#!/usr/bin/env -S nu --stdin
def main [] { 
  let instructions_path = ("~/.gemini/GEMINI.md" | path expand)
  let instructions = if ($instructions_path | path exists) { 
    open $instructions_path --raw
  } else {
    # Print to stderr and return empty string if no instructions are found 
    print --stderr $"Warning, ($instructions_path) not found!"
    exit 2
  }
  let response = {
    hookSpecificOutput: {
      additionalContext: $"**Please don't forget!**\n\n($instructions)"
    }
  }
  $response | to json --raw 
}
