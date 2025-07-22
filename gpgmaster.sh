#!/usr/bin/env bash
# Dependencies: GPG
# GPG Bash Master by Chatoyance

# USER DEFINED VARIABLES
rmencsource=false
rmdecsource=false
rmdecoutput=false

POSITIONAL_ARGS=()

# Main Functions
encrypt() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		email=$(cat $HOME/.cache/gpglastrec); [ -z "$email" ] && exit 1
		outmsg=$(echo "$msg" | gpg --encrypt --armor -r $email)
		# GPG Encrypt Done
		echo "$email" > "$HOME/.cache/gpglastrec"
		echo "$outmsg"
		[ $noask ] || echo
		[ $noask ] || echo ">> Used keys: $email"
		[ $noask ] || echo ">> Copied Message to Clipboard"
		echo "$outmsg" | xclip -r -sel c
	elif [ -z "$POSITIONAL_ARGS" ]; then
		# [ -z ] NO ARGUMENT
		[ -z "$email" ] && read -r -p "Enter Recipient(s): " email; [ -z "$email" ] && exit 1
		tempfile="/tmp/tmpencmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg --encrypt --armor -r $email)
		# GPG Encrypt Done
		echo "$outmsg"
		echo "$email" > "$HOME/.cache/gpglastrec"
		[ $noask ] || read -r -p "Copy Message? [Y/n]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] || [ -z "$topost" ] && ( echo "$outmsg" | xclip -r -sel c )
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
		# [ -f ] FILE ARGUMENT
		[ -z "$email" ] && read -r -p "Enter Recipient(s): " email; [ -z "$email" ] && exit 1
		outfile="${POSITIONAL_ARGS}.gpg"
		gpg --encrypt --armor -r $email --output "$outfile" "$POSITIONAL_ARGS"
		# GPG Encrypt Done
		filecontent=$(cat "$outfile")
		echo "$email" > "$HOME/.cache/gpglastrec"
		[ $noask ] || rm -i "$POSITIONAL_ARGS"
		[ $rmencsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Copy File Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && ( echo "$filecontent" | xclip -r -sel c )
		exit 0
	fi
	exit 0
}
decrypt() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
		# [ -p ] PIPE OPTION
		msg=$(cat)
		outmsg=$(echo "$msg" | gpg --decrypt) || exit 1
		# GPG Decrypt Done
		echo "$outmsg"
		[ $noask ] || echo
		[ $noask ] || echo ">> Launching EDITOR..."
		[ $noask ] || echo "$outmsg" | $EDITOR
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
		[ "$topost" = "e" ] || [ "$topost" = "E" ] && ( echo "$outmsg" | $EDITOR )
		[ "$topost" = "c" ] || [ "$topost" = "C" ] && ( echo "$outmsg" | xclip -r -sel c )
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
	# [ -f ] FILE ARGUMENT
		outfile=$(echo "${POSITIONAL_ARGS}" | sed 's/.\{4\}$//')
		gpg --decrypt --output "$outfile" "$POSITIONAL_ARGS" || exit 1
		# GPG Decrypt Done
		[ $noask ] || rm -i "$POSITIONAL_ARGS"
		[ $rmdecsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Open file? [Y/n]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] || [ -z "$topost" ] && ( xdg-open "$outfile" )
		[ $noask ] || rm -i "$outfile"
		[ $rmdecoutput = true ] && rm "$outfile"
	fi
	exit 0
}
clearsign() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
	# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		email=$(cat $HOME/.cache/gpglastloc); [ -z "$email" ] && exit 1
		outmsg=$(echo "$msg" | gpg --clear-sign -u $email)
		# GPG Sign Done
		echo "$outmsg"
		[ $noask ] || echo
		[ $noask ] || echo ">> Used keys: $email"
		[ $noask ] || echo ">> Copied Message to Clipboard"
		echo "$outmsg" | xclip -r -sel c
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
	# [ -z ] NO ARGUMENT
		[ -z "$email" ] && read -r -p "Enter Signer: " email; [ -z "$email" ] && exit 1
		tempfile="/tmp/tmpsignmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg --clear-sign -u $email)
		# GPG Sign Done
		echo "$outmsg"
		echo "$email" > "$HOME/.cache/gpglastloc"
		[ $noask ] || read -r -p "Copy Message? [Y/n]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] || [ -z "$topost" ] && ( echo "$outmsg" | xclip -r -sel c )
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
	# [ -f ] FILE ARGUMENT
		[ -z "$email" ] && read -r -p "Enter Signer(s): " email; [ -z "$email" ] && exit 1
		outfile="${POSITIONAL_ARGS}.asc"
		gpg --sign -u $email --output "$outfile" "$POSITIONAL_ARGS"
		# GPG Sign Done
		filecontent=$(cat "$outfile")
		echo "$email" > "$HOME/.cache/gpglastloc"
		[ $noask ] || rm -i "$POSITIONAL_ARGS"
		[ $rmencsource = true ] && rm "$POSITIONAL_ARGS"
		[ $noask ] || read -r -p "Copy File Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && ( echo "$filecontent" | xclip -r -sel c )
	fi
	exit 0
}
detachsign() {
	if [ $topipe ] && [ -z "$POSITIONAL_ARGS" ]; then
	# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		email=$(cat $HOME/.cache/gpglastloc); [ -z "$email" ] && exit 1
		outmsg=$(echo "$msg" | gpg --detach-sign --armor -u $email)
		# GPG Detach Sign Done
		echo "$msg" > "$HOME/signed-text-$(date '+%N')"
		echo "$outmsg" > "$HOME/signed-text-$(date '+%N').asc"
		[ $noask ] || echo
		[ $noask ] || echo ">> Used keys: $email"
		[ $noask ] || echo ">> Saved to User's Home as signed-text-NANOSECOND"
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
	# [ -z ] NO ARGUMENT
		[ -z "$email" ] && read -r -p "Enter Signer: " email; [ -z "$email" ] && exit 1
		tempfile="/tmp/tmpsignmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		rm -f "$tempfile"
		outmsg=$(echo "$msg" | gpg --detach-sign --armor -u $email)
		# GPG Detach Sign Done
		echo "$email" > "$HOME/.cache/gpglastloc"
		outdir="$HOME/" # default when noask
		outfile="signed-text-$(date '+%N')"
		[ $noask ] || read -r -p "Absolute directory Path (/ on end): " outdir
		[ $noask ] || read -r -p "Saved Filename: " outfile; [ -z "$outfile" ] || [ -f "$outfile" ] && exit 1
		echo "$msg" > "${outdir}${outfile}"
		echo "$outmsg" > "${outdir}${outfile}.asc"
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
	# [ -f ] FILE ARGUMENT
		[ -z "$email" ] && read -r -p "Enter Signer(s): " email; [ -z "$email" ] && exit 1
		outfile="${POSITIONAL_ARGS}.asc"
		gpg --detach-sign --armor -u $email --output "$outfile" "$POSITIONAL_ARGS"
		# GPG Detach Sign Done
		echo "$email" > "$HOME/.cache/gpglastloc"
		filecontent=$(cat "$outfile")
		[ $noask ] || read -r -p "Copy Sign Content? [y/N]: " topost
		[ "$topost" = "y" ] || [ "$topost" = "Y" ] && ( echo "$filecontent" | xclip -r -sel c )
	fi
	exit 0
}
verifysign() {
	if [ $topipe ]; then
	# [ -p ] PIPE OPTION
		msg=$(cat); [ -z "$msg" ] && exit 1
		( echo "$msg" | gpg --verify ) || exit 1
		exit 0
	elif [ -z "$POSITIONAL_ARGS" ]; then
	# [ -z ] NO ARGUMENT
		tempfile="/tmp/tmpvrfmsg-$(date '+%N')"
		$EDITOR "$tempfile"; [ -s "$tempfile" ] || exit 1
		msg=$(cat "$tempfile")
		( echo "$msg" | gpg --verify ) || exit 1
		[ $noask ] || read -r -p "Press Enter to continue... "
	elif [ -n "$POSITIONAL_ARGS" ] && [ -f "$POSITIONAL_ARGS" ]; then
	# [ -f ] FILE ARGUMENT
		[ "${POSITIONAL_ARGS[1]}" ] && ( gpg --verify "${POSITIONAL_ARGS[0]}" "${POSITIONAL_ARGS[1]}" || exit 1 )
		[ ! "${POSITIONAL_ARGS[1]}" ] && ( gpg --verify "$POSITIONAL_ARGS" || exit 1 )
		[ $noask ] || read -r -p "Press Enter to continue... "
	fi
	exit 0
}

