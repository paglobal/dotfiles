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

def deny [reason: string] {
    print ({ decision: "deny", reason: $reason } | to json)
}

def ask [] {
    print ({ decision: "ask" } | to json)
}

def force-ask [] {
    print ({ decision: "force_ask" } | to json)
}

def execute [] {
    let payload = $in | from json
    let tool = $payload.toolCall.name
    # Just in case a tool comes along with no args
    let args = $payload.toolCall.args?
    # Only write tools (as of the time of writing this) have the `TargetFile`arg
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
    let tmp_file = $"/tmp($abs_target)"
    let is_new_file = not ($target | path exists)
    let orig_text = if $is_new_file { "" } else { open --raw $target }
    let orig_lines = $orig_text | split row "\n"
    let new_text = if $tool == "write_to_file" {
        $args.CodeContent
    } else if $tool == "replace_file_content" or $tool == "multi_replace_file_content" {
        # Only `multi_replace_file_content` supports `ReplacementChunks`
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
    # Create parent directories if they don't exist
    mkdir ($target | path dirname)
    mkdir ($tmp_file | path dirname)
    $orig_text | save -f $tmp_file
    $new_text | save -f $target
    let content_before = $new_text
    if $is_new_file {
        ^zeditor --wait --existing --add $target
    } else {
        ^zeditor --wait --existing --add --diff $tmp_file $target
    }
    let content_after = open --raw $target
    let before_normalized = normalize $content_before
    let after_normalized = normalize $content_after
    if $before_normalized == $after_normalized {
        deny "Your edits have been applied as is. Great job!"
    } else {
        deny "Your edits have been modified. Read file to see new state and how to proceed."
    }
    rm -f $tmp_file
}

def main [] {
    try {
        $in | execute
    } catch {
        force-ask
    }
}
