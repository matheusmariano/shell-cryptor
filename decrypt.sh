# Set default output directory.
output="$PWD"

while getopts :i:o:p:r flag; do
	case "$flag" in
		i) input="$OPTARG" ;;
		o) output="$OPTARG" ;;
		p) password="$OPTARG" ;;
		\?)
			printf "%s\n" "Invalid option -$OPTARG"
			;;
	esac
done

if [[ -z "$input" ]]; then
	printf "%s\n" "Usage: sh encrypt.sh -i input [-o output] [-p password] [-r rename]"
	exit
fi

if [[ ! -e "$input" ]]; then
	printf "%s\n" "$input not found."
	exit 1
fi

input_name=${input##*/}

if [[ -z "$password" ]]; then
	read -s -p "Enter decryption password:" password
	printf "\n"
fi

# Create output directory if it does not exist.
if [[ ! -d "$output" ]]; then
	mkdir -p "$output"
fi

if [[ -f "$input" ]]; then
	if openssl enc -aes-256-cbc -d -salt -pass pass:"$password" -in "$input" -out "$output"; then
		printf "%s\n" "Decrypted successfully."
	else
		printf "%s\n" "Could not decrypt."
		exit 1
	fi
elif [[ -d "$input" ]]; then
	for entry in "$input"/*; do
		sh $0 -i "$entry" -o "$output" -p "$password" -r >/dev/null
	done

	printf "%s\n" "Decrypted successfully."
fi
