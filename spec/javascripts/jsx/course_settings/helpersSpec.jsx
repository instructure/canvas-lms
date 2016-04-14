define([
  'jsx/course_settings/helpers'
], (Helpers) => {

  module('Course Settings Helpers');

  test('isValidImageType', () => {
    ok(Helpers.isValidImageType('image/jpeg'), 'accepts jpeg');
    ok(Helpers.isValidImageType('image/gif'), 'accepts gif');
    ok(Helpers.isValidImageType('image/png'), 'accepts png');
    ok(!Helpers.isValidImageType('image/tiff'), 'denies tiff');
  });

  test('createFormData', () => {
    const params = {
      paramOne: 'valueOne',
      paramTwo: 'valueTwo'
    };

    const formData = Helpers.createFormData(params);

    ok(formData instanceof FormData, 'created a FormData object');
  });

});