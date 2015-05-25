#!/bin/bash

# VARS
url=//ftp.mozilla.org/pub/mozilla.org/b2g/nightly/latest-mozilla-central-flame-kk

# FUNCTIONS
show_head() {
	printf "\033[1;34m$@\033[0m"
}
show_sections_title() {
	printf "\033[1;32m$@\033[0m"
}

upgrade() {
	show_sections_title "\nUpgrade process started."
	# Clean old files
	for dir in b2g gaia system resources gaia.zip b2g-*.en-US.android-arm.tar.gz; do
	  if [ -d $dir ] || [ -f $dir ]; then
		rm -r $dir;
	  fi
	done

	# Download update files
	printf "\nDownloading Gaia and B2G from Mozilla servers...\n"
	wget http:$url/gaia.zip
	wget -r -np -nd --glob=on ftp:$url/b2g-\*.en-US.android-arm.tar.gz
	printf "\n\tDone."
	 
	# Prepare update
	printf "\nExtracting gaia.zip..."
	unzip gaia.zip &> /dev/null
	printf "\n\tDone."

	printf "\nExtracting b2g-(version).en-US.android-arm.tar.gz..."
	tar -zxvf b2g-*.en-US.android-arm.tar.gz &> /dev/null
	printf "\n\tDone."

	printf "\nPreparing the environment..."
	mkdir system
	 
	mv b2g system/
	mv gaia/profile/* system/b2g/
	printf "\n  Done."
	 
	# Update the phone
	printf "\nUpdating Flame..."
	adb shell stop b2g
	printf "\n\tb2g stopped."
	adb remount
	printf "\n\tDevice remounted."
	adb shell rm -r /system/b2g
	printf "\n\t/system/b2g wiped."

	if adb push system/b2g /system/b2g; then
		printf "\n\tPushed new version of b2g."

		printf "\nRestarting b2g..."
		adb shell start b2g
		printf "\n\tDone."
	
		show_sections_title "\n\nUpgrade complete!\n"
		loop
	fi
}

backup() {
	# Backup b2g
	#backup=`adb pull /system/b2g backup/`
	show_sections_title "\nBacking up /system/b2g into 'backup' folder (overwrite folder if already exists)...\n"
	rm -rf backup &> /dev/null
	
	if adb pull /system/b2g backup/; then
		show_sections_title "\n\nUpgrade complete!\n"
		loop
	fi
}

restore() {
	# Restore b2g from backup/
	show_sections_title "\nRestoring backup from backup/ to /system/b2g...\n"
	adb shell stop b2g
	printf "\n\tb2g stopped."
	adb remount
	printf "\n\tDevice remounted."
	adb push system/b2g /system/b2g
	printf "\n\tPushed b2g backup."

	if adb push backup/ /system/b2g; then
		printf "\nRestarting b2g..."
		adb shell start b2g
		printf "\n\tDone."
		show_sections_title "\n\nRestore complete!\n"
		loop
	fi
}

loop() {
	show_sections_title "\nChoose an option: "
	printf "\n1) Upgrade"
	printf "\n2) Backup"
	printf "\n3) Restore"
	printf "\n4) Exit\n"
	read INPUT
	case $INPUT in
		[1]* )
			upgrade
		;;
		[2]* ) 
			backup
		;;
		[3]* )
			restore
		;;
		[4]* )
			show_sections_title "\nBye!\n"
			exit 0
		;;
		* ) 
			printf "\nSorry, try again." 
			loop
		;;
	esac
}

# MAIN
clear
show_head "#----------------------------------#\n#   Flame Nightly Updater Script   #\n#----------------------------------#\n"
loop

