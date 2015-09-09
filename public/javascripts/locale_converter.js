define(['underscore'], function( _ ) {
  return {
    localesByBaseName: {
      "ar_SA": "ar-sa",
      "da_DK": "da",
      "de_DE": "de",
      "en_AU": "en-au",
      "en_GB": "en-gb",
      "en_US": "en",
      "es_ES": "es",
      "fa_IR": "fa",
      "fr_FR": "fr",
      "hy_AM": "hy-am",
      "ja_JP": "ja",
      "ko_KR": "ko",
      "mi_NZ": "mi-nz",
      "nb_NO": "nb",
      "nl_NL": "nl",
      "pl_PL": "pl",
      "pt_BR": "pt-br",
      "pt_PT": "pt",
      "ru_RU": "ru",
      "sv_SE": "sv",
      "tr_TR": "tr",
      "zh_CN": "zh-cn",
      "zh_HK": "zh-tw"
    },

    localesByMomentName: _.invert(this.localesByBaseName),

    convertToMoment: function(localeName){
      return this.localesByBaseName[localeName] || localeName
    },

    convertFromMoment: function(momentLocale){
      return this.localesByMomentName[momentLocale] || momentLocale
    }
  }
})
