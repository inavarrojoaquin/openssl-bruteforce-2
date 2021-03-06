CC=gcc-4.8
CC_1=gcc-4.9
MPICC=mpicc
LDFLAGS?=-std=c99 -O0 -Wall
LDFLAGS_1=-std=c99 -O3 -Wall
LDLIBS=-lcrypto -ldl
CUNITLIB=-lcunit

OBJ=obj
BIN=bin
SRC=src
INCLUDE=include
TMP=tmp

SOURCES=$(SRC)/fs.c $(SRC)/keygen.c $(SRC)/encryptor.c $(SRC)/commons.c
HEADERS=$(INCLUDE)/fs.h $(INCLUDE)/keygen.h $(INCLUDE)/encryptor.h $(INCLUDE)/commons.h
OBJECTS=$(OBJ)/keygen.o $(OBJ)/fs.o $(OBJ)/encryptor.o $(OBJ)/commons.o
TARGETS=$(BIN)/serial $(BIN)/omp $(BIN)/mpi $(BIN)/encrypt $(BIN)/decrypt

.PHONY: all
all: $(TARGETS)

test: test-unit test-utils test-app 

test-unit: $(BIN)/unit-tests
	@./$(BIN)/unit-tests 2> /dev/null

test-app: $(TARGETS)
	@bash ./scripts/test-app.sh

test-utils: $(TARGETS)
	@bash ./scripts/test-utils.sh

install: 
	@bash ./scripts/install-libs.sh

report:
	@bash ./scripts/make-report.sh

## binary files

$(BIN)/serial: $(OBJ)/serial.o $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

$(BIN)/serial-1: $(SRC)/serial-1.c
	$(CC_1) $(LDFLAGS_1) $^ -o $@  $(LDLIBS)

$(BIN)/omp: $(OBJ)/omp.o $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS) -fopenmp

$(BIN)/omp-1: $(SRC)/omp-1.c 
	$(CC_1) $(LDFLAGS_1) $^ -o $@ $(LDLIBS) -fopenmp

