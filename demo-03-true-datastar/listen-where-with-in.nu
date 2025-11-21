#!/usr/bin/env nu
# TEST: where with $in (KNOWN TO BUFFER)
# Based on issue #16990

let timeout = 60sec
const OPENCODE_API = "http://localhost:42992"

print "Testing: where with $in - EXPECTED TO BUFFER"
print "Watch for delayed output...\n"

http get -m $timeout $"($OPENCODE_API)/event"
| lines
| each {$in | from json}
| where {$in.data.type == "message.part.updated"}
| each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
