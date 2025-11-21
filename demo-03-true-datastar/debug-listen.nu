#!/usr/bin/env nu
# Testing where vs filter patterns - Issue #16990

let timeout = 60sec
const API = "http://localhost:42992"

print "Choose test to run:"
print "1. BASELINE: filter with explicit param (known to work)"
print "2. ORIGINAL: each {$in} + where {$in} - single condition"
print "3. ORIGINAL: each {$in} + where {$in} + where {$in} - multiple where"
print "4. ORIGINAL: each {$in} + where {$in and} - compound condition"
print "5. ORIGINAL: each {$in} + where {$in} + each {$in} - where + each combo"
print "6. where with \$it row-condition"
print "7. NO \$in: all explicit params - where version"
print ""

let choice = (input "Enter choice (1-7): ")

match $choice {
    "1" => {
        print "\n=== TEST 1: filter with explicit param (BASELINE - should stream) ==="
        http get -m $timeout $"($API)/event"
        | lines
        | each {$in | from json}
        | filter {|x| $x.data.type == "message.part.updated"}
        | each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
    }

    "2" => {
        print "\n=== TEST 2: each {$in} + where {$in} - single condition ==="
        http get -m $timeout $"($API)/event"
        | lines
        | each {$in | from json}
        | where {$in.data.type == "message.part.updated"}
        | each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
    }

    "3" => {
        print "\n=== TEST 3: each {$in} + multiple where {$in} ==="
        http get -m $timeout $"($API)/event"
        | lines
        | each {$in | from json}
        | where {$in.data.type == "message.part.updated"}
        | where {$in.data.properties.part.type == "text"}
        | each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
    }

    "4" => {
        print "\n=== TEST 4: each {$in} + where {$in and} compound ==="
        http get -m $timeout $"($API)/event"
        | lines
        | each {$in | from json}
        | where {$in.data.type == "message.part.updated" and $in.data.properties.part.type == "text"}
        | each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
    }

    "5" => {
        print "\n=== TEST 5: each {$in} + where {$in} + each {$in} ==="
        http get -m $timeout $"($API)/event"
        | lines
        | each {$in | from json}
        | where {$in.data.type == "message.part.updated"}
        | each {$in.data?.properties?.delta?}
    }

    "6" => {
        print "\n=== TEST 6: where with \$it row-condition ==="
        http get -m $timeout $"($API)/event"
        | lines
        | where ($it | str starts-with "data:")
        | each {$in | from json}
        | where {|x| $x.data.type == "message.part.updated"}
        | each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
    }

    "7" => {
        print "\n=== TEST 7: NO \$in at all - all explicit params with where ==="
        http get -m $timeout $"($API)/event"
        | lines
        | each {|line| $line | from json}
        | where {|x| $x.data.type == "message.part.updated"}
        | each {|x| print $"✓ ($x.data?.properties?.delta?)"; $x}
    }

    _ => {
        print "Invalid choice"
    }
}


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
