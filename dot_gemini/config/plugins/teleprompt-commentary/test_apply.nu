#!/usr/bin/env nu

def apply-chunk [lines: list<string>, chunk: record] {
    if $chunk.TargetContent == $chunk.ReplacementContent {
        return $lines
    }
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
        | each { |line| $line + "\n" }
        | str join ""
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
    let trimmed_block = if ($new_block | str ends-with "\n") {
        $new_block | str replace --regex "\n$" ""
    } else {
        $new_block
    }
    let new_lines = if ($trimmed_block | is-empty) {
        []
    } else {
        $trimmed_block | split row "\n"
    }
    (
        $before
        | append $new_lines
        | append $after
    )
}

def run-test [test: record] {
    let orig_lines = $test.input | split row "\n"
    let result_lines = apply-chunk $orig_lines $test.chunk
    let result_text = $result_lines | str join "\n"
    if $result_text == $test.expected {
        print $"[OK] ($test.name)"
    } else {
        print $"[FAIL] ($test.name)"
        print $"  Expected: ($test.expected | inspect)"
        print $"  Got:      ($result_text | inspect)"
        error make { msg: $"Test ($test.name) failed" }
    }
}

def main [] {
    let tests = get-tests
    for t in $tests {
        run-test $t
    }
    print $"\nSuccessfully ran ($tests | length) tests!"
    print "All tests passed successfully!"
}

