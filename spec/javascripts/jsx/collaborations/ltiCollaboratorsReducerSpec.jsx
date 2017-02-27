define([
  'jsx/collaborations/reducers/ltiCollaboratorsReducer',
  'jsx/collaborations/actions/collaborationsActions'
], (reducer, actions) => {

  QUnit.module('ltiCollaboratorsReducer');

  const defaults = reducer(undefined, {})

  test('there are defaults', () => {
    equal(Array.isArray(defaults.ltiCollaboratorsData), true);
    equal(defaults.ltiCollaboratorsData.length, 0);
    equal(defaults.listLTICollaboratorsPending, false);
    equal(defaults.listLTICollaboratorsSuccessful, false);
    equal(defaults.listLTICollaboratorsError, null);
  });

  test('responds to listCollaborationsStart', () => {
    let state = {
      listLTICollaboratorsPending: false,
      listLTICollaboratorsSuccessful: true,
      listLTICollaboratorsError: {}
    };

    let action = actions.listLTICollaborationsStart();
    let newState = reducer(state, action);
    equal(newState.listLTICollaboratorsPending, true);
    equal(newState.listLTICollaboratorsSuccessful, false);
    equal(newState.listLTICollaboratorsError, null);
  });

  test('responds to listLTICollaborationsSuccessful', () => {
    let state = {
      listLTICollaboratorsPending: true,
      listLTICollaboratorsSuccessful: false,
      ltiCollaboratorsData: []
    };
    let ltiCollaboratorsData = [];

    let action = actions.listLTICollaborationsSuccessful(ltiCollaboratorsData);
    let newState = reducer(state, action);
    equal(newState.listLTICollaboratorsPending, false);
    equal(newState.listLTICollaboratorsSuccessful, true);
    equal(newState.ltiCollaboratorsData, ltiCollaboratorsData);
  });

  test('responds to listLTICollaborationsFailed', () => {
    let state = {
      listLTICollaboratorsPending: true,
      listLTICollaboratorsError: null
    };
    let error = {};

    let action = actions.listLTICollaborationsFailed(error);
    let newState = reducer(state, action);
    equal(newState.listLTICollaboratorsPending, false);
    equal(newState.listLTICollaboratorsError, error);
  });
});
