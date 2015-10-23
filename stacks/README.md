# Building an MzConverter base AMI	
Very crude notes; in progress to boot.  You have to know what you're doing, or at least fake it better than I am.

1. Fire up a Windows AMI based on the "Microsoft Windows Server 2008 R2 Base" AMI, available from Amazon.  The AMI id changes monthly, following Microsoft's patch tuesdays.

1. Run chef-client on the instance, using the bootstrap\_runlist in the mzconvert role.  This will invoke the windows\_base role, which installs chocolatey, etc. all the way through installing XCalibur. 

1. You ***may*** need to uninstall and reinstall Thermo Foundation and Thermo XCalibur.  I'm not sure.  I don't think I had to, last time I fired up an instance using Chef.

1. Install the Shimadzu lab solutions product, available in the ib-installers bucket.

1. Contact Shimadzu and have them license the LabSolutions product.  Run labsolutions once, and log in as "admin," no password.  Open the instrument.  Go to the Postrun section and open the browser.

1. Upload the (docs/local-service-shimadzu.reg) file and import it using regedit.  This will import some harmless looking keys into the HKEY\_USERS\S-1-5-19 hive, which makes the MZConvert Service run properly as the NT AUTHORITY\local service account.

1. Remove the local-service-shimadzu.reg file.

1. Uninstall chef-client.

1. Remove the c:\chef directory and all of its contents.

1.Remove the c:\opscode directory and all of its contents.

1. Remove the c:\cfn directory and all of its contents.

1. Remove the c:\packages\shimadzu and c:\packages\xcalibur directories, and all of their contents.

1. Empty the recycle bin.

1. Run ec2configservicesettings.exe.  Follow the screenshots, below, and choose to shut down WITH sysprep.

![ec2configservice](docs/mzconvert-1.png)
![ec2configservice](docs/mzconvert-2.png)
![ec2configservice](docs/mzconvert-3.png)

1. The instance will shut down.  Open the EC2 management console, right click on the instance, choose "image," then choose "create image."

1. Once the image is created, right-click on the image and modify its permissions. Share the image with the other account (in this case, I'm sharing from ibdev to production).

1. Copy the image to the other AWS regions in the US.