$(BIN)/mpi: $(OBJ)/mpi.o  $(OBJECTS)
	$(MPICC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

$(BIN)/mpi-1: $(SRC)/mpi-1.c
	$(MPICC) $(LDFLAGS_1) $^ -o $@ $(LDLIBS)

$(BIN)/encrypt: $(OBJ)/encrypt.o $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@  $(LDLIBS)

$(BIN)/decrypt: $(OBJ)/decrypt.o $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

## tests files

$(BIN)/unit-tests: $(OBJ)/unit-tests.o $(OBJECTS)
	$(CC) $(LDFLAGS) -L/usr/local/lib $^ -o $@ $(LDLIBS) $(CUNITLIB) -fopenmp

## object files

$(OBJ)/serial.o: $(SRC)/serial.c $(HEADERS)
	$(CC) $(LDFLAGS) -c $(SRC)/serial.c -o $@ $(LDLIBS)

$(OBJ)/omp.o: $(SRC)/omp.c $(HEADERS)
	$(CC) $(LDFLAGS) -c $(SRC)/omp.c -o $@ $(LDLIBS) -fopenmp

$(OBJ)/mpi.o: $(SRC)/mpi.c $(HEADERS)
	$(MPICC) $(LDFLAGS) -c $(SRC)/mpi.c -o $@

$(OBJ)/unit-tests.o: $(SRC)/unit-tests.c $(HEADERS)
	$(CC) $(LDFLAGS) -c $(SRC)/unit-tests.c -o $@ $(LDLIBS) -fopenmp

$(OBJ)/encrypt.o: $(SRC)/encrypt.c $(HEADERS)
	$(CC) $(LDFLAGS) -c $(SRC)/encrypt.c -o $@ $(LDLIBS) 

$(OBJ)/decrypt.o: $(SRC)/decrypt.c $(HEADERS)
	$(CC) $(LDFLAGS) -c $(SRC)/decrypt.c -o $@ $(LDLIBS)

$(OBJ)/keygen.o: $(SRC)/keygen.c $(INCLUDE)/keygen.h
	$(CC) $(LDFLAGS) -c $(SRC)/keygen.c -o $@

$(OBJ)/fs.o: $(SRC)/fs.c $(INCLUDE)/fs.h
	 $(CC) $(LDFLAGS) -c $(SRC)/fs.c -o $@

$(OBJ)/encryptor.o: $(SRC)/encryptor.c $(INCLUDE)/encryptor.h
	$(CC) $(LDFLAGS) -c $(SRC)/encryptor.c -o $@ $(LDLIBS)

$(OBJ)/commons.o: $(SRC)/commons.c $(INCLUDE)/commons.h
	$(CC) $(LDFLAGS) -c $(SRC)/commons.c -o $@ $(LDLIBS)

## tmp files

$(TMP)/testfile:
	echo "Frase: Never be led astray onto the path of virtue." > $(TMP)/testfile

$(TMP)/encryptedfile: $(BIN)/encrypt $(TMP)/testfile
	./$(BIN)/encrypt $(TMP)/testfile 5000000 blowfish $(TMP)/encryptedfile

## commands

gcov: clean
	LDFLAGS="-std=c99 -Wall -O0 --coverage -g" $(MAKE) all $(TMP)/encryptedfile
	CANT_KEYS=500000 ./$(BIN)/serial $(TMP)/encryptedfile || echo done
	lcov -o cov.info -c -d obj/
	genhtml -o cov cov.info
	google-chrome cov/index.html

gcov_2: clean $(TMP)/encryptedfile
	$(CC_1) -std=c99 -Wall -O0 --coverage -g $(SRC)/serial-1.c -o $(BIN)/serial-1 $(LDLIBS)
	CANT_KEYS=500000 ./$(BIN)/serial-1 $(TMP)/encryptedfile || echo done
	lcov -o cov_2.info -c -d .
	genhtml -o cov_2 cov_2.info
	google-chrome cov_2/index.html

gprof: clean
	LDFLAGS="-std=c99 -Wall -O0 -pg -g" $(MAKE) all $(TMP)/encryptedfile
	CANT_KEYS=50000 ./$(BIN)/serial $(TMP)/encryptedfile || echo done
	gprof ./$(BIN)/serial gmon.out  > gprof.out
	less gprof.out

gprof_2: clean $(TMP)/encryptedfile
	$(CC_1) -std=c99 -Wall -O0 --coverage -pg -g $(SRC)/serial-1.c -o $(BIN)/serial-1 $(LDLIBS)
	CANT_KEYS=50000 ./$(BIN)/serial-1 $(TMP)/encryptedfile || echo done
	gprof ./$(BIN)/serial-1 gmon.out  > gprof_2.out
	less gprof_2.out

memcheck: clean 
	LDFLAGS="-std=c99 -Wall -O0 -g" $(MAKE) all $(TMP)/encryptedfile
	CANT_KEYS=50000 valgrind --leak-check=yes $(BIN)/serial $(TMP)/encryptedfile || echo done

memcheck_2: clean $(TMP)/encryptedfile
	LDFLAGS="-std=c99 -Wall -O0 -g" $(MAKE) all
	$(CC_1) -std=c99 -Wall -O0 -g $(SRC)/serial-1.c -o bin/serial-1 $(LDLIBS)
	CANT_KEYS=50000 valgrind --leak-check=yes $(BIN)/serial-1 $(TMP)/encryptedfile || echo done

cachegrind: clean
	LDFLAGS="-std=c99 -Wall -O0 -g" $(MAKE) all $(TMP)/encryptedfile
	CANT_KEYS=50000 valgrind --tool=cachegrind $(BIN)/serial $(TMP)/encryptedfile || echo done

cachegrind_2: clean $(TMP)/encryptedfile
	$(CC_1) -std=c99 -Wall -O0 -g $(SRC)/serial-1.c -o bin/serial-1 $(LDLIBS)
	CANT_KEYS=50000 valgrind --tool=cachegrind $(BIN)/serial-1 $(TMP)/encryptedfile || echo done

callgrind: clean
	LDFLAGS="-std=c99 -Wall -O0 -g" $(MAKE) all $(TMP)/encryptedfile
	CANT_KEYS=50000 valgrind --tool=callgrind $(BIN)/serial $(TMP)/encryptedfile || echo done

callgrind_2: clean $(TMP)/encryptedfile
	$(CC_1) -std=c99 -Wall -O0 -g $(SRC)/serial-1.c -o $(BIN)/serial-1 $(LDLIBS)
	CANT_KEYS=50000 valgrind --tool=callgrind $(BIN)/serial-1 $(TMP)/encryptedfile || echo done

clean:
	rm -f $(BIN)/* $(OBJ)/*
