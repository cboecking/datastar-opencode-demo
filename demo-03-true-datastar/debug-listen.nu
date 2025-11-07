#!/usr/bin/env nu
let timeout = 60sec
let output = "/tmp/output2.txt"
"starting..." | save --force $output

#http get -m $timeout http://localhost:3030/event | lines | where ($it | str starts-with "data:") | each {$in | from json } | where {|x| $x}
#http get -m $timeout http://localhost:3030/event
#http get -m $timeout http://localhost:3030/event | lines | each {$in | from json}
#http get -m $timeout http://localhost:3030/event | lines | each {$in | from json} | where {$in.data.type == "message.part.updated"}
#next line breaks the stream with the mutliple 'where'
#http get -m $timeout http://localhost:3030/event | lines | each {$in | from json} | where {$in.data.type == "message.part.updated"} | where {$in.data.properties.part.type == "text"}
#next line breaks the stream with the 'and'
#http get -m $timeout http://localhost:3030/event | lines | each {$in | from json} | where {$in.data.type == "message.part.updated" and $in.data.properties.part.type == "text"}
#next line breaks the stream - same reason
#http get -m $timeout http://localhost:3030/event | lines | each {$in | from json} | where {$in.data.type == "message.part.updated" and $in.data.properties.part.type == "text"} | each {$in.data?.properties?.delta?}

#next line breaks the stream - seems like the where + each also causes the delay
#http get -m $timeout http://localhost:3030/event | lines | each {$in | from json} | where {$in.data.type == "message.part.updated"} | each {$in.data?.properties?.delta?}

#this works
http get -m $timeout http://localhost:3030/event | lines | each {$in | from json} | filter {|x| $x.data.type == "message.part.updated"} | each {$in.data?.properties?.delta?}


#╭────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
#│ type       │ message.part.updated                                                                                                │
#│            │ ╭──────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────╮ │
#│ properties │ │      │ ╭────────────┬─────────────────────────────────────────────────────────────────────────────────────────╮ │ │
#│            │ │ part │ │ id         │ prt_a5c80ff65001ek2GWVu4miQG9W                                                          │ │ │
#│            │ │      │ │ sessionID  │ ses_5a37f062affevMg9WdO24mmj63                                                          │ │ │
#│            │ │      │ │ messageID  │ msg_a5c80fa00001NwJQbcPHluhd0H                                                          │ │ │
#│            │ │      │ │ type       │ text                                                                                    │ │ │
#│            │ │      │ │ text       │ A majestic whale swam through the ocean, singing songs of ancient seas, until it found  │ │ │
#│            │ │      │ │            │ its pod.                                                                                │ │ │
#│            │ │      │ │            │ ╭───────┬───────────────╮                                                               │ │ │
#│            │ │      │ │ time       │ │ start │ 1762488549358 │                                                               │ │ │
#│            │ │      │ │            │ │ end   │ 1762488549358 │                                                               │ │ │
#│            │ │      │ │            │ ╰───────┴───────────────╯                                                               │ │ │
#│            │ │      │ ╰────────────┴─────────────────────────────────────────────────────────────────────────────────────────╯ │ │
#│            │ ╰──────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────╯ │
#╰────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
