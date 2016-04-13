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

  test('calling gotCourseImage produces the proper object', () => {
    const actual = Actions.gotCourseImage('http://imageUrl');
    const expected = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl: 'http://imageUrl'
      }
    };

    deepEqual(actual, expected, 'the objects match');
  });

  asyncTest('getCourseImage', () => {
    const fakeResponse = {
      data: {
        image: 'http://imageUrl'
      }
    };

    const fakeAjaxLib = {
      get (url) {
        return new Promise((resolve) => {
          setTimeout(() => resolve(fakeResponse), 100);
        });
      }
    };

    const expectedAction = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl: 'http://imageUrl'
      }
    };

    Actions.getCourseImage(1, fakeAjaxLib)((dispatched) => {
      start();
      deepEqual(dispatched, expectedAction, 'the proper action was dispatched');
    });
  });

});