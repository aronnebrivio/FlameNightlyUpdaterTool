#!/bin/bash

########
# VARS #
########
URL=//ftp.mozilla.org/pub/mozilla.org/b2g/nightly/latest-mozilla-central-flame-kk
BASE=v18D_nightly_v4
B2GV=45.0a1

#############
# FUNCTIONS #
#############

##### UPGRADE #####
upgrade() {
	head
	show_sections_title "Upgrade process started."
	#prepare_adb
	# Clean old files if any
	clean_tmp
	# Download update files
	echo -e "Downloading Gaia and B2G from Mozilla servers..."
	wget --timestamping http:$URL/gaia.zip
	wget --timestamping http:$URL/b2g-$B2GV.en-US.android-arm.tar.gz
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
	root_remount
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
	head
	show_sections_title "Upgrading to the lastest base..."
	show_sections_title "The device is in fastboot mode yet? [y/n]"
	read RES
	if $RES=='n'; then
		prepare_adb
	fi
	# Clean old files if any
	clean_tmp
	wget http://cds.w5v8t3u9.hwcdn.net/$BASE.zip
	unzip $BASE.zip
	echo -e "### Lastest base downloaded and extracted."
	cd $BASE
	if sudo ./flash.sh; then
		echo -e "### Done."
		cd ..
		rm -r $BASE.zip $BASE/
		echo -e "### Removed files."
		show_sections_title "Base upgrade complete!"
		quest
	fi
}

