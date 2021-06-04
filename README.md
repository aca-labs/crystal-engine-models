# PlaceOS Models

[![CI](https://github.com/PlaceOS/models/actions/workflows/ci.yml/badge.svg)](https://github.com/PlaceOS/models/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/Docs-available-green.svg)](https://placeos.github.io/models)

The database models for PlaceOS in [crystal](https://crystal-lang.org/).

PlaceOS is a distributed application, with many concurrent event sources that require persistence.
We use [RethinkDB](https://rethinkdb.com) to unify our database and event bus, giving us a consistent interface to state and events across the system.

## Testing

`crystal spec` to run tests
