//bcX spi flash image generator
//c. cvondrachek 2014

//takes u-boot, kernel, dtb & rootfs as inputs
//crams everything into a bin with automagic
//u-boot env creation 

//hardcoded bits around 16384k flash size

#include <stdio.h>
#include <stdlib.h>

#define ALIGNBYTES (64*1024)
//can use 4k... or even 1k, just note that env size is currently hardcoded to SPI device blocksize:
//s25fl128l - 64kb block, does support 32kB "half-block" erase. Linux driver doesn't seem to care & uses 64k.
//mx25l12835f - 64k block w/ half-block erase

//set env size to erase block so that's automagically aligned
#define ENV_SIZE ALIGNBYTES

//device size
#define DEV_SIZE (16384*1024)

//env offset
#define ENV_OFFSET (DEV_SIZE - ENV_SIZE)

#define FILE1 "staging/MLO.byteswap"
#define FILE2 "staging/u-boot.img"
#define FILE3 "staging/am335x-bcmax.dtb"
#define FILE4 "staging/zImage"
#define FILE5 "staging/bcmax_boot.sfs"
#define OUTFN "deploy/bcmax_boot.img"
#define ENVFN "deploy/u-boot.env"

//global
static FILE* gOutFile;

unsigned int copyBytes(FILE* h,unsigned int offset)
{
	char c;
	unsigned int wroteBytes=0;

	//move to requested position
	fseek(gOutFile,offset,SEEK_SET);

	//copy data
	c=fgetc(h);
	while( (feof(h)==0) )
	{
		fputc(c,gOutFile);
        	wroteBytes++;
		c=fgetc(h);
	}
	printf("\t0x%08x bytes written (%u base10)\n",wroteBytes,wroteBytes);
	return wroteBytes;
}

unsigned int appendFile(char* fn, unsigned int* storedAt)
{
	unsigned int startPos=0;
	unsigned int fileSz=0;

	//store current file position
	startPos=ftell(gOutFile);

	FILE* h=fopen(fn,"r");
	if(h != NULL)
	{
		printf("\nAppending file '%s'\n",fn);
		//copy data using my wrapper
		fileSz=copyBytes(h,startPos);

		//seek to the next boundary, ideally equal to the device erase-block size...
		printf("\t0x%08x start (%u base10)\n",startPos,startPos);
		unsigned int paddedSz = ((fileSz/ALIGNBYTES)+1)*ALIGNBYTES;
		printf("\t0x%08x padded size (%u base10)\n",paddedSz,paddedSz);
		unsigned int offset = startPos + paddedSz;
		printf("\t0x%08x end (%u base10)\n",offset,offset);
		fseek(gOutFile,offset,SEEK_SET); //seek from start of file... just easier

		//close input file
		fflush(h);
		fclose(h);
		//return 
		*storedAt=startPos;
		return paddedSz;
	}
	else
		return -1;
}

int main(int argc, char* argv[])
{
#define NUM_FILES 5
	unsigned int base[NUM_FILES];
	unsigned int size[NUM_FILES];

	printf("Today we're putting NUM_FILES files together into a bcX boot img.\n==============================================\n\n");
	gOutFile=fopen(OUTFN,"w");
	if(gOutFile==NULL)
	{
		printf("Unable to create/access the output file, %s. Aborting.\n",OUTFN);
		exit(1);
	}

	//yeah...
	if((size[0]=appendFile(FILE1,&base[0])))
	{
 	 if((size[1]=appendFile(FILE2,&base[1])))
	 {
 	 if((size[2]=appendFile(FILE3,&base[2])))
	 {
	  if((size[3]=appendFile(FILE4,&base[3])))
	  {
	   if((size[4]=appendFile(FILE5,&base[4])))
	   {
		printf("\nDone with images.\n\nChecking for env-area overlap...");
		//check to ensure the last base does not exceed the env-area
		if(base[4]+size[4]>=ENV_OFFSET)
		{
			printf("env got munched.\n\nmake other stuff smaller or find a bigger flash device\n.Can't finish. Bye.\n");
			exit(1);
		}
		printf("OK! (%.1f k left)\n\nCreating uboot env...\n",(double)(ENV_OFFSET-base[4]-size[4])/1024 );

		FILE *envFile, *envBin;
		//write-out geo as uboot env file
		envFile=fopen(ENVFN,"w");
	        if(envFile==NULL)
        	{
                	printf("Unable to create/access the env file, %s. Aborting.\n",ENVFN);
   			exit(1);
		}
		char outStr[ENV_SIZE];

		//create the offsets & sizes vars that are expected by our u-boot scripts
		sprintf(outStr, \
		"b0=0x%08x\nb1=0x%08x\nb2=0x%08x\nb3=0x%08x\nb4=0x%08x\ns0=0x%08x\ns1=0x%08x\ns2=0x%08x\ns3=0x%08x\ns4=0x%08x\n", \
			base[0],base[1],base[2],base[3],base[4],size[0],size[1],size[2],size[3],size[4]);

		//need these, currently
		sprintf(outStr,"%sargs_tftpusb=root=/dev/ram0 rw ramdisk_size=65536 initrd=${loadaddr},32M rootfstype=squashfs mtdparts=spi0.0:16384k(device),%dk@%dk(bootfs),%uk@%uk(env)\n",outStr,size[4]/1024,base[4]/1024,ENV_SIZE/1024,ENV_OFFSET/1024);
		sprintf(outStr,"%sargs_spifast=root=/dev/mtdblock1 ro rootwait mtdparts=spi0.0:16384k(device),%dk@%dk(bootfs),%uk@%uk(env)\n",outStr,size[4]/1024,base[4]/1024,ENV_SIZE/1024,ENV_OFFSET/1024);
		/**************************************** NOTE LACK OF SEMICOLONS ON KERNEL PARAMS ********************************************/

		printf("\nGenerated env:\n%s\n\n",outStr);
		fputs(outStr,envFile);
		fflush(envFile);
		fclose(envFile);

		sprintf(outStr,"/usr/bin/mkenvimage -s %u -o /tmp/env.bin %s",ENV_SIZE,ENVFN);
		system(outStr);
		envBin = fopen("/tmp/env.bin","r");
                if(envBin==NULL)
                {
                        printf("Unable to access /tmp/env.bin. Aborting.\n");
                        exit(1);
                }
		//seek back to envOffset & copy 
		printf("Writing env bin to 0x%08x (%u dec).\n",ENV_OFFSET,ENV_OFFSET);
		copyBytes(envBin,ENV_OFFSET);
		fclose(envBin);
		fflush(gOutFile);
		fclose(gOutFile);

		printf("I'm done (and EOF is still 0x%02x)\n",((unsigned char)EOF));
		return 0;
	   }
	  }
	  }
	 }
	}
	printf("Something went wrong. Do not trust the output. >3-|\n");
	return 1;
}

