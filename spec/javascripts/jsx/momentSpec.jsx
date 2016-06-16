define(['moment'], (moment) => {
  module('moment module test');

  test('moment should include the locale mi-nz', () => {
    notEqual(moment.localeData('mi-nz'), null, 'locale data for mi-nz is not null');
  });
});
