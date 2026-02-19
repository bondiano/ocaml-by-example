.PHONY: help build test clean format format-check book

help:
	@echo "ocaml-by-example"
	@echo ""
	@echo "Available commands:"
	@echo "  build        - Build all exercises"
	@echo "  test         - Run all tests"
	@echo "  format       - Format source code"
	@echo "  format-check - Check code formatting"
	@echo "  book         - Build the mdBook"
	@echo "  clean        - Clean build artifacts"
	@echo ""

# Build all exercises
build:
	@echo "Building all exercises..."
	@bash scripts/build-all.sh

# Run all tests
test:
	@echo "Running all tests..."
	@bash scripts/test-all.sh

# Format source code
format:
	@echo "Formatting source code..."
	@dune build @fmt --auto-promote

# Check formatting (will fail if code is not formatted)
format-check:
	@echo "Checking code formatting..."
	@dune build @fmt

# Build the mdBook
book:
	@echo "Building book..."
	@mdbook build

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@dune clean
	@rm -rf output
