#!/usr/bin/env nu
# TEST: where with $it row-condition syntax
# Testing fdncred's suggestion

let timeout = 60sec
const OPENCODE_API = "http://localhost:42992"

print "Testing: where with \$it row-condition"
print "Watch if this streams in real-time...\n"

http get -m $timeout $"($OPENCODE_API)/event"
| lines
| each {|line| $line | from json}
| where ($it.data.type == "message.part.updated")
| each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
