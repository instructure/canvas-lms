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
});