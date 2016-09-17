define([
  'jsx/cyoe_assignment_sidebar/reducers/root-reducer',
  ], (reducer) => {

  module('Master Paths Teacher Sidebar reducer');

  const defaultState = {
    ranges: 1,
    rule: 1,
    enrolled: 1,
    assignment: 1,
    global_shared : {
      errors: [],
      open: null
    }
  }

  test('does not change state with unknown state', () => {
    const action = {
      type: 'I_AM_NOT_A_REAL_ACTION'
    };

    const newState = reducer(defaultState, action);

    deepEqual(defaultState, newState, 'state is unchanged');
  });

  test('sets correct number of students enrolled', () => {
    const startingState = defaultState

    const action = {
      type: 'SET_ENROLLED',
      payload: 10
    };

    const newState = reducer(startingState, action);
    equal(newState.enrolled, 10, 'state enrolled is changed');
  });


  test('sets the correct trigger assignment', () => {
    const startingState = defaultState

    const assignment = {
      id: 2
    };

    const action = {
      type: 'SET_ASSIGNMENT',
      payload: assignment
    };

    const newState = reducer(defaultState, action);
    equal(newState.assignment , assignment, 'state assignment is changed');
  });

  test('updates range boundaries with correct values', () => {
    const startingState = defaultState

    const ranges = [
      { upper_bound: 10 },
      { upper_bound: 11 }
    ]

    const action = {
      type: 'SET_SCORING_RANGES',
      payload: ranges
    };

    const newState = reducer(defaultState, action);
    equal(newState.ranges , ranges, 'state scoring range is changed');
  });

  test('sets the correct errors', () => {
    const startingState = defaultState

    const errors = ['Invalid Rule', 'Unable to Load']

    const action = {
      type: 'SET_ERRORS',
      payload: errors
    };

    const newState = reducer(startingState, action);
    deepEqual(newState.global_shared.errors , errors, 'state errors is changed');
  });

  test('open sidebar correctly', () => {
    const startingState = defaultState

    const action = {
      type: 'OPEN_SIDEBAR',
      payload: 1
    };

    const newState = reducer(startingState, action);
    equal(newState.global_shared.open, 1, 'state open index');
  });

  test('closes sidebar correctly', () => {
    const startingState = defaultState

    const action = {
      type: 'CLOSE_SIDEBAR'
    };

    const newState = reducer(startingState, action);
    equal(newState.global_shared.open, null, 'state open is set to close');
  });

});