# Test Data
def get-tests [] {
    [
        # Test 1: test.md comments deletion
        {
            name: "test.md comments deletion"
            input: "# Hey\n\nThis is hey.md.\n\nPrince Aliiiii!\n\n<!-- user: Append Prince Ali song lyrics -->\n<!-- Explain lyrics addition -->\nFabulous he, Ali Ababwa!\n\n<!--agent: next lyrics please-->\n\n<!-- user: Append next lyrics -->\n<!-- Explain more lyrics addition -->\nGenie of the lamp! Prince Ali! Mighty is he, Ali Ababwa!\n\n<!--agent: good! next please-->\n\n<!-- user: Append next lyrics -->\n<!-- Explain more lyrics addition -->\nStrong as ten regular men, definitely!\n\n\n<!--agent: nice! more please-->\n\n<!-- user: Append next lyrics -->\n<!-- Explain more lyrics addition -->\nHe faced the galloping hordes!\n\n<!--agent: continue-->\n\n<!-- user: Complete the lyrics line -->\n<!-- Explain completion logic -->\nA hundred bad guys with swords!\n\nWho sent those goons to their lords?\n"
            chunk: {
                StartLine: 30
                EndLine: 33
                TargetContent: "<!--agent: continue-->\n\n<!-- user: Complete the lyrics line -->\n<!-- Explain completion logic -->"
                ReplacementContent: ""
            }
            expected: "# Hey\n\nThis is hey.md.\n\nPrince Aliiiii!\n\n<!-- user: Append Prince Ali song lyrics -->\n<!-- Explain lyrics addition -->\nFabulous he, Ali Ababwa!\n\n<!--agent: next lyrics please-->\n\n<!-- user: Append next lyrics -->\n<!-- Explain more lyrics addition -->\nGenie of the lamp! Prince Ali! Mighty is he, Ali Ababwa!\n\n<!--agent: good! next please-->\n\n<!-- user: Append next lyrics -->\n<!-- Explain more lyrics addition -->\nStrong as ten regular men, definitely!\n\n\n<!--agent: nice! more please-->\n\n<!-- user: Append next lyrics -->\n<!-- Explain more lyrics addition -->\nHe faced the galloping hordes!\n\nA hundred bad guys with swords!\n\nWho sent those goons to their lords?\n"
        }
        # Test 2: Single line replacement with single line content
        {
            name: "Single line replacement with single line content"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "line2", ReplacementContent: "hello" }
            expected: "line1\nhello\nline3\n"
        }
        # Test 3: Single line replacement with empty string (deletion)
        {
            name: "Single line replacement with empty string"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "line2", ReplacementContent: "" }
            expected: "line1\nline3\n"
        }
        # Test 4: Multi line replacement with empty string
        {
            name: "Multi line replacement with empty string"
            input: "line1\nline2\nline3\nline4\n"
            chunk: { StartLine: 2, EndLine: 3, TargetContent: "line2\nline3", ReplacementContent: "" }
            expected: "line1\nline4\n"
        }
        # Test 5: Replacement with multi-line content
        {
            name: "Replacement with multi-line content"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "line2", ReplacementContent: "hello\nworld" }
            expected: "line1\nhello\nworld\nline3\n"
        }
        # Test 6: Replacement with trailing newline in replacement
        {
            name: "Replacement with trailing newline in replacement"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "line2", ReplacementContent: "hello\n" }
            expected: "line1\nhello\n\nline3\n"
        }
        # Test 7: Replace first line of file
        {
            name: "Replace first line of file"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 1, EndLine: 1, TargetContent: "line1", ReplacementContent: "first" }
            expected: "first\nline2\nline3\n"
        }
        # Test 8: Delete first line of file
        {
            name: "Delete first line of file"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 1, EndLine: 1, TargetContent: "line1", ReplacementContent: "" }
            expected: "line2\nline3\n"
        }
        # Test 9: Replace last line of file (no trailing newline in file)
        {
            name: "Replace last line of file (no trailing newline)"
            input: "line1\nline2\nline3"
            chunk: { StartLine: 3, EndLine: 3, TargetContent: "line3", ReplacementContent: "last" }
            expected: "line1\nline2\nlast"
        }
        # Test 10: Replace last line of file (with trailing newline in file)
        {
            name: "Replace last line of file (with trailing newline)"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 3, EndLine: 3, TargetContent: "line3", ReplacementContent: "last" }
            expected: "line1\nline2\nlast\n"
        }
        # Test 11: Delete last line of file (with trailing newline in file)
        {
            name: "Delete last line of file (with trailing newline)"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 3, EndLine: 3, TargetContent: "line3", ReplacementContent: "" }
            expected: "line1\nline2\n"
        }
        # Test 12: Delete last line of file (no trailing newline in file)
        {
            name: "Delete last line of file (no trailing newline)"
            input: "line1\nline2\nline3"
            chunk: { StartLine: 3, EndLine: 3, TargetContent: "line3", ReplacementContent: "" }
            expected: "line1\nline2"
        }
        # Test 13: Replace content containing special characters
        {
            name: "Replace content containing special characters"
            input: "line1\n$foo = 42;\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "$foo = 42;", ReplacementContent: "$bar = 'hello';" }
            expected: "line1\n$bar = 'hello';\nline3\n"
        }
        # Test 14: Replacement content is multiple empty lines
        {
            name: "Replacement content is multiple empty lines"
            input: "line1\nline2\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "line2", ReplacementContent: "\n\n" }
            expected: "line1\n\n\n\nline3\n"
        }
        # Test 15: TargetContent matches part of a line
        {
            name: "TargetContent matches part of a line"
            input: "line1\nhello world\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "world", ReplacementContent: "everyone" }
            expected: "line1\nhello everyone\nline3\n"
        }
        # Test 16: Replace empty line with content
        {
            name: "Replace empty line with content"
            input: "line1\n\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "", ReplacementContent: "inserted" }
            expected: "line1\ninserted\nline3\n"
        }
        # Test 17: Replace empty line with another empty line (no change)
        {
            name: "Replace empty line with another empty line"
            input: "line1\n\nline3\n"
            chunk: { StartLine: 2, EndLine: 2, TargetContent: "", ReplacementContent: "" }
            expected: "line1\n\nline3\n"
        }
        # Test 18: AllowMultiple is true (replace all occurrences)
        {
            name: "AllowMultiple is true"
            input: "hello\nhello\nworld\n"
            chunk: { StartLine: 1, EndLine: 2, TargetContent: "hello", ReplacementContent: "hi", AllowMultiple: true }
            expected: "hi\nhi\nworld\n"
        }
        # Test 19: AllowMultiple is false (replace only first occurrence)
        {
            name: "AllowMultiple is false"
            input: "hello\nhello\nworld\n"
            chunk: { StartLine: 1, EndLine: 2, TargetContent: "hello", ReplacementContent: "hi", AllowMultiple: false }
            expected: "hi\nhello\nworld\n"
        }
        # Test 20: Empty file input, insert content
        {
            name: "Empty file input, insert content"
            input: ""
            chunk: { StartLine: 1, EndLine: 1, TargetContent: "", ReplacementContent: "first line" }
            expected: "first line"
        }
        # Test 21: Replace single character
        {
            name: "Replace single character"
            input: "a\n"
            chunk: { StartLine: 1, EndLine: 1, TargetContent: "a", ReplacementContent: "b" }
            expected: "b\n"
        }
        # Test 22: Multi-line target content with different trailing spaces
        {
            name: "Multi-line target content with different trailing spaces"
            input: "line1  \nline2 \nline3\n"
            chunk: { StartLine: 1, EndLine: 2, TargetContent: "line1  \nline2 ", ReplacementContent: "replaced" }
            expected: "replaced\nline3\n"
        }
        # Test 23: Deletion of final agent comment at the end of the file
        {
            name: "Deletion of final agent comment at the end of the file"
            input: "Let us step into the future not\nwith anxiety about obsolescence, but with a commitment to reflect the glory of\nour Creator through the premium of Christian character.\n\n<!--agent: great! let's move back to chat. I'll hit you up once I'm ready to start making edits-->\n"
            chunk: {
                StartLine: 3
                EndLine: 5
                TargetContent: "\n\n<!--agent: great! let's move back to chat. I'll hit you up once I'm ready to start making edits-->\n"
                ReplacementContent: "\n"
            }
            expected: "Let us step into the future not\nwith anxiety about obsolescence, but with a commitment to reflect the glory of\nour Creator through the premium of Christian character.\n"
        }
    ]
}
