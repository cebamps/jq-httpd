#!/usr/bin/env -S jq -Rrnf --rawfile self httpd.jq

def next_phase: .phase |= {
  "verb": "header",
  "header": "done"
}[.];

def ingest_verb($l):
  next_phase + (
    $l
    | split(" ")
    | {verb: .[0], path: .[1], version: .[2]}
  )
;

def ingest_header($l):
  if $l == ""
    then next_phase
    else .headers += (
      $l
      | split(": ")
      | {(.[0] | ascii_downcase): .[1]}
    )
  end
;

def serve(lines; respond):
  foreach (lines | sub("\\r$"; "")) as $l (
    {phase: "verb"};
    if   .phase == "verb"   then ingest_verb($l)
    elif .phase == "header" then ingest_header($l)
    end;
    select(.phase == "done") | del(.phase) | (respond, halt)
  )
;

def response(code; reason; headers; body):
  "HTTP/2 \(code) \(reason)",
  (headers | to_entries[] | [.key, .value] | join(": ")),
  "",
  body
  | sub("$"; "\r")
;

def html(code; reason; body): response(code; reason; {"content-type": "text/html"}; body);
def html(code; body): html(code; ""; body);

def notfound: html(404; "not found"; "<html><body>not found. <a href=\"/\">go home</a>.</body></html>");

def escapehtml:
  gsub("&"; "&amp;")
  | gsub(">"; "&gt;")
  | gsub("<"; "&lt;")
;

serve(inputs;
  if .path == "/" then html(200; "
      <html>
        <body>
          <h1>Hello, world!</h1>
          <p>This is jq speaking. Yes. Seriously.</p>
          <details>
            <summary>here is my own source code</summary>
            <pre><code>\($self | escapehtml)</pre></code>
          </details>
          <p>Your user agent is \(.headers["user-agent"])</p>
          <details>
            <summary>full parsed request</summary>
            <pre><code id=\"req\">\(tojson)</pre></code>
            <script>(/*the irony*/ (e)=>e.innerText=JSON.stringify(JSON.parse(e.innerText),null,2))(document.getElementById(\"req\"))</script>
          </details>
          <p>If you want to know what time it is, go to the <a href=\"/time\">dedicated page</a>

          <style>pre{margin-left: 3em;}</style>
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
