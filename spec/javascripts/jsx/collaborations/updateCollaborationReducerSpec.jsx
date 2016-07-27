define([
  'jsx/collaborations/reducers/updateCollaborationReducer',
  'jsx/collaborations/actions/collaborationsActions'
], (reducer, actions) => {

  module('updateCollaborationReducer');

  let defaultState = reducer(undefined, {});

  test('has defaults', () => {
    equal(defaultState.updateCollaborationPending, false);
    equal(defaultState.updateCollaborationSuccessful, false);
    equal(defaultState.updateCollaborationError, null);
  });

  test('responds to updateCollaborationStart', () => {
    let initialState = {
      updateCollaborationPending: false,
      updateCollaborationSuccessful: false,
      updateCollaborationError: {}
    };

    let action = actions.updateCollaborationStart();
    let newState = reducer(initialState, action);

    equal(newState.updateCollaborationPending, true);
    equal(newState.updateCollaborationSuccessful, false);
    equal(newState.updateCollaborationError, null);
  });

  test('responds to updateCollaborationSuccessful', () => {
    let initialState = {
      updateCollaborationPending: true,
      updateCollaborationSuccessful: false
    };

    let action = actions.updateCollaborationSuccessful({});
    let newState = reducer(initialState, action);

    equal(newState.updateCollaborationPending, false);
    equal(newState.updateCollaborationSuccessful, true);
  });

  test('responds to updateCollaborationFailed', () => {
    let initialState = {
      updateCollaborationPending: true,
      updateCollaborationError: null
    };

    let error = {}

    let action = actions.updateCollaborationFailed(error);
    let newState = reducer(initialState, action);

    equal(newState.updateCollaborationPending, false);
    equal(newState.updateCollaborationError, error);
  });

})
