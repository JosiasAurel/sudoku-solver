# Sodoku Solver

A program that takes in a Sudoku grid and finds the numbers that fit in the empty slots.

Sudoku is a 9-by-9 game where you get a grid with partially filled numbers and your goal is to fill them such that there are no duplicate numbers on the same column, row and 3-by-3 sub-grid.

## How to solve sudoku

1. Look over the grid step-by-step
2. If you encounter an empty slot, 
    - Look at the numbers in use on the slots column, row and 3-by-3 sub-grid.
    - Determine what numbers between 0-9 are in neither the column, row or 3-by-3 sub-grid.
3. continue