#!/usr/bin/env nu
# BASELINE: filter with explicit parameter (KNOWN TO WORK)

let timeout = 60sec
const OPENCODE_API = "http://localhost:42992"

print "Testing: filter with explicit parameter - BASELINE (should stream)"
print "This is the working version for comparison\n"

http get -m $timeout $"($OPENCODE_API)/event"
| lines
| each {|line| $line | from json}
| filter {|x| $x.data.type == "message.part.updated"}
| each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
