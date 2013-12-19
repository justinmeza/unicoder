#!/usr/bin/env bash

if type curl 2> /dev/null; then
	GET="curl -O"
	GET_RENAME="curl -o"
else
	GET="wget"
	GET_RENAME="wget -O"
fi

function msg()
{
	echo "$0: $1 (press any key to continue)"
	return $(read line)
}

if [[ ! -f NamesList.txt ]]; then
	# grab the latest list of Unicode names
	${GET} http://unicode.org/Public/UNIDATA/NamesList.txt
else
	msg "detected existing NamesList.txt: press any key to download latest and check for differences"
	${GET_RENAME} NamesList.txt.new http://unicode.org/Public/UNIDATA/NamesList.txt
	if [[ `diff -s NamesList.txt NamesList.txt.new` ]]; then
		date=`date +%Y-%m-%d`
		msg "files match: deleting downloaded file and exiting"
		rm NamesList.txt.new
	else
		msg "files differ! moving current NamesList.txt to NamesList.txt.old and generating new unicode.c"
		mv NamesList.txt NamesList.txt.old
		mv NamesList.txt.new NamesList.txt
	fi
fi

# get the lines with codepoints and names
cat NamesList.txt | awk '/^[0-9A-F]+.*[A-Z-]+$/' | sort -k 2 > sorted.txt

# cut out the codepoints and names
cat sorted.txt | cut -d'	' -f 1 > codepoints.txt
cat sorted.txt | cut -d'	' -f 2 > names.txt

# generate the C files
cat << EOS > codepoints.c.almost
static const long codepoints[] = {
$(cat codepoints.txt | sed -e 's/^\(.*\)$/	0x\1,/')
};
EOS
cat << EOS > names.c.almost
static const char *names[] = {
$(cat names.txt | sed -e 's/^\(.*\)$/	"\1",/')
};
EOS

# remove the comma from the last array entry
cat codepoints.c.almost | tail -n 2 | sed -e 's/,$//' > codepoints.c.fixup
cat names.c.almost | tail -n 2 | sed -e 's/,$//' > names.c.fixup

# swap in the fixup lines
cat codepoints.c.almost | head -n $(( $(wc -l codepoints.c.almost | awk '{print $1}') - 2 )) | cat - codepoints.c.fixup > codepoints.c
cat names.c.almost | head -n $(( $(wc -l names.c.almost | awk '{print $1}') - 2 )) | cat - names.c.fixup > names.c

# tie everything together
cat << EOS > unicode.c
$(cat names.c)

$(cat codepoints.c)

#define NUM_UNICODE $(cat names.txt | wc -l | tr -d ' ')
EOS
