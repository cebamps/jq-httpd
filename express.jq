#!/usr/bin/env -S jq -Rrn --rawfile self express.jq -f

def ingest_request($l):
  (.phase = "header") + (
    $l
    | split(" ")
    | {method: .[0], path: .[1], version: .[2]}
  )
;

def ingest_header($l):
  if $l == ""
    # note that we don't parse request bodies after the header. though we
    # could! we would have to count bytes to match the content-length header
    then .phase = "done"
    else .headers += (
      $l
      | split(": ")
      | {(.[0] | ascii_downcase): .[1]}
    )
  end
;

def serve(lines; respond):
  foreach (lines | sub("\\r$"; "")) as $l (
    {phase: "request"};
    if   .phase == "request" then ingest_request($l)
    elif .phase == "header"  then ingest_header($l)
    end;
    select(.phase == "done") | del(.phase) | (respond, halt)
  )
;

def response(code; reason; headers; body):
  "HTTP/1.1 \(code) \(reason)",
  (headers | to_entries[] | [.key, .value] | join(": ")),
  "",
  body
  | . + "\r"
;

def html(code; reason; body): response(code; reason; {"content-type": "text/html"}; body);
def html(code; body): html(code; ""; body);

def notfound: html(404; "not found"; "
  <html>
  <head><title>Express.jq - 404</title></head>
  <body>not found. <a href=\"/\">go home</a>.</body>
  </html>
");

def escapehtml:
  gsub("&"; "&amp;")
  | gsub(">"; "&gt;")
  | gsub("<"; "&lt;")
;

serve(inputs;
  if .path == "/" then html(200; "
      <html>
        <head><title>Express.jq - homepage</title></head>
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
        <head><title>Express.jq - time</title></head>
        <body>
          <p>The current time is \(now | todate)</p>
        </body>
      </html>
    ")
  else notfound
  end
)
