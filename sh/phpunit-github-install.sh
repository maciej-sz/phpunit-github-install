#!/usr/bin/env bash

# Defaults:
WS="/tmp";
PUMOD="phpunit-modules";
PUDEP="phpunit-deps";
TARGET="/usr/local/lib/php";
TARGET_OWNER="www";
TARGET_GROUP="www";
CLEANUP="no";
UPDATE="no";
PURGE="no";




# ! DO NOT EDIT BELOW !

function echoHr {
	echo -e "\n-----------------------------------------\n";
}

function usage() {
	cat <<EOF

Usage: $0 options

This scripts installs PHPUnit in selected directory.

OPTIONS:
 -h	Show this help message.
 -w	Working directory for fetching the required repos. Default is "/tmp".
 -m	Modules subdirectory within the working directory. This is relative to the working directory, so you should NOT be providing full path. Default is "phpunit-modules"
 -d	Dependencies subdirectory within the working directory. This is relative to the working directory, so you should NOT be providing full path. Default is "phpunit-deps"
 -t	Target directory. This determines where to put final code. This should be a directory listed in 'include_path' directory. Default is "/usr/local/lib/php".
 -u	Update local repositories if they exist. Default is "no".
 -o	Owner of the target directory. Default is "www", but if there is no "www" user in /etc/passwd then the owner wont change and will ramain "root".
 -g	Group of the target directory. Default is "www", but if there is no "www" group then the owner wont be changed and will remain "root".
 -p	Purge existing directories in target directory. Default is "no".
 -c	Cleanup working directory after install.
EOF
}

function inArray() {
	local n=$#;
	local val=${!n}
	for ((i=1; i < $#; i++)) {
		if [ "${!i}" == "${val}" ]; then
			echo "y";
			return 0;
		fi
	}
	echo "n";
	return 1;
}

sudo echo;

while getopts "hw:m:t:u:o:g:p:c" opt
do
	case $opt in
		h)
			usage;
			exit 1;
			;;
		w)
			WS=$OPTARG;
			;;
		m)	
			PUMOD=$OPTARG;
			;;
		d)
			PUDEP=$OPTARG;
			;;
		t)
			TARGET=$OPTARG;
			;;
		u)
			UPDATE=$OPTARG;
			;;
		o)
			TARGET_OWNER=$OPTARG;
			;;
		g)
			TARGET_GROUP=$OPTARG;
			;;
		p)
			PURGE=$OPTARG;
			;;
		c)
			CLEANUP="yes";
			;;
		\?)
			echo -e "Invalid option: -$OPTARG\nSee $0 -h for help."
			exit 1;
			;;
	esac
done

PUMOD="$WS/$PUMOD";
PUDEP="$WS/$PUDEP";

declare -a mod_keys
declare -a mod_targets
declare -a mod_git_urls
declare -a mod_git_branches
declare -a mod_extracts
declare -a mod_extract_targets

mod_keys+=("phpunit")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/phpunit.git')
mod_git_branches+=('3.7')
mod_extracts+=('PHPUnit')
mod_extract_targets+=('*')

mod_keys+=("php-code-coverage")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/php-code-coverage.git')
mod_git_branches+=('1.2')
mod_extracts+=('PHP')
mod_extract_targets+=('*')

mod_keys+=("phpunit-mock-objects")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/phpunit-mock-objects.git')
mod_git_branches+=('1.2')
mod_extracts+=('PHPUnit')
mod_extract_targets+=('*')

mod_keys+=("phpunit-selenium")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/phpunit-selenium.git')
mod_git_branches+=('1.2')
mod_extracts+=('PHPUnit')
mod_extract_targets+=('*')

mod_keys+=("php-text-template")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/php-text-template.git')
mod_git_branches+=('master')
mod_extracts+=('Text')
mod_extract_targets+=('*')

mod_keys+=("php-file-iterator")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/php-file-iterator.git')
mod_git_branches+=('master')
mod_extracts+=('File')
mod_extract_targets+=('*')

mod_keys+=("php-token-stream")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/php-token-stream.git')
mod_git_branches+=('master')
mod_extracts+=('PHP')
mod_extract_targets+=('*')

mod_keys+=("php-timer")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/php-timer.git')
mod_git_branches+=('1.0')
mod_extracts+=('PHP')
mod_extract_targets+=('*')

