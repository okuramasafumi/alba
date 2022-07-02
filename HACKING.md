# Hacking document

This document is intended to provide detailed information about the internal design and implementation of Alba. You are recommended to read through it if you want to hack Alba.

## Design

The design of Alba is simple. `Alba::Resource` module is the only interface end users use by `include`ing it. Other classes and modules are referenced by `Alba::Resource`.

`included` hook 

## Methods

The main methods users directly use are listed below.

Class methods (DSL):

* `attribute` for block style attribute
* `attributes` for symbol style attribute
* `association` and its aliases such as `one` for association

Instance methods:

* `serializable_hash` and `to_h` for hash from target object
* `serialize` and `to_json` for serialized JSON string

Other methods are rather trivial. They'll be added to this list when it turned out it's important enough.

## Implementation

In `Alba::Resource` module there are some things to note.

`@object` is an object for serialization. It's either singular object or collection.

Attribute object can be either `Symbol`, `Proc`, `Alba::Association` or `Alba::TypedAttribute`.

* `Symbol` attributes come from `attributes` method and are sent to `__send__` as method name
* `Proc` attributes come from `attribute` method and are `instance_exec`uted
* `Alba::Association` attributes come from `association` method and `to_h` method on the object is called
* `Alba::TypedAttribute` attributes come when users specify `type` option and `value` method on the object is called

When users provide `if` option, the attribute object becomes an `Array`. It contains two element, attribute itself and condition.
