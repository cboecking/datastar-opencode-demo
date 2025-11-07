#!/usr/bin/env nu
http post http://localhost:3030/session ""
| get id
| $"http://localhost:3030/session/($in)/message"
| http post $in ({parts: [{type: "text", text: "create a whale story in about 8 to 15 words"}]} | to json) -H [Content-Type application/json]
