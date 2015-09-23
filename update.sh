#!/bin/bash

########
# VARS #
########
url=//ftp.mozilla.org/pub/mozilla.org/b2g/nightly/latest-mozilla-central-flame-kk
base=v18D_nightly_v4
b2gv=44.0a1

#############
# FUNCTIONS #
#############
show_head() {
	echo -e "\033[1;34m$@\033[0m"
}
show_sections_title() {
	echo -e "\033[1;32m$@\033[0m"
}

upgrade() {
	show_sections_title "Upgrade process started."
	prepare_adb
	# Clean old files if any
	clean_tmp
	# Download update files
	echo -e "Downloading Gaia and B2G from Mozilla servers..."
	wget http:$url/gaia.zip
	wget http:$url/b2g-$b2gv.en-US.android-arm.tar.gz
	#wget -r -np -nd --glob=on ftp:$url/b2g-*.en-US.android-arm.tar.gz
	echo -e "### Done." 
	# Prepare update
	echo -e "Extracting gaia.zip..."
	unzip gaia.zip &> /dev/null
	echo -e "### Done."
	echo -e "Extracting b2g-(version).en-US.android-arm.tar.gz..."
	tar -zxvf b2g-*.en-US.android-arm.tar.gz &> /dev/null
	echo -e "### Done."
	echo -e "Preparing the environment..."
	mkdir system	 
	mv b2g system/
	mv gaia/profile/* system/b2g/
	echo -e "### Done."	 
	# Update the phone
	echo -e "Updating Flame..."
	adb shell stop b2g
	echo -e "### b2g stopped."
	adb remount
	# Remount root partition read-write
	adb shell mount -o rw,remount /
	# Remount system partition read-write
	adb shell mount -o rw,remount /system
	echo -e "### Device remounted with rw privileges."
	adb shell rm -r /system/b2g
	echo -e "### /system/b2g wiped."
	if adb push system/b2g /system/b2g; then
		echo -e "### Pushed new version of b2g."
		echo -e "Restarting b2g..."
		adb shell start b2g
		echo -e "### Done."
		show_sections_title "Upgrade complete!"
		quest
	fi
}

upgrade_base() {
	show_sections_title "Upgrading to the lastest base..."
	prepare_adb
	# Clean old files if any
	clean_tmp
	wget http://cds.w5v8t3u9.hwcdn.net/$base.zip
	unzip $base.zip
	echo -e "### Lastest base downloaded and extracted."
	cd $base
	if sudo ./flash.sh; then
		echo -e "### Done."
		cd ..
		rm -r $base.zip $base/
		echo -e "### Removed files."
		show_sections_title "Base upgrade complete!"
		quest
	fi
}

backup() {
	# Backup b2g
	#backup=`adb pull /system/b2g backup/`
	show_sections_title "Backing up /system/b2g into 'backup' folder (overwrite folder if already exists)..."
	prepare_adb
	rm -rf backup &> /dev/null
	if adb pull /system/b2g backup/; then
		show_sections_title "Upgrade complete!"
		quest
	fi
}

restore() {
	# Restore b2g from backup/
	show_sections_title "Restoring backup from backup/ to /system/b2g..."
	prepare_adb
	adb shell stop b2g
	echo -e "### b2g stopped."
	adb remount
	echo -e "### Device remounted."
	adb push system/b2g /system/b2g
	echo -e "### Pushed b2g backup."
	if adb push backup/ /system/b2g; then
		echo -e "Restarting b2g..."
		adb shell start b2g
		echo -e "### Done."
		show_sections_title "Restore complete!"
		quest
	fi
}

udev() {
	show_sections_title "Adding an UDEV rule for Flame (if not present yet)..."
	echo -e "ACTUALLY NOT WORKING. Exiting"
	#myvar=$(less /etc/udev/rules.d/android.rules | grep 05c6)
	#if [${#myvar} -eq 0]; then
	#	sudo echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0666", GROUP="plugdev"' >> /etc/udev/rules.d/android.rules
	#	echo -e "### UDEV rule for Flame added."
	#else
	#	echo -e "### UDEV rule for Flame already present."
	#fi
	quest
}

clean_tmp() {
	echo -e "Cleaning working directory..."
	for dir in b2g gaia system resources $base $base.zip gaia.zip b2g-*.en-US.android-arm.tar.gz ; do
		if [ -d $dir ] || [ -f $dir ]; then
			rm -r $dir;
		fi
	done
	echo -e "### Done."
}

prepare_adb() {
	echo -e "Setting ADB"
	sudo adb kill-server
	# Start ADB as sudo
	sudo adb start-server
	echo -e "### adb service started"
	if adb wait-for-device; then
		echo -e "### device found"
		# Forward
		sudo adb forward tcp:6000 localfilesystem:/data/local/debugger-socket
		adb root
		echo -e "### adb restarted with root privileges"
	fi
}

end() {
	clean_tmp
	adb kill-server
	show_sections_title "Bye!"
	exit 0
}

loop() {
	show_sections_title "Choose an option: "
	echo -e "1) Upgrade Gaia and B2G"
	echo -e "2) Upgrade Gonk"
	echo -e "3) Backup"
	echo -e "4) Restore"
	echo -e "5) Add UDEV rules"
	echo -e "6) Exit"
	read INPUT
	case $INPUT in
		[1]* )
			upgrade
		;;
		[2]* )
			upgrade_base
		;;
		[3]* ) 
			backup
		;;
		[4]* )
			restore
		;;
		[5]* )
			udev
		;;
		[6]* )
			end
		;;
		* ) 
			echo -e "Sorry, try again." 
			loop
		;;
	esac
}

quest() {
	show_sections_title "Do you want to do other stuff? [y/n]"
	read RES
	case $RES in
		[y]* )
			loop
		;;
		[n]* )
			end
		;;
	esac
}

########
# MAIN #
########
clear
show_head "#----------------------------------#\n#   Flame Nightly Updater Script   #\n#----------------------------------#\n"
loop

