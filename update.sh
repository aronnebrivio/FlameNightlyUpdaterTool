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
	printf "\n  Done."
	 
	# Prepare update
	printf "\nExtracting gaia.zip..."
	unzip gaia.zip &> /dev/null
	printf "\n  Done."

	printf "\nExtracting b2g-(version).en-US.android-arm.tar.gz..."
	tar -zxvf b2g-*.en-US.android-arm.tar.gz &> /dev/null
	printf "\n  Done."

	printf "\nPreparing the environment..."
	mkdir system
	 
	mv b2g system/
	mv gaia/profile/* system/b2g/
	printf "\n  Done."
	 
	# Update the phone
	printf "\nUpdating Flame..."
	adb shell stop b2g
	printf "\n  b2g stopped."
	adb remount
	printf "\n  Device remounted."
	adb shell rm -r /system/b2g
	printf "\n  /system/b2g wiped."
	adb push system/b2g /system/b2g
	printf "\n  Pushed new version of b2g."

	printf "\nRestarting b2g..."
	adb shell start b2g
	printf "\n\tDone."
	
	show_sections_title "\n\nAll done!\n"
}

backup() {
	# Backup b2g
	#backup=`adb pull /system/b2g backup/`
	show_sections_title "\nBacking up /system/b2g into 'backup' folder (overwrite folder if already exists)...\n"
	rm -rf backup &> /dev/null
	
	if adb pull /system/b2g backup/; then
		printf "\n  Done."
		upgrade
	fi
}

loop() {
	show_sections_title "\nDo you want to backup your b2g version before starting? (Y)es, (N)o: "
	read INPUT
	case $INPUT in
		[Yy]* )
			backup
		;;
		[Nn]* ) 
			upgrade
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

