#!/usr/bin/env nu
# TEST: where with explicit parameter {|x| $x.field}
# Testing fdncred's suggestion to avoid $in

let timeout = 60sec
const OPENCODE_API = "http://localhost:42992"

print "Testing: where with explicit parameter - fdncred's suggestion"
print "Watch if this streams in real-time...\n"

http get -m $timeout $"($OPENCODE_API)/event"
| lines
| each {|line| $line | from json}
| where {|x| $x.data.type == "message.part.updated"}
| each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
