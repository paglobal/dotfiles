#!/usr/bin/env -S nu --stdin
def normalize [text: string] {
    $text | str trim --right
}

def apply-chunk [lines: list<string>, chunk: record] {
    let start = ($chunk.StartLine | into int)
    let end = ($chunk.EndLine | into int)
    let before = ($lines | take ($start - 1))
    let target_block = (
        $lines
        | skip ($start - 1)
        | take ($end - $start + 1)
        | str join "\n"
    )
    let after = ($lines | skip $end)
    let replace_all = ($chunk | get AllowMultiple? | default false)
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

def build-preview-path [parsed] {
    let preview_name = if ($parsed.extension | is-empty) {
        $"($parsed.stem).preview"
    } else {
        $"($parsed.stem).preview.($parsed.extension)"
    }
    $parsed.parent | path join $preview_name
}

def deny [reason: string] {
    print ({ decision: "deny", reason: $reason } | to json)
}

def allow [] {
    print ({ decision: "allow" } | to json)
}

def ask [] {
    print ({ decision: "ask" } | to json)
}

def force-ask [] {
    print ({ decision: "force_ask" } | to json)
}

def is-list [val] {
    ($val | describe | str starts-with "list")
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
       } else if $tool == "read_url_content" {
           allow
       } else {
           ask
       }

       return
    }
    let parsed: record = ($target | path parse)
    let preview_file = (build-preview-path $parsed )
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
    mkdir $parsed.parent
    $new_text | save -f $preview_file
    let content_before = open --raw $preview_file
    if $is_new_file {
        ^zeditor --wait --existing --add $preview_file
    } else {
        ^zeditor --wait --existing --add --diff $target $preview_file
    }
    let content_after = open --raw $preview_file
    let before_normalized = normalize $content_before
    let after_normalized = normalize $content_after
    if $before_normalized == $after_normalized {
        allow
    } else {
        $content_after | save -f $target
        deny "Your edits have been modified. Read file to see new state and how to move on. Pay attention to comments with prefix `agent:`"
    }
    rm -f $preview_file
}

def handle-fail [err] {
    force-ask
}

def main [] {
    try {
        $in | execute
    } catch {|err|
        handle-fail $err
    }
}
