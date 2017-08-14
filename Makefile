all: parser.y scanner.l test.cal
	bison -d parser.y -o parser.cpp
	flex -o scanner.cpp scanner.l
	g++ parser.cpp scanner.cpp -ll -o calculator
	./calculator test.cal

clean:
	rm -f parser.cpp parser.output parser.hpp
	rm -f scanner.cpp
	rm -f calculator
