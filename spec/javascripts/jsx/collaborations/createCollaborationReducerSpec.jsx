define([
  'jsx/collaborations/reducers/createCollaborationReducer',
  'jsx/collaborations/actions/collaborationsActions'
], (reducer, actions) => {
  module('createCollaborationReducer');

  const defaults = reducer(undefined, {})

  test('there are defaults', () => {
    equal(defaults.createCollaborationPending, false);
    equal(defaults.createCollaborationSuccessful, false);
    equal(defaults.createCollaborationError, null);
  });

  test('responds to createCollaborationStart', () => {
    let state = {
      createCollaborationPending: false,
      createCollaborationSuccessful: true,
      createCollaborationError: {}
    };

    let action = actions.createCollaborationStart();
    let newState = reducer(state, action);
    equal(newState.createCollaborationPending, true);
    equal(newState.createCollaborationSuccessful, false);
    equal(newState.createCollaborationError, null);
  });

  test('responds to createCollaborationSuccessful', () => {
    let state = {
      createCollaborationPending: true,
      createCollaborationSuccessful: false,
      collaborations: []
    };
    let collaborations = [{}];

    let action = actions.createCollaborationSuccessful(collaborations);
    let newState = reducer(state, action);
    equal(newState.createCollaborationPending, false);
    equal(newState.createCollaborationSuccessful, true);
  });

  test('responds to createCollaborationFailed', () => {
    let state = {
      createCollaborationPending: true,
      createCollaborationError: null
    };
    let error = {};

    let action = actions.createCollaborationFailed(error);
    let newState = reducer(state, action);
    equal(newState.createCollaborationPending, false);
    equal(newState.createCollaborationError, error);
  });
});
