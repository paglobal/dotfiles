#!/usr/bin/env nu
module z {
  export def int [] {
    { type: "int" }
  }

  export def float [] {
    { type: "float" }
  }

  export def string [] {
    { type: "string" }
  } 

  export def percent-string [] {
    { type: "percent-string" }
  }

  export def record [content: record] {
    { type: "record", content: $content }
  }

  export def array [content: record] {
    { type: "array", content: $content }
  }

  export def union [content: list] {
    { type: "union", content: $content }
  }

  export def enum [content: list] {
    { type: "enum", content: $content }
  }

  def "parse-percent-string" [percent_string: string] {
    if ($percent_string | str ends-with "%") {
      let number = ($percent_string | str replace "%" "" | into float)
      { number: $number, kind: "percentage" }
    } else {
      error make { msg: "Invalid percent string!" }
    }
  }

  export def parse [schema: record, data: any, path: string = ""] {
    let type = $schema.type
    if ($data == null) {
      return { value: null, errors: [] }
    }
    match $type {
      "int" => {
        if ($data | describe | str starts-with "int") {
          { value: { number: ($data | into int), kind: "integer" }, errors: [] }
        } else {
          { value: null, errors: [{ path: $path, msg: $"Expected int, got ($data | describe)!" }] }
        }
      }
      "float" => {
        if (($data | describe | str starts-with "float") or ($data | describe | str starts-with "int")) {
          { value: { number: ($data | into float), kind: "float" }, errors: [] }
        } else {
          { value: null, errors: [{ path: $path, msg: $"Expected float, got ($data | describe)!" }] }
        }
      }
      "string" => {
        if ($data | describe | str starts-with "string") {
          { value: $data, errors: [] }
        } else {
          { value: null, errors: [{ path: $path, msg: $"Expected string, got ($data | describe)!" }] }
        }
      }
      "percent-string" => {
        try {
          { value: (parse-percent-string $data), errors: [] }
        } catch {
          { value: null, errors: [{ path: $path, msg: $"Unable to parse percent-string: ($data)!" }] }
        }
      }
      "enum" => {
        if ($data in $schema.content) {
          { value: $data, errors: [] }
        } else {
          let expected = ($schema.content | str join ", ")
          { value: null, errors: [{ path: $path, msg: $"Expected one of: [($expected)], but got '($data)'!" }] }
        }
      }
      "record" => {
        if ($data | describe | str starts-with "record") {
          mut out_value = {}
          mut out_errors = []
          let unknown_keys = ($data | columns | where $it not-in ($schema.content | columns))
          for unknown_key in $unknown_keys {
            $out_errors = ($out_errors | append { path: (if $path == "" { $unknown_key } else { $"($path).($unknown_key)"}), msg: "Unknown key!"})
          }
          for field in ($schema.content | items { |key, value| { key: $key, schema: $value } }) {
            let sub_path = if ($path | is-empty) { $"($field.key)" } else { $"($path).($field.key)" }
            let result = (parse $field.schema ($data | get -o $field.key) $sub_path)
            $out_value = ($out_value| insert $field.key $result.value)
            $out_errors = ($out_errors | append $result.errors)
          }
          { value: $out_value, errors: ($out_errors | flatten) }
        } else {
          { value: null, errors: [{ path: $path, msg: $"Expected record, got ($data | describe)!" }] }
        }
      }
      "array" => {
        if ($data | describe | str starts-with "list") {
          mut out_value = []
          mut out_errors = []
          for it in ($data | enumerate) {
            let sub_path = if ($path | is-empty) { $"($it.index)" } else { $"($path).($it.index)" }
            let result = (parse $schema.content $it.item $sub_path)
            $out_value = ($out_value | append $result.value)
            $out_errors = ($out_errors | append $result.errors)
          }
          { value: $out_value, errors: ($out_errors | flatten) }
        } else {
          { value: null, errors: [{ path: $path, msg: $"Expected list, got ($data | describe)!" }] }
        }
      }
      "union" => {
        for option in $schema.content {
          let result = (parse $option $data $path)
          if ($result.errors | is-empty) {
            return $result
          }
        }
        let expected = ($schema.content | each { get type } | str join ", ")
        { value: null, errors: [{ path: $path, msg: $"Expected one of: [($expected)], but got '($data | describe)'!"}]}
      }
      _ => { { value: null, errors: [{path: $path, msg: $"Unknown schema type: ($type)!" }] } }
    }
  }
}

