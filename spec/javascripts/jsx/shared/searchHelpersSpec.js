define([
  'jsx/shared/helpers/searchHelpers'
], (Helpers) => {
  QUnit.module('searchHelpers#exactMatchRegex', {
    setup() {
      this.regex = Helpers.exactMatchRegex("hello!");
    }
  });

  test('tests true against an exact match', function() {
    equal(this.regex.test("hello!"), true);
  });

  test('ignores case', function() {
    equal(this.regex.test("Hello!"), true);
  });

  test('tests false if it is a substring', function() {
    equal(this.regex.test("hello!sir"), false);
  });

  test('tests false against a completely different string', function() {
    equal(this.regex.test("cat"), false);
  });

  QUnit.module('searchHelpers#startOfStringRegex', {
    setup() {
      this.regex = Helpers.startOfStringRegex("hello!");
    }
  });

  test('tests true against an exact match', function() {
    equal(this.regex.test("hello!"), true);
  });

  test('ignores case', function() {
    equal(this.regex.test("Hello!"), true);
  });

  test('tests false if it is a substring that does not start at the beggining of the test string', function() {
    equal(this.regex.test("bhello!sir"), false);
  });

  test('tests true if it is a substring that starts at the beggining of the test string', function() {
    equal(this.regex.test("hello!sir"), true);
  });

  test('tests false against a completely different string', function() {
    equal(this.regex.test("cat"), false);
  });

  QUnit.module('searchHelpers#substringMatchRegex', {
    setup() {
      this.regex = Helpers.substringMatchRegex("hello!");
    }
  });

  test('tests true against an exact match', function() {
    equal(this.regex.test("hello!"), true);
  });

  test('ignores case', function() {
    equal(this.regex.test("Hello!"), true);
  });

  test('tests true if it is a substring that does not start at the beggining of the test string', function() {
    equal(this.regex.test("bhello!sir"), true);
  });

  test('tests true if it is a substring that starts at the beggining of the test string', function() {
    equal(this.regex.test("hello!sir"), true);
  });

  test('tests false against a completely different string', function() {
    equal(this.regex.test("cat"), false);
  });
});
