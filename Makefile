default:
	zig build-exe main.zig

wasm:
	zig build-exe main.zig -target wasm32-wasi

run:
	./main