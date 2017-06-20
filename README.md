##Filesystem Driver Infrastructure for MSX-DOS 2

aka

#NestorFilesystem

### Motivation

Some people in the MSX scene has developed awesome harwdare extensions that in some cases have mass storage capabilities - think SD card readers or network cards with built-in commands to access HTTP and FTP servers. Many of these come with the [Nextor](http://www.konamiman.com/msx/msx-e.html#nextor) kernel built-in, as its support for custom device drivers allows it to be easily adapted  to custom hardware.

However this approach has an important limitation: Nextor custom drivers are _device drivers_, i.e. they basically expose just "read/write sectors" functions. The filesystem level is still managed by Nextor, which poses some problems:

* Only FAT12 and FAT16 is supported, so it is not possible to use devices larger than 4GB unless they are partitioned accordingly.
* Some of these gadgets have microcontrollers that can handle filesystems by themselves, with a big performance gain compared to letting MSX-DOS doing all the work; but these "hardware accelerations" can't be used unless specific file handling applications are developed.
* Files in non-block devices (e.g. optical disks, network servers) can't be used directly, dedicated applications are needed no matter what.

One of the planned features for a future version of Nextor is the support for custom filesystem drivers, but that would be a ton of work, so instead of (or before, I'm not sure yet) doing that, I have started to develop a "simpler" solution: a template for filesystem drivers that install in mapped RAM (and it works in MSX-DOS 2, Nextor not required).

### How does it work?

Every time that an application performs a MSX-DOS 2 function call, the kernel code does some work and before actually executing the function it invokes a hook named `H_BDOS`, located at address `0F252h`. Of course the existence of this hook and the state of the system when it is invoked are completely undocumented, but who needs documentation having the source code of MSX-DOS 2 (which is the foundation of Nextor)?

A NestorFilesystem driver is a MSX-DOS 2 executable that allocates a RAM segment, copies the main driver code on it and puts a small piece of code in page 3. Then it hooks `H_BDOS` to point to this page 3 code, which (if it's a file access related function) calls an entry point in the driver code, which in turns executes the custom implementation of the function call. These custom implementations do the actual file access for the targetted hardware and return the appropriate values in the appropriate registers.

The template contains the installer and the driver scaffolding code that preprocesses the input to the function calls before passing it to the custom function implementations. Your job as a driver developer, should you accept it, is to implement these custom versions of the function calls according to the specification (which at this point is just a handful of comments in the source code).

Note that this project is in a **very** early stage. For now the only patched function calls are those for setting/getting the current directory and for searching files (aka CD and DIR). Expect breaking changes between 0.x versions, but of course I will try to minimize them and will appropriately document all ot them.

### How to build a custom filesystem driver

Open [NFS.ASM](MSX/NFS.ASM), search for `TODO` comments, and do whatever you are told to. At this point that's all the "spec" that exists. You may want to take a look at [the official MSX-DOS 2 programming guide](Docs) for reference as well.

The source is intended for the Compass MSX assembler, you can assemble it from a PC by using [Sjasm 0.39h](https://github.com/Konamiman/Sjasm/releases/tag/v0.39h): `sjasm -c NFS.asm NFS.COM` (the [`compile.bat`](MSX/compile.bat) script does exactly that).

To install it just run `NFS.COM` without paramaters from within MSX-DOS 2 or Nextor (you need one free RAM segment in the primary mapper). The driver will be attached to drive G: (future versions will allow you to choose the drive letter). Uninstall with `NFS U`.

You can check whether the driver is installed (and where) by calling extended BIOS (`0FFCAh`) with `DE=2204h`. If it is installed, you will get 22h in A, the slot number in B and the segment number in C. You can use this if you need to configure the driver with a custom tool (just switch the segment to any page and change whatever you need on it). Note that it is not possible to install more than one driver at the same time.

### Testing with NestorMSX

To ease testing the driver scaffolding code I have developed a plugin for [NestorMSX](https://github.com/Konamiman/NestorMSX) that provides integration with the host filesystem - that is, it allows you to access the filesystem of the machine running the emulator directly from the emulated MSX. If you want to give it a try:

1. Build [the plugin](NestorMSX) with Visual Studio and copy it to the `plugins` directory of your NestorMSX install. Or alternatively, use the [already compiled version from the Releases version](releases/tag/v0.1).

2. Modify the `machine.config` file of the machine configuration you will use (a good one would be _MSX2 with Nextor_) and add the following to the plugins section, modifying the values appropriately:

```
    "Filesystem integration": { 
        "integratedDirectory": "$MyDocuments$/NestorMSX/FileSystem",
        "volumeLabel": "NestorMSX"
    }
```
    
3. Build `NFS.COM` and copy it to a disk image file that you will mount in the emulator by using the MSX-DOS plugin. The [`build.bat`](MSX/build.bat) script does exactly that by using [ImDisk](http://www.ltr-data.se/opencode.html/#ImDisk) to mount the disk image file in the host machine, but you can use any other similar tool. You may need to tweak the [`mount.bat`](MSX/mount.bat) script as it contains the location of the image file in your machine - the default `NextorAndMsxDos.dsk` file is supplied with NestorMSX.

4. Boot NestorMSX, and in the MSX-DOS 2 prompt run `NFS`. Then do `DIR G:` and... magic!

### Oh, and one more thing...

[Take a look at my home page](http://www.konamiman.com) for contact details and other fun/obsolete stuff I have made, and [drop a couple of €s](http://www.konamiman.com/msx/msx-e.html#donate) if you think that I deserve it. Enjoy!