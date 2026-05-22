#!/usr/bin/env -S nu --stdin
def main [] {
  let response = {
    decision: "ask"
  }
  $response | to json --raw
}
