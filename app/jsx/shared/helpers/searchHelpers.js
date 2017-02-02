import _ from 'underscore'
import rEscape from 'compiled/regexp/rEscape'
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

export default SearchHelpers
