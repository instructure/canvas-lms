// TODO: right now, whenever someone require's 'moment', we have
// an alias set up in both our baseWebpackConfig.js and our require_js.rb config
// so it actually requires this file. once we are all-webpack, we should not load
// all of the locales and just load the one they need with something like this:

// // in baseWebpackConfig
// new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),

// // in entry
// const moment = require('moment')
// const loadMomentLocale = ENV.MOMENT_LOCALE && new Promise(resolve => {
//   if (ENV.MOMENT_LOCALE == 'mi-nz') {
//     require(['custom_moment_locales/mi_nz'], () => resolve())
//   }
//   require('bundle!moment/locale/' + ENV.MOMENT_LOCALE + '.js')(() => {
//     moment().locale(ENV.MOMENT_LOCALE)
//     resolve()
//   })
// })
// loadMomentLocale.then(function(){
//   // run any code that uses moment
// }

define(['node_modules-version-of-moment'], function(moment) {
  // Include locale that is not a part of momentjs proper.
  var mi_nz = moment.defineLocale('mi-nz', {
    months: 'Kohi-tāte_Hui-tanguru_Poutū-te-rangi_Paenga-whāwhā_Haratua_Pipiri_Hōngoingoi_Here-turi-kōkā_Mahuru_Whiringa-ā-nuku_Whiringa-ā-rangi_Hakihea'.split('_'),
    monthsShort: 'Kohi_Hui_Pou_Pae_Hara_Pipi_Hōngoi_Here_Mahu_Whi-nu_Whi-ra_Haki'.split('_'),
    weekdays: 'Rātapu_Mane_Tūrei_Wenerei_Tāite_Paraire_Hātarei'.split('_'),
    weekdaysShort: 'Ta_Ma_Tū_We_Tāi_Pa_Hā'.split('_'),
    weekdaysMin: 'Ta_Ma_Tū_We_Tāi_Pa_Hā'.split('_'),
    longDateFormat: {
      LT: 'HH:mm',
      LTS: 'HH:mm:ss',
      L: 'DD/MM/YYYY',
      LL: 'D MMMM YYYY',
      LLL: 'D MMMM YYYY [i] HH:mm',
      LLLL: 'dddd, D MMMM YYYY [i] HH:mm'
    },
    calendar: {
      sameDay: '[i teie mahana, i] LT',
      nextDay: '[apopo i] LT',
      nextWeek: 'dddd [i] LT',
      lastDay: '[inanahi i] LT',
      lastWeek: 'dddd [whakamutunga i] LT',
      sameElse: 'L'
    },
    relativeTime: {
      future: 'i roto i %s',
      past: '%s i mua',
      s: 'te hēkona ruarua',
      m: 'he meneti',
      mm: '%d meneti',
      h: 'te haora',
      hh: '%d haora',
      d: 'he ra',
      dd: '%d ra',
      M: 'he marama',
      MM: '%d marama',
      y: 'he tau',
      yy: '%d tau'
    },
    ordinalParse: /\d{1,2}º/,
    ordinal: '%dº'
  });

  return moment;
});
