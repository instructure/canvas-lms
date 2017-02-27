var I18nliner = require("../js/main").I18nliner;
var mkdirp = require("mkdirp");

var subject = function(path) {
  var command = new I18nliner.Commands.Check({});
  var origDir = process.cwd();
  try {
    process.chdir(path);
    command.processors.forEach(function(processor) {
      processor.directories.forEach(function(directory) {
        mkdirp.sync(directory);
      });
    });
    command.run();
  }
  finally {
    process.chdir(origDir);
  }
  return command.translations.masterHash.translations;
}

describe("I18nliner", function() {
  describe("handlebars", function() {
    it("extracts default translations", function() {
      expect(subject("test/fixtures/hbs")).toEqual({
        absolute_key: "Absolute key",
        inferred_key_c49e3743: "Inferred key",
        inline_with_absolute_key: "Inline with absolute key",
        inline_with_inferred_key_88e68761: "Inline with inferred key",
        foo: {
          bar_baz: {
            inline_with_relative_key: "Inline with relative key",
            relative_key: "Relative key"
          }
        }
      });
    });
  });

  describe("javascript", function() {
    it("extracts default translations", function() {
      expect(subject("test/fixtures/js")).toEqual({
        absolute_key: "Absolute key",
        inferred_key_c49e3743: "Inferred key",
        foo: {
          relative_key: "Relative key"
        },
        bar: {
          relative_key: "Another relative key"
        },
        nested: {
          relative_key: "Relative key in nested scope"
        },
        yay_coffee_d4d65736: 'yay coffee',
        yay_jsx_49700f4a: 'yay jsx'
      });
    });
  });
});
