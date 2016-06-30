define([
  'underscore',
  'compiled/regexp/rEscape'
], function (_, rEscape) {
  let SearchHelpers = {
    exactMatchRegex(string) {
      return new RegExp('^' + rEscape(string) + '$', 'i')
    },

    startOfStringRegex(string) {
      return new RegExp('^' + rEscape(string), 'i')
    },

    substringMatchRegex(string) {
      return new RegExp(rEscape(string), 'i')
    },
  };

  return SearchHelpers;
});
