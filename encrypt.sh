# Set default output directory.
output="$PWD"

while getopts :i:o:p:r flag; do
	case "$flag" in
		i) input="$OPTARG" ;;
		o) output="$OPTARG" ;;
		p) password="$OPTARG" ;;
		r) encrypt_input_name="y" ;;
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
	read -s -p "Enter encryption password:" password
	printf "\n"

	read -s -p "Confirm encryption password:" password_confirmation
	printf "\n"

	if [[ "$password" != "$password_confirmation" ]]; then
		printf "%s\n" "The passwords do not match."
		exit 1
	fi
fi

encrypted_input_name=$(printf "%s" "$input_name" | openssl aes-256-cbc -a -salt -pass pass:"$password" | base64)

if [[ -z "$encrypt_input_name" ]]; then
	read -p "Encrypt input name? (Y/n) " encrypt_input_name
fi

case "$encrypt_input_name" in
	"y"|"Y"|"")
		output_name="$encrypted_input_name"
		;;
	"n"|"N")
		output_name="$input_name"
		;;
	*)
		printf "%s\n" "Invalid option."
		exit 1
		;;
esac

# Create output directory if it does not exist.
if [[ ! -d "$output" ]]; then
	mkdir -p "$output"
fi

output_path="$output/$output_name"

if [[ -f "$output_path" ]] || [[ -d "$output_path" ]]; then
	read -p "$output_name already exists. Do you want to override? (Y/n) " override

	case "$override" in
		"n"|"N")
			printf "%s\n" "Encryption interrupted."
			exit 1
			;;
	esac
fi

if [[ -f "$input" ]]; then
	if openssl enc -aes-256-cbc -salt -pass pass:"$password" -in "$input" -out "$output_path"; then
		printf "%s\n" "Encrypted successfully."
	else
		printf "%s\n" "Could not encrypt."
		exit 1
	fi
fi

if [[ -d "$input" ]]; then
	temporary_output_path="$output/$encrypted_input_name"

	mkdir "$temporary_output_path"

	for entry in "$input"/*; do
		sh $0 -i "$entry" -o "$temporary_output_path" -p "$password" -r >/dev/null
	done

	case "$encrypt_input_name" in
		"n"|"N")
			mv "$temporary_output_path" "$output_path"
			;;
	esac

	if [[ ! -z "$override" ]]; then
		rm -rf $output_path
	fi

	printf "%s\n" "Encrypted successfully."
fi