mod_keys+=("sebastianbeergmann-version")
mod_targets+=("$PUMOD")
mod_git_urls+=('https://github.com/sebastianbergmann/version.git')
mod_git_branches+=('master')
mod_extracts+=('src')
mod_extract_targets+=('SebastianBergmann/Version')

<<PATTERN
mod_keys+=("")
mod_targets+=("")
mod_git_urls+=('')
mod_git_branches+=('master')
mod_extracts+=('')
mod_extract_targets+=('*')
PATTERN



command -v git >/dev/null 2>&1 || { echo >&2 "Git is not installed. Aborting."; exit 1; }

if [ ! -d "$WS" ] ; then
	echo "Directory \"${WS}\" is required for this script. Aborting.";
	exit 1;
fi


for (( i=0; i < ${#mod_keys[@]}; i++ )); do
	if [ ! -d "${mod_targets[$i]}" ] ; then
		echo "Creating dir \"${mod_targets[$i]}\"";
		mkdir "${mod_targets[$i]}";
	fi
	TGT="${mod_targets[$i]}/${mod_keys[$i]}";
	if [ -d "${TGT}" ]; then
		echo "Updating \"${mod_keys[$i]}\"...";
		if [[ "Y" == $UPDATE || "y" == $UPDATE || "yes" == $UPDATE ]]; then
			git --git-dir="${TGT}/.git" fetch origin || { echo "Cannot update \"${mod_keys[$i]}\". Aborting."; exit 1; };
	                git --git-dir="${TGT}/.git" --work-tree="${TGT}" merge "${mod_git_branches[$i]}" || { echo "Cannot merge \"${mod_keys[$i]}\" (${mod_git_branches[$i]}). Aborting."; exit 1; };
		else
			echo "skipping due to \"-u no\" option.";
		fi
	else
		echo "Cloning \"${mod_keys[$i]}\"...";
		git clone -b "${mod_git_branches[$i]}" "${mod_git_urls[$i]}" "${TGT}" || { echo "Cannot clone \"${mod_git_urls[$i]}\". Aborting."; exit 1; };
	fi
	echo;
done


# MOVING TO TARGET:

if [[ "Y" == $PURGE || "y" == $PURGE || "yes" == $PURGE ]]; then
	declare -a dirs_to_purge;

	for (( i=0; i < ${#mod_keys[@]}; i++ )); do
		TGT=${mod_extracts[$i]};
		if [[ '*' != ${mod_extract_targets[$i]} ]]; then
			TGT=${mod_extract_targets[$i]};
		fi
		if [ $(inArray ${dirs_to_purge[@]} $TGT) != "y" ]; then
			dirs_to_purge+=($TGT);
		fi
	done

	for (( i=0; i < ${#dirs_to_purge[@]}; i++ )); do
		TGT="${TARGET}/${dirs_to_purge[$i]}";
		echo "Deleting ${TGT}";
		sudo rm -rf "$TGT";
	done
	echo;
fi



if [ ! -d "$TARGET" ] ; then
	sudo mkdir "$TARGET" || { echo "Can't create target directory \"${TARGET}\". Aborting."; exit 1; }
fi

for (( i=0; i < ${#mod_keys[@]}; i++ )); do
	SRC="${mod_targets[$i]}/${mod_keys[$i]}/${mod_extracts[$i]}";
        TGT="${TARGET}/${mod_extracts[$i]}";
	if [ '*' != "${mod_extract_targets[$i]}" ] ; then
		TGT="${TARGET}/${mod_extract_targets[$i]}"
	fi
	echo -e "Syncing \"${mod_keys[$i]}\" => \"${TGT}\"";
	sudo mkdir -p "$TGT"
	sudo rsync -azCP "${SRC}/" "${TGT}/" >/dev/null;
	sudo chown -R "${TARGET_OWNER}:${TARGET_GROUP}" "${TGT}"
done

if [[ "y" == $CLEANUP || "y" == $CLEANUP || "yes" == $CLEANUP ]]; then
	echo -e "\nCleaning up...";
	if [ -d $PUMOD ]; then
		rm -rf $PUMOD;
	fi
	if [ -d $PUDEP ]; then
                rm -rf $PUDEP;
        fi
fi

echo
echo "DONE!";
echo

exit 0