# Helper Functions
getlastemail() {
	[ ! $signer ] && email=$(cat $HOME/.cache/gpglastrec)
	[ $signer ] && email=$(cat $HOME/.cache/gpglastloc)
}
helpmsg() {
	echo -e "[-l] - Use last recipient/signer [-n] - Don't ask anything [-p] - Pipe input \
	\n[-e] - Encrypt [-d] - Decrypt [-s] - Clear Sign [-u] - Detach Sign [-v] - Verify Sign \
	\nPipe flag also uses [-l] and [-n] by default \
	\nJust add file path at the end to use it"
	exit 1
}

# Get Arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -l|--last) getlast=true; shift ;;
  -p|--pipe) topipe=true; shift ;;
  -n|--noask) noask=true; shift ;;
  -e|--encrypt) encryptor=true;
  	singleflag+=1; shift
  ;;
  -d|--decrypt) decryptor=true;
  	singleflag+=1; shift
  ;;
  -s|--sign) signer=true;
		singleflag+=1; shift
	;;
  -u|--detach) detacher=true;
	  singleflag+=1; shift
	;;
  -v|--verify) verifier=true;
	  singleflag+=1; shift
	;;
  -*|--*) helpmsg ;;
  *) POSITIONAL_ARGS+=("$1"); shift ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

# Flag check
[ $singleflag = 1 ] || exit 1
[ $getlast ] && getlastemail

# Functions Static Variables
filefmt=$(echo "$POSITIONAL_ARGS" | rev | cut -b -4 | rev)

# Main Program
if [ $encryptor ]; then encrypt;
elif [ $decryptor ]; then decrypt;
elif [ $signer ]; then clearsign;
elif [ $detacher ]; then detachsign;
elif [ $verifier ]; then verifysign;
fi

[ -z "$POSITIONAL_ARGS" ] && helpmsg
