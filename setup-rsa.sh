#!/usr/bin/env bash

###########################
# This script setups ssh keys on your system using symbolic links to a pendrive
# @author Thomas Letsch Groch
###########################

# some colorized echo helpers
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

function ok() {
    echo -e "$COL_GREEN[ok]$COL_RESET "$1
}

function bot() {
    echo -e "\n$COL_GREEN\[._.]/$COL_RESET - "$1
}

function running() {
    echo -en "$COL_YELLOW ⇒ $COL_RESET"$1": "
}

function action() {
    echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..."
}

function warn() {
    echo -e "$COL_YELLOW[warning]$COL_RESET "$1
}

function error() {
    echo -e "$COL_RED[error]$COL_RESET "$1
}

# Check for required installed software
SSH_AGENT_BIN=`which ssh-agent`
if [ -z "${SSH_AGENT_BIN}" ]; then
	error "No ssh-agent command found, exiting." && exit 1
else
	ok "ssh-agent command found"
fi
SSH_ADD_BIN=`which /usr/bin/ssh-add` # Apple's standard version of ssh-add
if [ -z "/usr/bin/ssh-add" ]; then
	error "No ssh-add command found, exiting." && exit 1
else
	ok "ssh-add command found"
fi

# check if ssh-agent is already running
if ps -p $SSH_AGENT_PID > /dev/null
then
	ok "ssh-agent is running"
else
	action "Initializing ssh-agent"
	eval `ssh-agent -s`
fi

chmod 700 /Users/$(whoami)/.ssh

bot "Current loaded ssh keys:"
if [ "$(ssh-add -l)" = "The agent has no identities." ]; then
	echo "No keys on the agent."
else
	for key in $(ssh-add -l | awk '{ print $3 }'); do
		echo " - ${key} [$(ssh-keygen -lf $key | awk '{ print $3 }')]"
	done
fi

PENDRIVE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bot "The best I can make out, your email address is $COL_YELLOWasd$COL_RESET"

bot "What would you like to do?"
read -r -p "(N)ew SSH key, (I)mport SSH key, (U)nload all keys or (Q)uit  [default=I] " response
response=${response:-I}

if [[ $response =~ (n|N) ]];then

	bot "Generating a new SSH key"

	read -r -p "What is your email? " email
	if [[ ! $email ]];then
		error "you must provide an email as rsa fingerprint"
		exit 1
	fi

	# Key name
	read -r -p "What is the name of this key? [default=id_rsa] " key_name
	if [[ ! $key_name ]];then
		key_name="id_rsa"
	else
		key_name="${key_name}_id_rsa"
	fi

	# Key passphrase
	read -r -p "What passphrase should I use? [default=Random] " key_passphrase
	if [[ ! $key_passphrase ]];then
		key_passphrase=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 | sed 's/=//g')
	fi

	# Key comment
	read -r -p "Would you like to add comment? [default=${key_name}]" key_comment
	if [[ ! $key_comment ]];then
		key_comment=$key_name
	else
		key_comment="${key_name} ${key_comment}"
	fi
	
	OUTPUT_KEY="${PENDRIVE}/rsa/${key_name}"
	OUTPUT_PASSPHRASE_FILE="${OUTPUT_KEY}.passphrase"

	action "Saving passphrase"
	echo $key_passphrase > "${OUTPUT_PASSPHRASE_FILE}";ok

	action "Generating key"
	ssh-keygen -b 4096 -t rsa -C $key_comment -f $OUTPUT_KEY -q -N $key_passphrase;ok

	chmod 600 $OUTPUT_KEY
	chmod 600 ${OUTPUT_KEY}.pub

	bot "Your new key has been successfully created.\n \
	Private: ${OUTPUT_KEY}\n \
	Public: ${OUTPUT_KEY}.pub\n \
	Passphrase: ${OUTPUT_PASSPHRASE_FILE}\n\n \
	Comment: ${key_comment}\n"

elif [[ $response =~ (u|U) ]];then
	action "Unload all keys"
	ssh-add -D;ok
elif [[ $response =~ (q|Q) ]];then
	echo "Quitting.." >&2
    exit 0
else

	bot "Which key should I be importing?"
	while IFS= read -r -d $'\0' f; do
	  options[i++]="$f"
	done < <(find $PENDRIVE/rsa/ -maxdepth 1 -type f -name "*.pub" -print0 )

	select opt in "${options[@]}" "Quit"; do
	    case $opt in
	        *.pub)
	            pub_filename="${opt##*/}"
	            private_filename="${pub_filename%.*}"

	            action "Creating symbolic link to public key"
	            ln -s $PENDRIVE/rsa/$pub_filename /Users/$(whoami)/.ssh;ok

	            action "Creating symbolic link to private key"
	            ln -s $PENDRIVE/rsa/$private_filename /Users/$(whoami)/.ssh;ok
	            
	            action "Setting permissions"
	            chmod 600 /Users/$(whoami)/.ssh/$pub_filename
	            chmod 600 /Users/$(whoami)/.ssh/$private_filename;ok

	            action "Loading key into ssh-agent"
	            passphrase=$(cat "${PENDRIVE}/rsa/${private_filename}.passphrase")

	            ssh-add-pass.sh "/Users/$(whoami)/.ssh/${private_filename}" $passphrase

				if [ $? -eq 0 ]; then
					ok;
					bot "Your ${private_filename} key has been successfully imported"
				else
					error "Wrong passphrase"
				fi

	            break
	            ;;
	        "Quit")
	            echo "Quitting.." >&2
	            exit 0;;
	        *) echo "invalid option $REPLY" >&2;exit 1;
	    esac
	done

fi

# cat ~/.ssh/id_rsa.pub | pbcopy

# Add to Github
# [Github SSH keys](https://github.com/settings/ssh)

# Test connection
# ssh -T git@github.com

# You've successfully authenticated








