all: unicoder

unicoder:
	./unicoder.sh

clean:
	rm -f NamesList.txt
	rm -f sorted.txt
	rm -f codepoints.txt
	rm -f names.txt
	rm -f names.c.almost
	rm -f codepoints.c.almost
	rm -f names.c.fixup
	rm -f codepoints.c.fixup
	rm -f names.c
	rm -f codepoints.c
	rm -f unicode.c
