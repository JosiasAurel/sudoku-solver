import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [sudokuGrid, setSudokuGrid] = useState<Array<Array<number>>>(
    new Array(9).fill(0).map(() => new Array(9).fill(0))
  );

  function gridToStr() {
    return sudokuGrid.map(subgrid => subgrid.map(entry => entry.toString()).join("")).join("");
  }

  function gridFromStr(gridStr: string) {
    const strArr = gridStr.split("");
    let outGrid = new Array(9).fill(0).map(() => new Array(9).fill(0));
    var row = 0;
    var column = 0;
    for (let i = 0; i < strArr.length; i++) {
      const str = strArr[i];
        if ((i + 1) % 9 == 0) {
            row += 1;
            column = 0;
            continue;
        }
        outGrid[row][column] = parseInt(str);
        column += 1;
    }
    return outGrid;
  }

  function instanceAndSolve() {
    WebAssembly.instantiateStreaming(fetch("sudoku.wasm"), {
      env: {
        print: (d) => console.log("[fromWasm]", d)
      }
    }).then(wasmModule => {
      console.log(wasmModule.instance.exports);
      const { allocMem, freeMem, main, memory } = wasmModule.instance.exports;

      // const sampleStr = "140000612082900704000000000070004000008500370013000000000800000005109000700040100";
        const gridStr = gridToStr(sudokuGrid);
      const encoder = new TextEncoder();
      const bytes = encoder.encode(gridStr);

      const ptr = allocMem();
      const wasmMem = new Uint8Array(memory.buffer, ptr, 81);
      // write the string to the wasm memory
      wasmMem.set(bytes);

      const decoder = new TextDecoder("utf-8");
      // solve the sudoku
      const result = main(ptr);
      if (result === 1) {
        const str = decoder.decode(wasmMem);
          setSudokuGrid(gridFromStr(str));
          alert("Solved!");
        // console.log("result", str);
      } else {
        const str = decoder.decode(wasmMem.slice(0, 7));
        alert(str);
        // console.log("result", str);
      }
    })
  }

  /*
  useEffect(() => {
    console.log(gridToStr());
    console.log(gridFromStr("040000612082900704000000000070004000008500370013000000000800000005109000700040100"));
  }, [sudokuGrid]);

  */

  return (
    <>
      <div className="grid-container">
        {sudokuGrid.map((subgrid, i) => (
          <span key={i}>
            {subgrid.map((entry, j) => (
                <input key={j} type="number" value={entry} onChange={e => {
                  const gridCopy = [...sudokuGrid];
                  gridCopy[i][j] = parseInt(e.target.value);
                  setSudokuGrid(() => gridCopy);
              }} />
            ))}
          </span>
        ))}
      </div>
        <br />
      <button onClick={() => {
          instanceAndSolve();
        }}>
        Solve
      </button>
   </>
  )
}

export default App
