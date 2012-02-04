#!/usr/bin/env bash

if [[ ! -f NamesList.txt ]]; then
	# grab the latest list of Unicode names
	wget http://unicode.org/Public/UNIDATA/NamesList.txt
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
cat codepoints.c.almost | tail -n -2 | sed -e 's/,$//' > codepoints.c.fixup
cat names.c.almost | tail -n -2 | sed -e 's/,$//' > names.c.fixup

# swap in the fixup lines
cat codepoints.c.almost | head -n -2 | cat - codepoints.c.fixup > codepoints.c
cat names.c.almost | head -n -2 | cat - names.c.fixup > names.c

# tie everything together
cat << EOS > unicode.c
$(cat names.c)

$(cat codepoints.c)

#define NUM_UNICODE $(cat names.txt | wc -l)
EOS
