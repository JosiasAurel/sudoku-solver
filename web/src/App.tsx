import { useState } from 'react'
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
            outGrid[row][column] = parseInt(str);
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
        print: (d: any) => console.log("[fromWasm]", d)
      }
    }).then(wasmModule => {
      // console.log(wasmModule.instance.exports);
      const { allocMem, main, memory } = wasmModule.instance.exports as any;

      // const sampleStr = "140000612082900704000000000070004000008500370013000000000800000005109000700040100";
        const gridStr = gridToStr();
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
      <h1> Sudoku Solver (wasm) </h1>
        <p> (Input your sudoku problem and hit <em>solve</em>!) </p>
      <div className="grid-container">
        {sudokuGrid.map((subgrid, i) => (
          <span key={i}>
            {subgrid.map((entry, j) => (
                <input key={j} min={0} max={9} type="number" value={entry} onChange={e => {
                  const gridCopy = [...sudokuGrid];
                  gridCopy[i][j] = parseInt(e.target.value.slice(-1));
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

      <footer>
        <p>
          Checkout my <a href="https://github.com/josiasaurel">GitHub</a> — <a href="https://josiasw.dev/">Josias </a>
        </p>
      </footer>
   </>
  )
}

export default App
