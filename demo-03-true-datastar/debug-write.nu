#!/usr/bin/env nu
const OPENCODE_API = "http://localhost:42992"

http post $"($OPENCODE_API)/session" ""
| get id
| $"($OPENCODE_API)/session/($in)/message"
| http post $in ({parts: [{type: "text", text: "create a whale story in about 8 to 15 words"}]} | to json) -H [Content-Type application/json]
