define(['underscore', 'i18nObj', "moment"], function( _, I18n, moment) {
  return {

    i18nToMomentHash: {
      "%A": "dddd",
      "%B": "MMMM",
      "%H": "HH",
      "%M": "mm",
      "%P": "a",
      "%Y": "YYYY",
      "%a": "ddd",
      "%b": "MMM",
      "%d": "D",
      "%k": "H",
      "%l": "h",

      "%-A": "dddd",
      "%-B": "MMMM",
      "%-H": "HH",
      "%-M": "mm",
      "%-P": "a",
      "%-Y": "YYYY",
      "%-a": "ddd",
      "%-b": "MMM",
      "%-d": "D",
      "%-k": "H",
      "%-l": "h"
    },

    basicMomentFormats: ["LT", "LTS", "L", "l", "LL", "ll", "LLL", "lll", "LLLL", "llll"],

    getFormats: function(){
      var formatsToTransform = this.formatsForLocale()
      return this.transformFormats(formatsToTransform)
    },

    transformFormats: _.memoize( function(formats){
      var localeSpecificFormats = _.map(formats, this.i18nToMomentFormat, this)
      return _.union(this.basicMomentFormats, localeSpecificFormats)
    }),

    formatsForLocale: function(){
      return _.union(
        _.values(I18n.lookup('date.formats')),
        _.values(I18n.lookup('time.formats'))
      )
    },

    i18nToMomentFormat: function(fullString){
      var withEscapes = this.escapeSubStrings(fullString)
      return this.replaceDateKeys(withEscapes)
    },

    escapeSubStrings: function(formatString){
      var substrings = formatString.split(" ")
      var escapedSubs = _.map(substrings, this.escapedUnlessi18nKey, this)
      return escapedSubs.join(" ")
    },

    escapedUnlessi18nKey: function(string){
      var isKey = _.detect(_.keys(this.i18nToMomentHash), function(k){
        return string.indexOf(k) > -1
      })

      return isKey ? string : "["+ string +"]"
    },

    replaceDateKeys: function(formatString){
      return _.reduce(this.i18nToMomentHash, function(string, forMoment, forBase){
        return string.replace(forBase, forMoment)
      }, formatString)
    }
  }
})
