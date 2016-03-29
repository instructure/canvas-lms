define ["underscore"], (_) ->
  class CalendarLocaleConverter
    # note: order of keys matters due to formattedAndSplitMapping
    # see comment below
    @localeMapping:
      "ar": "ar"
      "da": "da"
      "de": "de"
      "de-DE": "de"
      "en-AU": "en-au"
      "en-GB": "en-gb"
      "en-US": "en"
      "es": "es"
      "fa-IR": "fa"
      "fr": "fr"
      "he": "he"
      "hy": null #armenian
      "ja": "ja"
      "ko": "ko"
      "mi": null #maori
      "nb": "nb"
      "nl": "nl"
      "pl": "pl"
      "pt-BR": "pt-br"
      "pt": "pt"
      "ru": "ru"
      "sv": "sv"
      "tr": "tr"
      "zh":"zh-cn"
      "zh_Hant":"zh-cn"

    @formatString: (str) ->
      str && str.toLowerCase().replace("-", "_")

    @splitAndUseFirst: (str) ->
      str && str.split("_")[0]

    @keyMap: (obj, fn) ->
      newKeys = _.chain(obj).
                  keys().
                  map(fn).
                  value()
      _.object(_.zip(newKeys, _.values(obj)))

    @formattedMapping: @keyMap(@localeMapping, @formatString)

    # there is a chance of overlapping keys as something like "pt-BR"
    # would become "pt" - the later key's value will be returned
    @formattedAndSplitMapping: @keyMap(@formattedMapping, @splitAndUseFirst)

    @localeToLang: (canvasLocale) ->
      forFormatted = @formatString(canvasLocale)
      forFormattedAndSplit = @splitAndUseFirst(forFormatted)

      @localeMapping[canvasLocale] || @formattedMapping[forFormatted] ||
        @formattedAndSplitMapping[forFormattedAndSplit] || "en"
