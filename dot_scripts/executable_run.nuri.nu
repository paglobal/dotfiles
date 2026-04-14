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

  export def default [value: any] {
    let schema = $in
    $schema | merge { default: $value }
  }

  export def optional [] {
    let schema = $in
    $schema | merge { optional: true }
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
      if ("default" in $schema) {
        return { value: $schema.default, errors: [] }
      } else if ($schema.optional? == true) {
        return { value: null, errors: [] }
      } else {
        return { value: null, errors: [{ path: $path, msg: "Missing required field!"}]}
      }
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
  let size = (z union [(z float) (z percent-string)])
  let window_action = (z enum ["ignore", "show-self", "show-all", "hide-self", "hide-all"])
  let sidebar_anchor = (z enum ["top-left", "bottom-left", "top-right", "bottom-right"])
  let default_floating_window_dimension = (z default { number: 1, kind: "percentage"})
  let default_tiling_window_dimension = (z default { number: 0.33, kind: "percentage"})
  let default_spacing = (z default { number: 3, kind: "integer"})

  z record {
    sidebar: (z record {
      gap: $size,
      anchor: $sidebar_anchor
      peak: $size,
      margins: (z record {
        top: $size,
        left: $size,
        right: $size,
        bottom: $size
      })
    }),
    windows: (z array (z record {
      match: ((z array (z record {
        app-id: (z string | z optional),
        title: (z string | z optional)
      })) | z optional),
      exclude: ((z array (z record {
        app-id: (z string | z optional),
        title: (z string | z optional)
      })) | z optional),
      tiling: (z record {
        default-width: ($size | z default 5) ,
        default-height: $size,
      }),
      floating: (z record {
        position: (z enum ["start", "end", "auto"]),
        default-width: $size,
        default-height: $size,
        on-focus: (z record {
          sidebar-hidden: $window_action,
          sidebar-shown: $window_action,
        }),
        on-blur: (z record {
          sidebar-hidden: $window_action,
          sidebar-shown: $window_action,
        }),
        on-sidebar-focus: (z record {
          sidebar-hidden: $window_action,
          sidebar-shown: $window_action,
        }),
        on-sidebar-blur: (z record {
          sidebar-hidden: $window_action,
          sidebar-shown: $window_action,
        }),

      })
    }))

  }
}

def main [] {
    job spawn { run-niri-watcher } -t "niri-watcher"
    job spawn { run-socket-server } -t "socket-server"
    job spawn { run-config-watcher } -t "config-watcher"
    run-manager
}

def run-niri-watcher [] {
    print "Initializing niri-watcher!"
    niri msg --json event-stream | lines | each { |line|
        print $"Here's the ($line)"
    }
}

def run-socket-server [] { print "Initializing socket-server!" }

def run-config-watcher [] {
    print "Initializing config-watcher!"
    let config_folder_path = ("~/.config/scripts" | path expand)
    let config_file_path = ("~/.config/scripts/nuri.toml" | path expand)
    watch $config_folder_path { |op, path| 
        if $path == $config_file_path {
            print $"A/an ($op) was performed" 
        }
    }
}

def run-manager [] {
    print "Initializing manager!"
    loop { sleep 1sec }
}
