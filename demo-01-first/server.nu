# server.nu - Serve Datastar + OpenCode demo
#
# Run with: cat server.nu | http-nu :8080 -

{|req|
  match $req.path {
    "/" | "/index.html" => {
      .response { headers: { "Content-Type": "text/html" } }
      open index.html
    }

    # 404 for everything else
    _ => {
      .response { status: 404 }
      "404 - Not found"
    }
  }
}
