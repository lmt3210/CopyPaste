# CC=clang++

OPTS=-Wall -Werror -pedantic -O2
LOPTS=-framework ApplicationServices

TARGET=macpaste

all: $(TARGET)

$(TARGET): cmdmain.o macpaste.o
	$(CC) $(LOPTS) -o $@ $^

cmdmain.o : Source/cmdmain.c
	$(CC) -c $(OPTS) $<

macpaste.o : Source/macpaste.c
	$(CC) -c $(OPTS) $<

clean:
	rm -f $(TARGET) *.o

install: $(TARGET)
	cp $(TARGET) /Users/Larry/bin

