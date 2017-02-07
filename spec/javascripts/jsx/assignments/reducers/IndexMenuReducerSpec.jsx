define([
  'jsx/assignments/actions/IndexMenuActions',
  'jsx/assignments/reducers/indexMenuReducer',
], (Actions, Reducer) => {
  module('AssignmentsIndexMenuReducer')

  test('SET_MODAL_OPEN actions result in expected state', () => {
    const initialState1 = { modalIsOpen: false };
    const action1 = {
      type: Actions.SET_MODAL_OPEN,
      payload: true,
    };
    const expectedState1 = { modalIsOpen: true };
    const newState1 = Reducer(initialState1, action1);
    deepEqual(expectedState1, newState1);

    const initialState2 = { modalIsOpen: true };
    const action2 = {
      type: Actions.SET_MODAL_OPEN,
      payload: false,
    };
    const expectedState2 = { modalIsOpen: false };
    const newState2 = Reducer(initialState2, action2);
    deepEqual(expectedState2, newState2);
  });

  test('LAUNCH_TOOL actions result in expected state', () => {
    const tool = { 'foo' : 'bar' };
    const initialState = { modalIsOpen: false, selectedTool: null };
    const action = { type: Actions.LAUNCH_TOOL, payload: tool };
    const expectedState = { modalIsOpen: true, selectedTool: tool };
    const newState = Reducer(initialState, action);

    deepEqual(expectedState, newState);
  });

  test('SET_TOOLS actions result in expected state', () => {
    const tools = [1, 2, 3];
    const initialState = { externalTools: [] };
    const action = { type: Actions.SET_TOOLS, payload: tools };
    const expectedState = { externalTools: tools };
    const newState = Reducer(initialState, action);

    deepEqual(expectedState, newState);
  });

  test('SET_WEIGHTED actions result in expected state', () => {
    const initialState1 = { weighted: false };
    const action1 = {
      type: Actions.SET_WEIGHTED,
      payload: true,
    };
    const expectedState1 = { weighted: true };
    const newState1 = Reducer(initialState1, action1);
    deepEqual(expectedState1, newState1);

    const initialState2 = { weighted: true };
    const action2 = {
      type: Actions.SET_WEIGHTED,
      payload: false,
    };
    const expectedState2 = { weighted: false };
    const newState2 = Reducer(initialState2, action2);
    deepEqual(expectedState2, newState2);
  });
});
