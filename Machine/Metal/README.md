# Metal Machines

Your computer can (temporarily; reversibly; while booted from an external drive or USB stick) be turned into a Linux-native machine, which makes its full resources (RAM; processors) available. This is like a brain transplant for your computer, and is worth doing if you will be spending a lot of time working with the tools

* This will require you to have two USB sticks
   1. A small one to hold the installer software (say, 4GB)
   1. A large one to hold the installed system
      * at least 128 GB
* Be sure to get a _fast_ USB stick, at least for the large drive

n.b.: You will need to reconfigure your machine to permit it to boot from an external drive. This probably will involve disabling a "secure boot" machinery of some kind

   * Instructions for what you need to do for Macs vary by vintage, but at least there's a unique correct answer that depends on your model and is findable via a Google search
   * Instructions for non-Macs (Windows or Linux) machines are much more heterogeneous, but always involve you needing to manipulate your BIOS in several ways
      * On such machines, you can set the boot order between two USB ports
	  * You will need to put your installer USB drive into whichever is the first of these

## Instructions for Installing your VM on a Bootable USB Stick (or drive)

### [Burn](#burn) your chosen ISO image (MIN or MAX) to the small USB stick

1. Download your selected [(MIN or MAX)](https://github.com/econ-ark/econ-ark-tools/master/Software/Size.md) ISO image to your computer
0. "mount" the image so that the computer can see it
   * [Create-A-USB-Stick-On-Windows](https://ubuntu.com/tutorials/create-a-usb-stick-on-windows)
   * On Macs, mounting is done with the Disk Utility app ("open image")
   * Next, make a "bootable USB" stick by "flashing" the ISO image to the USB stick
      * ["Carbon Copy Cloner"](https://bombich.com/software/download_ccc.php) is the most reliable option for this
	     * There is a free trial version that should work
	     * Format your USB stick to MS-DOS
		 * Clone from the mounted ISO image to the formatted USB stick
      * ["balenaEtcher"](https://balena.io/etcher/)
	     * Seems to work on 2015-2019 vintage macs
	     * Fails on some earlier and later ones
      * [Create-A-USB-Stick-On-Macs](https://ubuntu.com/tutorials/create-a-usb-stick-on-macs) is another resource

