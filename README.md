# Express.jq

A tongue-in-cheek demonstration of jq as a capable programming language,
implementing an HTTP server.

Requires `socat` and `jq` in `$PATH`, and some version of Bash.

Probably not standards-compliant. Use at own risk.

## Next steps

(not really, but it's fun to imagine)

- Support requests with bodies.

- Helper functions to build HTML markup.

- Split the request handlers into separate files `import`ed in the entry point.

- Make the server stateful: the runner script could be extended to somehow
  persist state to disk.
  
  One very hacky way would be to output two shell commands from jq: one that
  writes to a state file and the other that prints the response to stdout as
  usual. We can slurp that state file into jq.
