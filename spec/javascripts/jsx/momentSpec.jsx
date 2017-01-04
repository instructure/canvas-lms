define([
  'moment',

], (moment) => {
  module('moment module test');

  test('moment should include the locale mi-nz', () => {

    // webpack does not load up all locales by default.
    // we have to ask for it specifically
    if (window.USE_WEBPACK) require('custom_moment_locales/mi_nz');

    notEqual(moment.localeData('mi-nz'), null, 'locale data for mi-nz is not null');
  });
});
