SRCDIR := ./src

DC := dmd
DFLAGS := -debug -unittest -inline -w -wi -I$(SRCDIR)
LD := dmd

SOURCES := $(wildcard $(SRCDIR)/*.d)
OBJECTS := $(patsubst %.d, %.o, $(SOURCES))

EXECUTABLE := ae

%.o : %.d
	$(DC) $(DFLAGS) -c $< -of$@

.PHONY: all
all: build

.PHONY: build
build: $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -of$(EXECUTABLE)

.PHONY: tests
tests: build
	./$(EXECUTABLE)

.PHONY: clean
clean:
	$(RM) $(OBJECTS) $(EXECUTABLE)
