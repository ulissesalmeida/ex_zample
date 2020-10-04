# Used by "mix format"
sequence_dsl_format = [def_sequence: 1, def_sequence: 2]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: sequence_dsl_format,
  export: [
    locals_without_parens: sequence_dsl_format
  ]
]
