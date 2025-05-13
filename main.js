const fs = require("node:fs");

const wasmBuf = fs.readFileSync("./main_wasm.wasm");

WebAssembly.instantiate(wasmBuf, {
  env: {
    print: (d) => console.log("[fromWasm]", d)
  }
}).then(wasmModule => {
  console.log(wasmModule.instance.exports);
  const { allocMem, freeMem, main, memory } = wasmModule.instance.exports;

  const sampleStr = "140000612082900704000000000070004000008500370013000000000800000005109000700040100";
  const encoder = new TextEncoder();
  const bytes = encoder.encode(sampleStr);

  const ptr = allocMem();
  const wasmMem = new Uint8Array(memory.buffer, ptr, 81);
  // write the string to the wasm memory
  wasmMem.set(bytes);

  const decoder = new TextDecoder("utf-8");
  // solve the sudoku
  const result = main(ptr);
  if (result === 1) {
    const str = decoder.decode(wasmMem);
    console.log("result", str);
  } else {
    const str = decoder.decode(wasmMem.slice(0, 7));
    console.log("result", str);
  }
});
