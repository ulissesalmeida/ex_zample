# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.2] - 2020-10-13

### Fixed

- Fix accidental removal of manifests of files that has only with sequences defined

## [0.10.1] - 2020-10-06

### Fixed

- Fix compile time error message by [feliperenan](https://github.com/feliperenan)
- Fix a single sequence bringing down the whole sequences registry

## [0.10.0] - 2020-10-04

### Added

- `ExZample.insert/3`
- `ExZample.insert_pair/3`
- `ExZample.insert_list/4`
- `ExZample.DSL.def_sequence/2`

### Deprecated

- `ExZample.DSL.sequence/2`

## [0.9.0] - 2020-06-22

### Added

- `ExZample.params_for/3`
- `ExZample.params_list_for/2`
- `ExZample.params_pair_for/1`

## [0.8.0] - 2020-06-13

### Added

- `ExZample.map_for/3`
- `ExZample.map_list_for/2`
- `ExZample.map_pair_for/1`

## [0.7.0] - 2020-06-06

### Added

- Sequence DSL

## [0.6.1] - 2020-03-29

### Fixed

- Fixed DSL factories for umbrella apps by [@feliperenan](https://github.com/feliperenan)

## [0.6.0] - 2020-03-26

### Added

- `ExZample.DSL`

## [0.5.0] - 2020-03-20

### Added
- `ExZample.example/1` callback

## [0.4.0] - 2020-03-14

### Added
- `ExZample.config_aliases/1`
- `ExZample.config_aliases/2`
- `ExZample.create_sequence/1`
- `ExZample.create_sequence/2`
- `ExZample.create_sequence/3`
- `ExZample.sequence/1`
- `ExZample.sequence_list/2`
- `ExZample.sequence_pair/1`

### Deprecated
- `ExZample.add_aliases/1`
- `ExZample.add_aliases/2`

## [0.3.0] - 2020-03-05

### Added
- `ExZample.add_aliases/1`
- `ExZample.add_aliases/2`
- `ExZample.ex_zample/1`

## [0.2.0] - 2020-03-01

### Added
- `ExZample.build_list/3`
- `ExZample.build_pair/2`

## [0.1.0] - 2020-02-29
### Added
- `ExZample.build/1` and the core `Behaviour` that is from `example/0`