change_ota() {
	head
	show_sections_title "Switching to 'nightly-latest' FOTA channel..."
	#prepare_adb
	TODAY=$(date +%s)
	TWO_DAY_AGO=$((${TODAY} - 172800))
	echo -e "### Working on prefs.js..."
	prefs_path=$(adb shell ls /data/b2g/mozilla/*.default/prefs.js | tr -d '\n' | tr -d '\r')
	mkdir tmp
	cd tmp
	adb pull ${prefs_path}
	cp prefs.js prefs.js.bak
	echo -e "user_pref(\"app.update.url.override\", \"nightly-latest\");" >> prefs.js
	echo -e "user_pref(\"app.update.lastUpdateTime.background-update-timer\", $TWO_DAY_AGO);" >> prefs.js
	adb push prefs.js ${prefs_path}
	sleep 5
	show_sections_title "Switch done, rebooting."
	adb reboot
	cd ..
	quest
}

########## BACKUP ###############
backup_sms() {
	head
	show_sections_title "Backing up SMSs..."
	echo -e "NOT IMPLEMENTED YET."
	quest
}

backup_contacts() {
	head
	show_sections_title "Backing up Contacts..."
	echo -e "NOT IMPLEMENTED YET."
	quest
}

backup_wifi() {
	head
	show_sections_title "Backing up WIFI known networks..."
	#prepare_adb
	root_remount
	if adb pull /data/misc/wifi/wpa_supplicant.conf backup/wpa_supplicant.conf; then
		show_sections_title "Backup complete!"
		quest
	fi
}

backup_sdcard() {
	head
	show_sections_title "Backing up Internal Memory datas..."
	#prepare_adb
	root_remount
	if adb pull /sdcard/ backup/sdcard/; then
		show_sections_title "Backup complete!"
		quest
	fi
}

backup_b2g() {
	head
	# Backup b2g
	show_sections_title "Backing up /system/b2g into 'backup' folder (overwrite folder if already exists)..."
	#prepare_adb
	rm -rf backup &> /dev/null
	if adb pull /system/b2g backup/; then
		show_sections_title "Backup complete!"
		quest
	fi
}

restore_sms() {
	head
	show_sections_title "Restoring SMSs..."
	echo -e "NOT IMPLEMENTED YET."
	#adb reboot
	quest
}

restore_contacts() {
	head
	show_sections_title "Restoring Contacts..."
	echo -e "NOT IMPLEMENTED YET."
	#adb reboot
	quest
}

restore_wifi() {
	head
	show_sections_title "Restoring WIFI known networks..."
	#prepare_adb
	root_remount
	if adb push backup/wpa_supplicant.conf /data/misc/wifi/wpa_supplicant.conf; then
		adb shell chown system:wifi /data/misc/wifi/wpa_supplicant.conf
		show_sections_title "Restore complete, rebooting!"
		adb reboot
		quest
	fi
}

restore_sdcard() {
	head
	show_sections_title "Restoring Internal Memory datas..."
	#prepare_adb
	root_remount
	if adb push backup/sdcard/ /sdcard/; then
		show_sections_title "Restore complete, rebooting!"
		adb reboot
		quest
	fi
}

restore_b2g() {
	head
	# Restore b2g from backup/
	show_sections_title "Restoring backup from backup/ to /system/b2g..."
	#prepare_adb
	adb shell stop b2g
	echo -e "### b2g stopped."
	root_remount
	adb push system/b2g /system/b2g
	echo -e "### Pushed b2g backup."
	if adb push backup/ /system/b2g; then
		show_sections_title "Restore complete, rebooting!"
		adb reboot
		quest
	fi
}

backup() {
	head
	show_sections_title "Choose an option:"
	echo -e "1) Backup SMS"
	echo -e "2) Backup Contacts"
	echo -e "3) Backup WIFI networks"
	echo -e "4) Backup Internal Memory Card"
	echo -e "5) Backup B2G"
	echo -e "99) Back to main menu"
	read INBACKUP
	case $INBACKUP in
		[1]* )
			backup_sms
		;;
		[2]* )
			backup_contacts
		;;
		[3]* )
			backup_wifi
		;;
		[4]* )
			backup_sdcard
		;;
		[5]* )
			backup_b2g
		;;
		[99]* )
			first_loop
		;;
		* ) 
			echo -e "Sorry, try again." 
			sleep 2
			backup
		;;
	esac
}

restore() {
	head
	show_sections_title "Choose an option:"
	echo -e "1) Restore SMS"
	echo -e "2) Restore Contacts"
	echo -e "3) Restore WIFI networks"
	echo -e "4) Restore Internal Memory Card"
	echo -e "5) Restore B2G"
	echo -e "99) Back to main menu"
	read INRESTORE
	case $INRESTORE in
		[1]* )
			restore_sms
		;;
		[2]* )
			restore_contacts
		;;
		[3]* )
			restore_wifi
		;;
		[4]* )
			restore_sdcard
		;;
		[5]* )
			restore_b2g
		;;
		[99]* )
			first_loop
		;;
		* ) 
			echo -e "Sorry, try again."
			sleep 2 
			restore
		;;
	esac	
}

############ MISC ####################
patch_hosts() {
	head
	show_sections_title "Patching HOSTS file..."
	#prepare_adb
	root_remount
	adb push res/hosts /system/etc/hosts
	show_sections_title "Patch complete, rebooting!"
	adb reboot
	quest
}

restore_hosts() {
	head
	show_sections_title "Restoring stock HOSTS file..."
	#prepare_adb
	root_remount
	adb push res/hosts_orig /system/etc/hosts
	show_sections_title "Restore complete, rebooting!"
	adb reboot
	quest
}

host() {
	head
	show_sections_title "Choose an option:"
	echo -e "1) Patch HOSTS file (no more ads)"
	echo -e "2) Restore stock HOSTS file"
	echo -e "99) Back to main menu"
	read INHOST
	case $INHOST in
		[1]* )
			patch_hosts
		;;
		[2]* )
			restore_hosts
		;;
		[99]* )
			first_loop
		;;
		* ) 
			echo -e "Sorry, try again." 
			sleep 2
			host
		;;
	esac
}

udev() {
	head
	show_sections_title "Adding an UDEV rule for Flame (if not present yet)..."
	myvar=$(less /etc/udev/rules.d/android.rules | sed -n 's/.*\(05c6\).*/\1/p')
	if [[ "${myvar}" = "" ]]; then
		echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0666", GROUP="plugdev"' | sudo tee --append /etc/udev/rules.d/android.rules > /dev/null
		echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"' | sudo tee --append /etc/udev/rules.d/android.rules > /dev/null
		echo -e "### UDEV rule for Flame added."
		sudo service udev restart
		echo -e "### UDEV service reloaded, please unplug and replug the device."
	else
		echo -e "### UDEV rule for Flame already present."
	fi
	quest
}

############# OTHERS ###################
show_head() {
	echo -e "\033[1;34m$@\033[0m"
}

show_sections_title() {
	echo -e "\033[1;32m$@\033[0m"
}

clean_tmp() {
	echo -e "Cleaning working directory..."
	# gaiatime=$(stat -c %y gaia.zip | cut -d '.' -f1)
	# b2gtime=$(stat -c %y b2g-$b2gv.en-US.android-arm.tar.gz | cut -d '.' -f1)
	TODAY=$(date +%s)
	TWO_DAY_AGO=$((${TODAY} - 172800))
	for dir in b2g gaia system resources $BASE $BASE.zip gaia.zip b2g-*.en-US.android-arm.tar.gz tmp; do
		if [ -d $dir ] || [ -f $dir ]; then
			rm -r $dir;
		fi
	done
	echo -e "### Done."
}

prepare_adb() {
	show_sections_title "Setting ADB"
	sudo adb kill-server
	# Start ADB as sudo
	sudo adb start-server
	echo -e "### adb service started"
	echo -e "### waiting for the device, make sure it's plugged"
	if adb wait-for-device; then
		echo -e "### device found"
		# Forward
		sudo adb forward tcp:6000 localfilesystem:/data/local/debugger-socket
		adb root
		echo -e "### adb restarted with root privileges"
	fi
}

prepare_adb_first() {
	show_sections_title "Setting ADB"
	sudo adb kill-server
	# Start ADB as sudo
	sudo adb start-server
	echo -e "### adb service started"
	echo -e "### waiting for the device, make sure it's plugged"
	if adb wait-for-device; then
		echo -e "### device found"
		# Forward
		sudo adb forward tcp:6000 localfilesystem:/data/local/debugger-socket
		adb root
		echo -e "### adb restarted with root privileges"
		sleep 1
		first_loop
	fi
}

root_remount() {
	echo -e "Mounting / as root"
	adb remount
	# Remount root partition read-write
	adb shell mount -o rw,remount /
	# Remount system partition read-write
	adb shell mount -o rw,remount /system
	echo -e "### device remounted with rw privileges."
}

end() {
	clean_tmp
	adb kill-server
	show_sections_title "Bye!"
	exit 0
}

loop() {
	show_sections_title "Choose an option: "
	echo -e "------- Upgrade --------"
	echo -e "1) Upgrade Gaia and B2G"
	echo -e "2) Upgrade Gonk"
	echo -e "3) Change FOTA url"
	echo -e ""
	echo -e "---- Backup/Restore ----"
	echo -e "4) Backup"
	echo -e "5) Restore"
	echo -e ""
	echo -e "--------- Misc ---------"
	echo -e "6) HOSTS file"
	echo -e "7) Add UDEV rules"
	echo -e "99) Exit"
	read INPUT
	case $INPUT in
		[1]* )
			upgrade
		;;
		[2]* )
			upgrade_base
		;;
		[3]* )
			change_ota
		;;
		[4]* ) 
			backup
		;;
		[5]* )
			restore
		;;
		[6]* )
			host
		;;
		[7]* )
			udev
		;;
		[99]* )
			end
		;;
		* ) 
			echo -e "Sorry, try again." 
			sleep 2
			first_loop
		;;
	esac
}

quest() {
	show_sections_title "Do you want to do other stuff? [y/n]"
	read RES
	case $RES in
		[y]* )
			first_loop
		;;
		[n]* )
			end
		;;
	esac
}

first_loop() {
	head
	loop
}

head() {
	clear
	show_head "#----------------------------------#\n#   Flame Nightly Updater Script   #\n#----------------------------------#\n"
}
########
# MAIN #
########
head
prepare_adb_first

