# worker_process

A OCaml package to start and control worker as system processes.

# Description

`worker_process` contains two module functors to enable easy offloading of computational work to a separate (worker) process. This will also enable the usage of multiple processor cores.

The `Master` module is responsible for starting a number of worker processes, sending requests to them and collecting the response.

The `Processor` module includes the boilerplate to start worker processes, listens to requests and send the processed answers.

Communication between controller and workers is done via sockets and uses [ZeroMQ](https://zeromq.org/). The "pipeline" pattern is applied, so all started workers listen on the same channel and send the response on another (single) channel back to the controller.

# Installation

So far, this package is not released on opam, so you have to pin this repo:

`opam pin worker_process https://github.com/kkirstein/ocaml-worker-process`

`opam install worker_process`

# Status

Alpha status, API might change (see below)

## TODOs

* Provide an example
* Use a dedicated logger instead of simple `verbose` flag for writing status, error, and debug messages
* ...


# License

MIT

