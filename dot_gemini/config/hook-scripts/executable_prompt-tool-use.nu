#!/usr/bin/env -S nu --stdin
def main [] {
  let response = {
    decision: "force_ask"
  }
  $response | to json --raw
}
