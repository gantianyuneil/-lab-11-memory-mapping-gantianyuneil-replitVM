CC := gcc
CFLAGS := -ggdb -O0 -Wall -Werror -std=c99 -D_DEFAULT_SOURCE

all: invert

invert: invert.o
	@chmod -w images/*.pbm
	$(CC) -o $@ $^

test: white-inverted.pbm black-inverted.pbm
	@if ! cmp -s white-inverted.pbm images/black.pbm; then \
	    echo "Inverted white image is wrong.";             \
	else                                                   \
	    echo "Inverted white image is correct.";           \
	fi
	@if ! cmp -s black-inverted.pbm images/white.pbm; then \
	    echo "Inverted black image is wrong.";             \
	else                                                   \
	    echo "Inverted black image is correct.";           \
	fi

%-inverted.pbm: images/%.pbm invert
	cp $< $@
	chmod +w $@
	./invert $@

%.o: %.c
	$(CC) -o $@ -c $^ $(CFLAGS)

clean:
	rm -f *~ *.o output.pbm

.PHONY: all clean test
