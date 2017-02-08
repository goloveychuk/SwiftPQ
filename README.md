# SwiftPQ
Pure swift postgres client library

It implements frontend/backend postgres protocol ( https://www.postgresql.org/docs/current/static/protocol.html )

Early beginning, PRs are welcome.

For now for TCP sockets are used libmill's one. http://libmill.org/documentation.html

What is done:
https://github.com/goloveychuk/SwiftPQ/blob/master/Tests/PurePostgresTests/PurePostgresTests.swift

TODO:
- [ ] Supporting postgres structs, and deserializing it to swift structs. Maybe https://github.com/Zewo/Reflection needed.
- [ ] Test protocol implementation. I'm pretty sure there are cases, where it go to inconsistent state, and I don't catch it. Like reconnection, errors, exceptions and other.
- [ ] Implement and test for concurrency.
