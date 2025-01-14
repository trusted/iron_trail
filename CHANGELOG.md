# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.5 - 2025-01-06

### Fixed

- `#travel_to` now returns nil when no versions are found in the specified timestamp.

## 0.0.4 - 2024-12-30

### Added

- Improved developer experience, added CONTRIBUTING.md docs
- Publish gem using a github workflow

### Fixed

- `ActiveRecord::Reflection#reflect_on_all_associations` would not work for models having IronTrail enabled

## 0.0.3 - 2024-12-26

### Added

- Now able to travel back in time with `model.iron_trails.travel_to(some_timestamp)`
- Add ability to "reify" a trail, that is, to restore the object to what it was in a given trail
- Added helper methods to `IronTrail::ChangeModelConcern`: `insert_operation?`, `update_operation?`, `delete_operation?`
- Added helpers to filter/scope trails: `model.iron_trails.inserts` (also '.deletes' and `.updates`)
- Full STI (Single Table Inheritance) support now added with proper tests

## 0.0.2 - 2024-12-09

### Added

- Added means to disable tracking ignored tables
- Allow enabling/disabling IronTrail in rspec

## 0.0.1 - 2024-11-26

Initial release.
