define([
  'jsx/course_settings/actions'
], (Actions) => {

  module('Course Settings Actions');

  test('calling setModalVisibility produces the proper object', () => {
    let actual = Actions.setModalVisibility(true);
    let expected = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: true
      }
    };

    deepEqual(actual, expected, 'the objects match');

    actual = Actions.setModalVisibility(false);
    expected = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: false
      }
    };
  });

});