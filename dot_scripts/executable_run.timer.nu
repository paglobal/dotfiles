#!/usr/bin/env nu
def main [] {
    if not (is-terminal -o) { run.term.hold.float.sh $env.CURRENT_FILE }
    let timer_history_file = ("~/.local/state/scripts/timer-history.nuon" | path expand)
    mkdir ($timer_history_file | path dirname)
    if not ($timer_history_file | path exists) {
        [] | save $timer_history_file
    }
    let opt_new = "New timer"
    let opt_hist = "View history"
    let action = (gum choose $opt_new $opt_hist)
    if $action == $opt_hist {
        let days = (gum input --placeholder "How many days back?" | into int)
        let cutoff = ((date now) - ($days * 1day))
        open $timer_history_file | where initialization_time > $cutoff | select description duration_in_minutes completion_time | rename "Description" "Duration" "Day" | update Day {|r| $r.Day | format date "%A"} | table
    } else if $action == $opt_new {
        let target_mins = (gum input --placeholder "Duration in minutes" | into float)
        let initialization_time = (date now)
        mut elapsed_seconds = 0.0
        let total_seconds = $target_mins * 60.0
        loop {
            if $elapsed_seconds >= $total_seconds { break }
            let remaining = $total_seconds - $elapsed_seconds
            let remaining_minutes = ($remaining / 60.0 | math floor)
            let remaining_seconds = ($remaining mod 60)
            print -n $"\r(ansi --escape "2K")Time remaining: (printf '%02d:%02d' $remaining_minutes $remaining_seconds)"
            sleep 1sec
            $elapsed_seconds += 1
        }
        print -n $"\r(ansi --escape "2K")Time remaining: (printf '%02d:%02d' 0 0)"
        print ""
        let duration_in_minutes = (($elapsed_seconds / 60.0) | math round -p 2)
        let toast_payload = {
            title: "Timer finished!"
            type: "notice"
            body: $"Tracked ($duration_in_minutes) mins"
        } | to json --raw
        qs -c noctalia-shell ipc call toast send $toast_payload
        for i in 1..3 { ffplay -nodisp -autoexit /usr/share/sounds/freedesktop/stereo/complete.oga out> /dev/null err> /dev/null }
        let description = (gum write --placeholder "What happened?")
        let new_timer_history_entry = {
            description: $description
            duration_in_minutes: $duration_in_minutes
            initialization_time: $initialization_time
            completion_time: (date now)
        }
        open $timer_history_file | append $new_timer_history_entry | collect | save $timer_history_file --force
        print "Session logged successfully!"
    }
}
