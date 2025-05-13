default:
	zig build-exe main.zig

wasm:
	zig build-exe main_wasm.zig -target wasm32-freestanding -fno-entry -rdynamic

run:
	./main
