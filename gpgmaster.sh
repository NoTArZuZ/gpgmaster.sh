#!/usr/bin/env bash
# Dependencies: GPG
# GPG Bash Master by Chatoyance v1.13
# Very poor codebase at the moment

# USER DEFINED VARIABLES
rmencsource=false # Remove the source file before encryption
rmdecsource=false # Remove the source file before decryption
rmdecoutput=false # Remove the file after decryption

# Main Functions
POSITIONAL_ARGS=()
singleflag=0
encrypt() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		recipu=$(cat $HOME/.cache/gpglastrec); [ -z "$recipu" ] && exit 1
		outmsg=$(echo "$msg" | gpg --encrypt --armor -r $recipu) || exit 1
		# GPG Encrypt Done
		echo "$outmsg"
		[ $noask ] || {
			echo
			echo ">> Used keys: $recipu"
			echo ">> Copied Message to Clipboard"
		}
		echo "$outmsg" | xclip -r -sel c
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		[ -z "$recipu" ] && read -r -p "Enter Recipient(s): " recipu; [ -z "$recipu" ] && exit 1
		tempfile="/tmp/tmpencmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg --encrypt --armor -r $recipu) || exit 1
		# GPG Encrypt Done
		echo "$outmsg"
		echo "$recipu" >"$HOME/.cache/gpglastrec"
		[ $noask ] || read -r -p "Copy Message? [Y/n]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] || [ -z "$topost" ] && (echo "$outmsg" | xclip -r -sel c)
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		[ -z "$recipu" ] && read -r -p "Enter Recipient(s): " recipu; [ -z "$recipu" ] && exit 1
		outfile="${POSITIONAL_ARGS}.gpg"
		gpg --encrypt --armor -r $recipu --output "$outfile" "$POSITIONAL_ARGS" || exit 1
		# GPG Encrypt Done
		filecontent=$(cat "$outfile")
		echo "$recipu" >"$HOME/.cache/gpglastrec"
		[ $noask ] || rm -i "$POSITIONAL_ARGS"
		[ $rmencsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Copy File Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && (echo "$filecontent" | xclip -r -sel c)
		exit 0
	fi
	exit 0
}
# signencrypt SHOULD be somehow merged into encrypt in the future
signencrypt() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		recipu=$(cat $HOME/.cache/gpglastrec); [ -z "$recipu" ] && exit 1
		localu=$(cat $HOME/.cache/gpglastloc); [ -z "$localu" ] && exit 1
		outmsg=$(echo "$msg" | gpg -se --armor -r $recipu -u $localu) || exit 1
		# GPG Sign Encrypt Done
		echo "$outmsg"
		[ $noask ] || {
			echo
			echo ">> Recipient keys: $recipu"
			echo ">> Signer keys: $localu"
			echo ">> Copied Message to Clipboard"
		}
		echo "$outmsg" | xclip -r -sel c
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		[ -z "$recipu" ] && read -r -p "Enter Recipient(s): " recipu; [ -z "$recipu" ] && exit 1
		[ -z "$localu" ] && read -r -p "Enter Signer: " localu; [ -z "$localu" ] && exit 1
		tempfile="/tmp/tmpencmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg -se --armor -r $recipu -u $localu) || exit 1
		# GPG Sign Encrypt Done
		echo "$outmsg"
		echo "$recipu" >"$HOME/.cache/gpglastrec"
		echo "$localu" >"$HOME/.cache/gpglastloc"
		[ $noask ] || read -r -p "Copy Message? [Y/n]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] || [ -z "$topost" ] && (echo "$outmsg" | xclip -r -sel c)
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		[ -z "$recipu" ] && read -r -p "Enter Recipient(s): " recipu; [ -z "$recipu" ] && exit 1
		[ -z "$localu" ] && read -r -p "Enter Signer: " localu; [ -z "$localu" ] && exit 1
		outfile="${POSITIONAL_ARGS}.gpg"
		gpg -se --armor -r $recipu -u $localu --output "$outfile" "$POSITIONAL_ARGS" || exit 1
		# GPG Sign Encrypt Done
		filecontent=$(cat "$outfile") || exit 1
		echo "$recipu" >"$HOME/.cache/gpglastrec"
		echo "$localu" >"$HOME/.cache/gpglastloc"
		[ $noask ] || rm -i "$POSITIONAL_ARGS"
		[ $rmencsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Copy File Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && (echo "$filecontent" | xclip -r -sel c)
		exit 0
	fi
	exit 0
}
decrypt() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		outmsg=$(echo "$msg" | gpg --decrypt) || exit 1
		# GPG Decrypt Done
		echo "$outmsg"
		[ $noask ] || {
			echo
			echo ">> Launching EDITOR..."
			echo "$outmsg" | $EDITOR
		}
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		tempfile="/tmp/tmpdecmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		outmsg=$(cat "$tempfile" | gpg --decrypt) || exit 1
		# GPG Decrypt Done
		rm -f "$tempfile"
		echo "$outmsg"
		[ $noask ] || read -r -p "Copy/Edit/Exit [c/e/N]: " topost
		[ "$topost" = "e" ] || [ "$topost" = "E" ] && (echo "$outmsg" | $EDITOR)
		[ "$topost" = "c" ] || [ "$topost" = "C" ] && (echo "$outmsg" | xclip -r -sel c)
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		outfile=$(echo "${POSITIONAL_ARGS}" | sed 's/.\{4\}$//')
		gpg --decrypt --output "$outfile" "$POSITIONAL_ARGS" || exit 1
		# GPG Decrypt Done
		filecontent=$(cat "$outfile") || exit 1
		[ $noask ] || rm -i "$POSITIONAL_ARGS"; [ $rmdecsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Copy/Open/Exit? [c/O/n]: " topost
		[ "$topost" = "o" ] || [ "$topost" = "O" ] || [ -z "$topost" ] && (xdg-open "$outfile")
		[ "$topost" = "c" ] || [ "$topost" = "C" ] && (echo "$filecontent" | xclip -r -sel c)
		[ $noask ] || rm -i "$outfile"; [ $rmdecoutput = true ] && rm "$outfile"
	fi
	exit 0
}
clearsign() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		localu=$(cat $HOME/.cache/gpglastloc); [ -z "$localu" ] && exit 1
		outmsg=$(echo "$msg" | gpg --clear-sign -u $localu) || exit 1
		# GPG Sign Done
		echo "$outmsg"
		[ $noask ] || {
			echo
			echo ">> Used keys: $localu"
			echo ">> Copied Message to Clipboard"
		}
		echo "$outmsg" | xclip -r -sel c
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		[ -z "$localu" ] && read -r -p "Enter Signer: " localu; [ -z "$localu" ] && exit 1
		tempfile="/tmp/tmpsignmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg --clear-sign -u $localu) || exit 1
		# GPG Sign Done
		echo "$outmsg"
		echo "$localu" >"$HOME/.cache/gpglastloc"
		[ $noask ] || read -r -p "Copy Message? [Y/n]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] || [ -z "$topost" ] && (echo "$outmsg" | xclip -r -sel c)
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		[ -z "$localu" ] && read -r -p "Enter Signer(s): " localu; [ -z "$localu" ] && exit 1
		outfile="${POSITIONAL_ARGS}.asc"
		gpg --sign -u $localu --output "$outfile" "$POSITIONAL_ARGS" || exit 1
		# GPG Sign Done
		filecontent=$(cat "$outfile") || exit 1
		echo "$localu" >"$HOME/.cache/gpglastloc"
		[ $noask ] || rm -i "$POSITIONAL_ARGS"; [ $rmencsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Copy File Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && (echo "$filecontent" | xclip -r -sel c)
	fi
	exit 0
}
detachsign() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		localu=$(cat $HOME/.cache/gpglastloc); [ -z "$localu" ] && exit 1
		outmsg=$(echo "$msg" | gpg --detach-sign --armor -u $localu) || exit 1
		# GPG Detach Sign Done
		echo "$msg" >"$HOME/signed-text-$(date '+%N')"
		echo "$outmsg" >"$HOME/signed-text-$(date '+%N').asc"
		[ $noask ] || {
			echo
			echo ">> Used keys: $localu"
			echo ">> Saved to User's Home as signed-text-NANOSECOND"
		}
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		[ -z "$localu" ] && read -r -p "Enter Signer: " localu; [ -z "$localu" ] && exit 1
		tempfile="/tmp/tmpsignmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg --detach-sign --armor -u $localu) || exit 1
		# GPG Detach Sign Done
		echo "$localu" >"$HOME/.cache/gpglastloc"
		outdir="$HOME/" # default when noask
		outfile="signed-text-$(date '+%N')"
		[ $noask ] || {
			read -r -p "Absolute directory Path (/ on end): " outdir
			read -r -p "Saved Filename: " outfile
		}
		[ -z "$outfile" ] || [ -f "$outfile" ] && exit 1
		echo "$msg" >"${outdir}${outfile}"
		echo "$outmsg" >"${outdir}${outfile}.asc"
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		[ -z "$localu" ] && read -r -p "Enter Signer(s): " localu; [ -z "$localu" ] && exit 1
		outfile="${POSITIONAL_ARGS}.asc"
		gpg --detach-sign --armor -u $localu --output "$outfile" "$POSITIONAL_ARGS" || exit 1
		# GPG Detach Sign Done
		filecontent=$(cat "$outfile") || exit 1
		echo "$localu" >"$HOME/.cache/gpglastloc"
		[ $noask ] || read -r -p "Copy Sign Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && (echo "$filecontent" | xclip -r -sel c)
	fi
	exit 0
}
verifysign() {
	if [ $topipe ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		(echo "$msg" | gpg --verify) || exit 1
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		tempfile="/tmp/tmpvrfmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		(echo "$msg" | gpg --verify) || exit 1
		[ $noask ] || read -r -p "Press Enter to continue... "
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		[ "${POSITIONAL_ARGS[1]}" ] && (gpg --verify "${POSITIONAL_ARGS[0]}" "${POSITIONAL_ARGS[1]}" || exit 1)
		[ ! "${POSITIONAL_ARGS[1]}" ] && (gpg --verify "$POSITIONAL_ARGS" || exit 1)
		[ $noask ] || read -r -p "Press Enter to continue... "
	fi
	exit 0
}

# Helper Functions
helpmsg() {
	echo -e "GPG Bash Master by Chatoyance v1.13 \
	\nOpen an issue here: https://github.com/NoTArZuZ/gpgmaster.sh/issues \
	\n \
	\n[-l] - Use last recipient/signer [-n] - Don't ask anything [-p] - Pipe input \
	\n[-e] - Encrypt [-c] Sign and Encrypt [-d] - Decrypt \
	\n[-s] - Clear Sign [-u] - Detach Sign [-v] - Verify Sign \
	\nPipe flag also uses [-l] and [-n] by default \
	\nJust add file path at the end to use it"
	exit 1
}

# Get Arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-l | --last) getlast=true
		shift
		;;
	-p | --pipe) topipe=true
		shift
		;;
	-n | --noask) noask=true
		shift
		;;
	-e | --encrypt) encryptor=true
		((singleflag += 1))
		shift
		;;
	-c | --sign-encrypt) signcryptor=true
		((singleflag += 1))
		shift
		;;
	-d | --decrypt) decryptor=true
		((singleflag += 1))
		shift
		;;
	-s | --sign) signer=true
		((singleflag += 1))
		shift
		;;
	-u | --detach) detacher=true
		((singleflag += 1))
		shift
		;;
	-v | --verify) verifier=true
		((singleflag += 1))
		shift
		;;
	-* | --*) helpmsg ;;
	*)
		POSITIONAL_ARGS+=("$1")
		shift
		;;
	esac
done

set -- "${POSITIONAL_ARGS[@]}"

# Flag check
[ $singleflag = 1 ] || helpmsg
[ $getlast ] && {
	recipu=$(cat $HOME/.cache/gpglastrec);
	localu=$(cat $HOME/.cache/gpglastloc)
}

# Functions Static Variables
filefmt=$(echo "$POSITIONAL_ARGS" | rev | cut -b -4 | rev)

# Main Program
[ $encryptor ] && encrypt
[ $signcryptor ] && signencrypt
[ $decryptor ] && decrypt
[ $signer ] && clearsign
[ $detacher ] && detachsign
[ $verifier ] && verifysign
