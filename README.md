# PlaceOS Models

![CI](https://github.com/PlaceOS/models/workflows/CI/badge.svg)

The database models for PlaceOS in [crystal](https://crystal-lang.org/).

PlaceOS is a distributed application, with many concurrent event sources that require persistence.
We use [RethinkDB](https://rethinkdb.com) to unify our database and event bus, giving us a consistent interface to state and events across the system.

## Testing

`crystal spec` to run tests
