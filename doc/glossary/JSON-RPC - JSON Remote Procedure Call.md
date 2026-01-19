# JSON-RPC - JSON Remote Procedure Call

**JSON-RPC** is a stateless, lightweight remote procedure call (RPC) protocol encoded in JSON. It defines a simple set of data structures and rules for processing them, allowing a client to invoke methods on a remote server and receive responses. JSON-RPC is transport-agnostic, meaning it can be used over HTTP, WebSockets, TCP, or any other communication protocol. The protocol supports both request-response patterns and notification messages that do not require a response.

## Protocol Design

JSON-RPC is designed to be simple and easy to implement. A request contains a method name, parameters, and an identifier, while a response includes the result or error information along with the matching identifier. The protocol's simplicity makes it ideal for microservices architectures, IoT devices, and scenarios where lightweight communication is essential. JSON-RPC 2.0, the current version, added support for batch requests and named parameters.

## External References

- [JSON-RPC Official Website](https://www.jsonrpc.org/) - The official JSON-RPC project homepage
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification) - Complete specification for JSON-RPC 2.0 protocol
- [Wikipedia: JSON-RPC](https://en.wikipedia.org/wiki/JSON-RPC) - Encyclopedia entry covering JSON-RPC protocol details
- [JSON-RPC Archive Specification](https://www.jsonrpc.org/archive_json-rpc.org/specification.html) - Historical specification documentation
