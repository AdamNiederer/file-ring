# file-ring

Quickly switch between related files

## Setup

To quickly switch between a set of files, customize `file-ring--rings` with the
extensions of the files you wish to quickly switch between, and, optionally, a
key for going directly to a specific file in a ring.

`file-ring--rings` accepts a list of multiple rings, in descending order of
matching priority. That is, if you have a ring which matches files ending in
`.hpp` and `.cpp`, you'll probably want to put it after the ring which
matches files ending in `.myext.cpp` and `.myext.hpp`.

## Usage

To quickly get started with `file-ring`, activate `file-ring-mode` and use any
of the following commands:

- `C-c C-o` or `file-ring-next` opens the next existing file in the ring. If a
  prefix argument is provided, opens or creates the next file in the ring.
- `C-c C-p` or `file-ring-prev` opens the next existing file in the ring. If a
  prefix argument is provided, opens or creates the previous file in the ring.
- `C-c C-i` or `file-ring-goto` opens a specific file in a ring which
  corresponds to a provided key combination. If multiple files have the same
  combination, the first existing file is chosen. If no files exist, the first
  file is created.

`file-ring-next`, `file-ring-prev`, and `file-ring-goto` may also be bound to
other keymaps, at your option.

## API

`file-ring` follows semantic versioning for its exported functions. Exported
functions begin with `file-ring-`, while internal functions begin with
`file-ring--`. No stability guarantees are granted for internal functions.

`file-ring` is also developed using separate logic and orchestration whereever
possible. This means you can call most internal functions without risk of
harming `file-ring` or Emacs. Functions which are always safe to call are marked
with the appropriate `declare` forms.