use z

def get-config-schema [] {
  let size = (z union [(z int) (z float) (z percent-string)])
  let window_action = (z enum ["ignore", "show_self", "show_all", "hide_self", "hide_all"])
  let sidebar_anchor = (z enum ["top_left", "bottom_left", "top_right", "bottom_right"])

  z record {
    sidebar: ((z record {
      gap: $size,
      anchor: $sidebar_anchor,
      peak: $size,
      margins: (z record {
        top: $size,
        left: $size,
        right: $size,
        bottom: $size
      })
    })),
    windows: (z array (z record {
      match: (z array (z record {
        app_id: (z string),
        title: (z string),
      })),
      exclude: (z array (z record {
        app_id: (z string),
        title: (z string)
      })),
      tiling: (z record {
        default_width: ($size),
        default_height: ($size),
      }),
      floating: (z record {
        default_width: ($size),
        default_height: ($size),
        on_focus: (z record {
          sidebar_hidden: ($window_action),
          sidebar_shown: ($window_action),
        }),
        on_blur: (z record {
          sidebar_hidden: ($window_action),
          sidebar_shown: ($window_action),
        }),
        on_sidebar_focus: ((z record {
          sidebar_hidden: ($window_action),
          sidebar_shown: ($window_action),
        })),
        on_sidebar_blur: (z record {
          sidebar_hidden: ($window_action),
          sidebar_shown: ($window_action),
        }),
      })
    }))
  }
}

def get-default-config [] {
  {
    sidebar: {
      gap: { number: 5, kind: "integer" },
      anchor: "bottom_right",
      peak: { number: 5, kind: "percentage" },
      margins: {
        top: { number: 5, kind: "integer" },
        left: { number: 5, kind: "integer" },
        right: { number: 5, kind: "integer" },
        bottom: { number: 5, kind: "integer" }
      }
    },
    windows: [
      {
        tiling: {
          default_width: { number: 33, kind: "percentage" },
          default_height: { number: 33, kind: "percentage" }
        },
        floating: {
          default_width: { number: 75, kind: "percentage" },
          default_height: { number: 100, kind: "percentage" }
        },
        on_focus: {
          self_hidden: "show_self",
          self_shown: "ignore",
          sidebar_hidden: "ignore",
          sidebar_shown: "ignore",
        },
        on_blur: {
          self_hidden: "ignore",
          self_shown: "hide_self",
          sidebar_hidden: "ignore",
          sidebar_shown: "ignore",
        },
        on_sidebar_focus: {
          self_hidden: "ignore",
          self_shown: "ignore",
          sidebar_hidden: "ignore",
          sidebar_shown: "ignore",
        },
        on_sidebar_blur: {
          self_hidden: "ignore",
          self_shown: "ignore",
          sidebar_hidden: "ignore",
          sidebar_shown: "ignore",
        },
      }
    ]
  }
}

