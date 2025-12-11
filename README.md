# Langda — Loop Detector Gem

Langda automatically detects slow loops in Ruby & Rails.

## What It Does

- Counts loop iterations
- Detects slow loops
- Logs performance warnings
- Works automatically (no need to wrap code)

## Example Log

[Langda] each loop — 1244 iterations — 10.2 ms

## Installation

gem install langda

## Usage

Just add the gem — no configuration needed.
It monkey-patches Array & Hash iteration methods.
