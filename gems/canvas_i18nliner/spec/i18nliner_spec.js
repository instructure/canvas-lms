/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const mkdirp = require("mkdirp");
const { I18nliner } = require("../js/main");
const scanner = require("../js/scanner");

var subject = function(dir) {
  var command = new I18nliner.Commands.Check({});
  scanner.scanFilesFromI18nrc(scanner.loadConfigFromDirectory(dir))
  command.run();
  return command.translations.masterHash.translations;
}

describe("I18nliner", function() {
  afterEach(function() {
    scanner.reset()
  })

  describe("handlebars", function() {
    it("extracts default translations", function() {
      expect(subject("spec/fixtures/hbs")).toEqual({
        absolute_key: "Absolute key",
        inferred_key_c49e3743: "Inferred key",
        inline_with_absolute_key: "Inline with absolute key",
        inline_with_inferred_key_88e68761: "Inline with inferred key",
        foo: {
          bar_baz: {
            inline_with_relative_key: "Inline with relative key",
            relative_key: "Relative key"
          },
          bar_fizz_buzz: {
            inline_with_relative_key: "Inline with relative key"
          }
        }
      });
    });

    it('throws if no scope was specified', () => {
      const command = new I18nliner.Commands.Check({});
      const origDir = process.cwd();

      try {
        process.chdir('spec/fixtures/hbs-missing-i18n-scope');
        command.checkFiles();
      }
      finally {
        process.chdir(origDir);
      }

      expect(command.isSuccess()).toBeFalsy()
      expect(command.errors.length).toEqual(1)
      expect(command.errors[0]).toMatch(/expected i18nScope for Handlebars template to be specified/)
    })
  });

  describe("javascript", function() {
    it("extracts default translations", function() {
      expect(subject("spec/fixtures/js")).toEqual({
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