# Recursively merge two values. If both are records, merge keys.
# If both are lists, merge elements by index if possible, otherwise use b.
def merge-deep [a: any, b: any] {
  let type_a = ($a | describe)
  let type_b = ($b | describe)
  if ($a == null) {
    return $b
  }
  if ($b == null) {
    return $a
  }
  if ($type_a | str starts-with "record") and ($type_b | str starts-with "record") {
    mut result = $a
    for key in ($b | columns) {
      let val_b = ($b | get $key)
      if ($key in ($a | columns)) {
        let val_a = ($a | get $key)
        $result = ($result | insert $key (merge-deep $val_a $val_b))
      } else {
        $result = ($result | insert $key $val_b)
      }
    }

    return $result
  }
  if (($type_a | str starts-with "list") or ($type_a | str starts-with "table")) and (($type_b | str starts-with "list") or ($type_b | str starts-with "table")) {
    if ($b | is-empty) {
      return $a
    }
    if ($a | length) > 0 {
      let template = ($a | first)

      return ($b | each { |item| merge-deep $template $item })
    }

    return $b
  }
  
  return $b
}

def load-config [path: string] {
  let defaults = (get-default-config)
  if not ($path | path exists) {
    return $defaults
  }
  try {
    let raw = (open $path)
    let schema = (get-config-schema)
    let parsed = (z parse $schema $raw)
    if not ($parsed.errors | is-empty) {
      let err_msg = ($parsed.errors | each { |e| $"($e.path): ($e.msg)" } | str join "; ")
      try { 
        ^notify-send "Nuri config validation failed" $err_msg
      } catch {}

      return $defaults
    }
    return (merge-deep $defaults $parsed.value)
  } catch { |err|
    try { ^notify-send "Nuri config parse error" $err.msg } catch {}
    return $defaults
  }
}

def resolve-size [size: record, output_dim: float] {
  match $size.kind {
    "percentage" => { ($size.number * $output_dim / 100.0) | math round }
    _ => { $size.number | math round }
  }
}

def match-window [window: record, rule: record] {
  if ($rule.exclude != null) {
    for entry in $rule.exclude {
      mut matched = true
      if ($entry.app_id != null and $window.app_id != $entry.app_id) {
        $matched = false
      }
      if ($entry.title != null and $window.title != $entry.title) {
        $matched = false
      }
      if $matched {
        return false
      }
    }
  }
  if ($rule.match != null) {
    mut match_found = false
    for entry in $rule.match {
      mut matched = true
      if ($entry.app_id != null and $window.app_id != $entry.app_id) {
        $matched = false
      }
      if ($entry.title != null and $window.title != $entry.title) {
        $matched = false
      }
      if $matched {
        $match_found = true
        break
      }
    }
    if not $match_found {
      return false
    }
  }

  return true
}

def get-window-config [window: record, config: record] {
  for rule in ($config.windows | default []) {
    if (match-window $window $rule) {
      return $rule
    }
  }
  {
    tiling: {
      default_width: { number: 26.0, kind: "percentage" },
      default_height: { number: 300, kind: "integer" }
    },
    floating: {
      default_width: { number: 20, kind: "integer" },
      default_height: { number: 50.0, kind: "percentage" },
      on_focus: {
        sidebar_hidden: "show_all",
        sidebar_shown: "show_self"
      },
      on_blur: {
        sidebar_hidden: "ignore",
        sidebar_shown: "ignore"
      },
      on_sidebar_focus: {
        sidebar_hidden: "ignore",
        sidebar_shown: "hide_self"
      },
      on_sidebar_blur: {
        sidebar_hidden: "show_all",
        sidebar_shown: "ignore"
      }
    }
  }
}

def get-niri-state [] {
  let outputs = (niri msg --json outputs | from json)
  let workspaces = (niri msg --json workspaces | from json)
  let windows = (niri msg --json windows | from json)
  { outputs: $outputs, workspaces: $workspaces, windows: $windows }
}

def apply-window-size [id: int, w: int, h: int] {
  niri msg action set-window-width --id $id $"($w)"
  niri msg action set-window-height --id $id $"($h)"
}


def run-niri-watcher [] {
  print "Initializing niri-watcher!"
}

def run-config-watcher [config_path: string] {
  print "Initializing config-watcher!"
}

def run-socket-server [socket_path: string] {
  print $"Initializing socket-server at ($socket_path)!"
}

def run-manager [config_path: string] {
  print "Initializing manager!"
}

def main [] {
}