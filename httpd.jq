#!/usr/bin/env -S jq -Rrnf --rawfile self httpd.jq

def ingest_verb($l):
  (.phase = 1) + (
    $l
    | split(" ")
    | { verb: .[0], path: .[1], version: .[2]}
  );

def ingest_header($l):
  .headers += (
    $l
    | split(": ")
    | {(.[0] | ascii_downcase): .[1]}
  )
;

def finish:
  .phase = "done"
;

def ingest($l):
  if .phase == 0
    then ingest_verb($l)
  elif .phase == 1
    then if $l != ""
      then ingest_header($l)
      else finish
    end
  end
;

def serve(lines; respond):
  foreach (lines | sub("\\r$"; "")) as $l (
    {phase: 0};
    ingest($l);
    if .phase == "done"
      then del(.phase) | (respond, halt)
      else empty
    end
  )
;
def serve(respond): serve(inputs; respond);

def response(code; reason; headers; body):
(
  "HTTP/2 \(code) \(reason)",
  (headers | to_entries[] | [.key, .value] | join(": ")),
  "",
  body
) | sub("$"; "\r")
;
def response(code; headers; body): response(code; ""; headers; body);

def html(code; reason; body): response(code; reason; {"content-type": "text/html"}; body);
def html(code; body): html(code; ""; body);

def notfound: html(404; "not found"; "<html><body>not found. <a href=\"/\">go home</a>.</body></html>");

def escapehtml:
  gsub("&"; "&amp;")
  | gsub(">"; "&gt;")
  | gsub("<"; "&lt;")
;

serve(
  if .path == "/" then html(200; "
      <html>
        <body>
          <h1>Hello, world!</h1>
          <p>This is jq speaking. Yes. Seriously.</p>
          <details>
            <summary>here is my own source code</summary>
            <pre style=\"margin-left:3em\"><code>\($self | escapehtml)</pre></code>
          </details>
          <p>Your user agent is \(.headers["user-agent"])</p>
          <p>If you want to know what time it is, go to the <a href=\"/time\">dedicated page</a>
        </body>
      </html>
    ")
  elif .path == "/time" then html(200; "
      <html>
        <body>
          <p>The current time is \(now | todate)</p>
        </body>
      </html>
    ")
  else notfound
  end
)
