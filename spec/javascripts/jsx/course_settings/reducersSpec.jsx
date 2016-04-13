define(['jsx/course_settings/reducer'], (reducer) => {

  module('Course Settings Reducer');

  test('Unknown action types return initialState', () => {
    const initialState = {
      courseImage: 'abc'
    };

    const action = {
      type: 'I_AM_NOT_A_REAL_ACTION'
    };

    const newState = reducer(initialState, action);

    deepEqual(initialState, newState, 'state is unchanged');
  });

  test('sets the modal visibility properly', () => {
    const action = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: true
      }
    };

    const initialState = {
      showModal: false
    };

    const newState = reducer(initialState, action);
    equal(newState.showModal, true, 'state is updated to show the modal');
  });

  test('sets course image properly', () => {
    const action = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageString: '123',
        imageUrl: 'http://imageUrl'
      }
    };

    const initialState = {
      courseImage: 'abc',
      imageUrl: '',
    };

    const newState = reducer(initialState, action);
    equal(newState.courseImage, '123', 'state has the course image set');
    equal(newState.imageUrl, 'http://imageUrl', 'state has the image url set');
  });


});