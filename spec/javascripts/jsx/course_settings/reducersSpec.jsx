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

  test('sets uploading image properly', () => {
    const action = {
      type: 'UPLOADING_IMAGE'
    };

    const initialState = {
      uploadingImage: false
    };

    const newState = reducer(initialState, action);
    equal(newState.uploadingImage, true, 'state is updated to indicate image uploading');
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

  test('SET_COURSE_IMAGE_ID', () => {
    const action = {
      type: 'SET_COURSE_IMAGE_ID',
      payload: {
        imageUrl: 'http://imageUrl',
        imageId: 42,
      }
    };

    const initialState = {
      imageUrl: '',
      courseImage: '',
      showModal: true,
    };

    const newState = reducer(initialState, action);
    equal(newState.imageUrl, 'http://imageUrl', 'image url gets set');
    equal(newState.courseImage, '42', 'image id gets set');
    equal(newState.showModal, false, 'modal gets closed');
  });

  test('sets removing image properly', () => {
    const action = {
      type: 'REMOVING_IMAGE'
    };

    const initialState = {
      removingImage: false
    };

    const newState = reducer(initialState, action);
    equal(newState.removingImage, true, 'state is updated to indicate removing image');
  });

  test('sets removed image properly', () => {
    const action = {
      type: 'REMOVED_IMAGE'
    };

    const initialState = {
      imageUrl: 'http://imageUrl',
      courseImage: '24',
      removingImage: true
    };

    const newState = reducer(initialState, action);
    equal(newState.imageUrl, '', 'image url gets removed');
    equal(newState.courseImage, 'abc', 'course image gets cleared');
    equal(newState.removingImage, false, 'no longer removing image');
  });

  test('sets removing image to false on error', () => {
    const action = {
      type: 'ERROR_REMOVING_IMAGE'
    };

    const initialState = {
      removingImage: true
    };

    const newState = reducer(initialState, action);
    equal(newState.removingImage, false, 'removing image set to false after error');
  });
  
});