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

  test('extractInfoFromEvent', () => {
    const changeEvent = {
      type: 'change',
      target: {
        files: [{type: 'image/jpeg'}]
      }
    };

    const dragEvent = {
      type: 'drop',
      dataTransfer: {
        files: [{
          name: 'test',
          type: 'image/jpeg'
        }]
      },
    };

    const changeResults = Helpers.extractInfoFromEvent(changeEvent);
    const expectedChangeResults = {
      file: {
        type: 'image/jpeg'
      },
      type: 'image/jpeg'
    };

    const dragResults = Helpers.extractInfoFromEvent(dragEvent);
    const expectedDragResults = {
      file: {
        name: 'test',
        type: 'image/jpeg'
      },
      type: 'image/jpeg'
    };

    deepEqual(changeResults, expectedChangeResults, 'creates the proper info from change events');
    deepEqual(dragResults, expectedDragResults, 'creates the proper info from drag events');
  });

});