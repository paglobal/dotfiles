#!/usr/bin/env -S nu --stdin
def normalize [text: string] {
    $text | str trim --right
}

def apply-chunk [lines: list<string>, chunk: record] {
    let start = $chunk.StartLine
    let end = $chunk.EndLine
    if ($start | describe) != "int" or ($end | describe) != "int" {
        error make
    }
    let before = ($lines | take ($start - 1))
    let target_block = (
        $lines
        | skip ($start - 1)
        | take ($end - $start + 1)
        | str join "\n"
    )
    let after = ($lines | skip $end)
    let replace_all = ($chunk.AllowMultiple? | default false)
    let new_block = if $replace_all {
        $target_block
        | str replace --all $chunk.TargetContent $chunk.ReplacementContent
    } else {
        $target_block
        | str replace $chunk.TargetContent $chunk.ReplacementContent
    }
    (
        $before
        | append ($new_block | split row "\n")
        | append $after
    )
}

def allow [reason: string] {
    print ({ decision: "allow", reason: $reason } | to json)
}

def deny [reason: string] {
    print ({ decision: "deny", reason: $reason } | to json)
}

def ask [] {
    print ({ decision: "ask" } | to json)
}

def force-ask [] {
    print ({ decision: "force_ask" } | to json)
}

def get-session-dir [conversation_id: string] {
    [$nu.temp-dir "vscode-teleprompt" $conversation_id] | path join
}

def execute-pre [] {
    let payload = $in | from json
    let tool = $payload.toolCall.name
    let args = $payload.toolCall.args?
    let conversation_id = $payload.conversationId
    # Only write tools (as of the time of writing this) have the `TargetFile` arg
    let target = $args.TargetFile?
    if ($target | is-empty) {
        if $tool == "run_command" or $tool == "manage_task" {
            force-ask
        } else {
            ask
        }

        return
    }
    let abs_target = ($target | path expand)
    let session_dir = (get-session-dir $conversation_id)
    let extension = ($target | path parse | get extension)
    let diff_file = ($session_dir | path join (if ($extension | is-empty) { "preview" } else { $"preview.($extension)" }))
    let mod_file = ($session_dir | path join "userModification.json")
    let feedback_file = ($session_dir | path join "feedback.md")
    # Clean stale files from previous runs
    mkdir $session_dir
    rm -f $mod_file
    rm -f $feedback_file
    let is_new_file = not ($abs_target | path exists)
    let orig_text = if $is_new_file { "" } else { open --raw $abs_target }
    let orig_lines = $orig_text | split row "\n"
    let new_text = if $tool == "write_to_file" {
        $args.CodeContent
    } else if $tool == "replace_file_content" or $tool == "multi_replace_file_content" {
        let chunks = if $tool == "replace_file_content" {
            [$args]
        } else {
            $args.ReplacementChunks
        }
        (
            $chunks
            | sort-by -r StartLine
            | reduce -f $orig_lines {|chunk, acc|
                apply-chunk $acc $chunk
            }
            | str join "\n"
        )
    } else {
        ask
        return
    }
    # Set up directories and write files for diff view
    mkdir ($abs_target | path dirname)
    $orig_text | save -f $diff_file
    $new_text | save -f $abs_target
    # Open in editor for review
    if $is_new_file {
        ^code --wait --reuse-window $abs_target
    } else {
        ^code --wait --reuse-window --diff $diff_file $abs_target
    }
    # Check for user modifications
    let content_after_review = open --raw $abs_target
    let user_modified = (normalize $new_text) != (normalize $content_after_review)
    # Restore original file state
    if $is_new_file {
        rm -f $abs_target
    } else {
        $orig_text | save -f $abs_target
    }
    # Save user modifications if any
    if $user_modified {
        { filePath: $abs_target, replaceContent: $content_after_review }
        | to json
        | save -f $mod_file
    }
    # Open feedback file for user input
    "" | save -f $feedback_file
    ^code --wait --reuse-window $feedback_file
    let feedback = (open --raw $feedback_file | str trim)
    rm -f $feedback_file
    rm -f $diff_file
    if ($feedback | is-not-empty) {
        # Deny with user feedback
        let mod_note = if $user_modified {
            "The user also modified your edits. Check the file for the new state."
        } else {
            "The user discarded your edits completely."
        }
        deny $"User says: ($feedback)\n\nNote: ($mod_note)"
    } else {
        # Accept
        if $user_modified {
            allow "Your edits have been accepted with modifications. Check the file for the new state and proceed accordingly."
        } else {
            allow "Your edits have been accepted without modification. Proceed."
        }
    }
}

def execute-post [] {
    let payload = $in | from json
    let conversation_id = $payload.conversationId
    let session_dir = (get-session-dir $conversation_id)
    let mod_file = ($session_dir | path join "userModification.json")
    if ($mod_file | path exists) {
        let mod = (open $mod_file)
        $mod.replaceContent | save -f $mod.filePath
        rm -f $mod_file
    }
    print "{}"
}

def main [event: string] {
    try {
        if $event == "pre" {
            $in | execute-pre
        } else if $event == "post" {
            $in | execute-post
        }
    } catch {|err|
        notify-send $err 
        force-ask
    }
}