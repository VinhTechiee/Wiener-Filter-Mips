# Wiener Filter Implementation in MIPS Assembly

## Overview
This project implements a **Wiener filter** in **MIPS assembly**, developed for the *Computer Architecture Lab (CO2008)* course.  
The filter estimates a desired signal from a noisy input by minimizing the **Mean Square Error (MSE)** under the **MMSE criterion**.

---

## Problem Statement
Given:
- Input signal: \( x(n) = s(n) + w(n) \)
- Desired signal: \( d(n) \)

Design a finite-length linear filter:
\[
y(n) = \sum_{k=0}^{M-1} h_k x(n-k)
\]
such that the mean-square error between \( y(n) \) and \( d(n) \) is minimized.

---

## Methodology
The Wiener filter is obtained by solving the **Wiener–Hopf equations**:
\[
\mathbf{R}_M \mathbf{h} = \boldsymbol{\gamma}_d
\]
where:
- \( \mathbf{R}_M \): Toeplitz autocorrelation matrix of the input signal  
- \( \boldsymbol{\gamma}_d \): cross-correlation vector between desired and input signals  

The optimal coefficients are:
\[
\mathbf{h}_{opt} = \mathbf{R}_M^{-1} \boldsymbol{\gamma}_d
\]

The **MMSE** is computed as:
\[
\text{MMSE} = \frac{1}{M} \sum_{n=0}^{M-1} (d(n) - y(n))^2
\]

---

## Implementation
The program is written entirely in **MIPS assembly** and includes:
- Parsing floating-point input from text files
- Autocorrelation and cross-correlation computation
- Toeplitz matrix construction
- Linear system solving using Gaussian elimination
- Wiener filtering
- MMSE evaluation
- Output formatting and file writing

---

## Input and Output
### Input
- `input.txt`: noisy input signal (10 floating-point values)
- `desired.txt`: desired signal (10 floating-point values)

### Output
- `output.txt`:
  - Filtered output sequence
  - MMSE value

If the input sizes do not match:
- Error: size not match
  
---

## Project Structure
Wiener-Filter-Mips/
├── src/
│ └── wiener_filter.asm # Main MIPS implementation
│
├── data/
│ ├── input.txt # Noisy input signal
│ ├── desired.txt # Desired signal
│ └── expected.txt # Reference output (optional)
│
├── tools/
│ └── Mars45.jar # MARS simulator (optional)
│
├── .gitignore
├── README.md
└── output.txt # Generated output (optional)

---

## How to Run
1. Open the `.asm` file in **MARS MIPS Simulator**.
2. Place `input.txt` and `desired.txt` in the working directory.
3. Run the program.
4. View results in the terminal and `output.txt`.

