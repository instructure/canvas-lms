---
name: rspec
description: MUST use this skill when writing, reviewing, or modifying Ruby RSpec tests (*_spec.rb) in Canvas
---

When writing or reviewing RSpec tests in Canvas, there are several guidelines to ensure tests are effective and maintainable.
Canvas' codebase is quite old, so there are many legacy tests that don't follow modern best practices.

- Prefer `let` and `let!` for defining test data instead of instance variables. This provides better scoping and lazy loading of test data. This also applies to using `let` instead of `before` blocks for setting up test data.
- When an ActiveRecord model instance is shared across multiple tests without any stubbed methods, use `let_once` to define it. This will create the object once and reuse it across examples, improving test performance.
- When using `subject`, remember that it's a noun -- don't use it as a way to perform a common action across multiple examples. The `subject` should be the object under test. If you want to perform a common action across multiple examples, write a method. You can call that in each action. Or use a `before` block if it makes sense.
- Look for repetitive patterns in your tests, and extract them into `let`, `before` blocks, helper methods, or shared context as appropriate. This will make your tests more DRY and easier to read.
- Don't create "factory" methods for models unless the method is doing something non-trivial. Most factory methods are simply guessing a couple of defaults (that you're likely passing in anyway) and then calling `create!` on the model. Simply pass your attributes directly to `create!` yourself. If you find yourself wanting to infer the same values over and over, consider a `before_validation` hook on the model that can infer them for you.
- Don't use raw `double` unless absolutely necessary. `instance_double` and `class_double` provide better guarantees that your test doubles are accurate representations of the real objects.
- For specs testing individual methods, group all examples for that method within a `describe "#method_name"` or `describe ".class_method_name"` block.
- For controller specs and integration specs testing a single action, group all examples for that action within a `describe "HTTP_METHOD action_name"` block (e.g. `describe "GET index"`).
- Do not create any classes or modules within spec files. If you need to define a class or module for testing purposes, define it dynamically (`Class.new`), and assign it either with `let` or `stub_const`.
- Do not create any top-level methods within spec files. Helper methods can be defined in the appropriate example group, or in a shared group that can be included where needed.
- Use the strictest equality matcher that makes sense:
  - `be` asserts object identity -- use it for numbers, symbols, true, false, nil, or when you specifically want to assert that two variables point to the same object.
  - `eql` asserts that two values are not just semantically the same, but also of the same type without conversions -- this should be the most commonly used matcher for types like strings, arrays, hashes, and custom objects.
  - `eq` asserts that two values are semantically the same, allowing for type conversions.
