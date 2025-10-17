; vim: set sw=2 ts=2 et:

;; JS in the `script` field of a `actions/github-script` step:
(block_mapping
  (block_mapping_pair
    key: (flow_node (plain_scalar (string_scalar)) @_uses_key)
    (#eq? @_uses_key "uses")
    value: (flow_node (plain_scalar (string_scalar)) @_uses_value)
    (#match? @_uses_value "^actions/github-script[@]")
  )
  (block_mapping_pair
    key: (flow_node (plain_scalar (string_scalar)) @_with_key)
    (#eq? @_with_key "with")
    value: (block_node (block_mapping
      (block_mapping_pair
        key: (flow_node (plain_scalar (string_scalar)) @_script_key)
        (#eq? @_script_key "script")
        value: (block_node (block_scalar) @injection.content)
        (#set! injection.language "javascript")
        ; don't treat YAML block modifier as JS:
        (#offset! @injection.content 0 1 0 0)
        ; overwrite GitLabCI bash script query w/ 100 prio
        (#set! priority 101)
      )
    ))
  )
)

