define([
  'jsx/cyoe_assignment_sidebar/actions/conditional-actions'
], (Actions) => {

  module('Master Paths Teacher Sidebar actions');

  test('updates the correct scoring range boundary', () => {
    const ranges = [
      {
        upper_bound: 1.0
      }
    ]
    const actual = Actions.setScoringRanges(ranges);
    const expected = {
      type: 'SET_SCORING_RANGES',
      payload: [
      {
        upper_bound: 1.0
      }
    ]
    };

    deepEqual(actual, expected, 'the objects match');
  });

  test('updates correct breakdown bar by the index ', () => {
    const actual = Actions.setBarAtIndex(5, 'test');
    const expected = {
      type: 'SET_BAR_AT_INDEX',
      payload: {
        index: 5,
        bar: 'test'
      }
    };

    deepEqual(actual, expected, 'the objects match');
  });

  test('sets the correct trigger assignment id', () => {
    const rule = {
      id: 5
    }
    const actual = Actions.setRule(rule);
    const expected = {
      type: 'SET_RULE',
      payload: {
        id : 5
      }
    };

    deepEqual(actual, expected, 'the objects match');

  });

  test('sets the correct number of students enrolled in the breakdown graph', () => {
    const actual = Actions.setEnrolled(12);
    const expected = {
      type: 'SET_ENROLLED',
      payload: 12
    };

    deepEqual(actual, expected, 'the objects match');
  });

  test('updates with the correct errors', () => {
    const errors = ['Wrong Error']
    const actual = Actions.setErrors(errors);
    const expected = {
      type: 'SET_ERRORS',
      payload: ['Wrong Error']
    };

    deepEqual(actual, expected, 'the objects match');

  });

  test('updates with the correct assignment ID', () => {
    const assignment = {
      id: 'name'
    }
    const actual = Actions.setAssignment(assignment);
    const expected = {
      type: 'SET_ASSIGNMENT',
      payload: {
        id: 'name'
      }
    };

    deepEqual(actual, expected, 'the objects match');

  });

  test('sidebar opens with correct index', () => {
    const actual = Actions.openSidebar(1);
    const expected = {
      type: 'OPEN_SIDEBAR',
      payload: 1
    };

    deepEqual(actual, expected, 'the objects match');
  });

  test('closes sidebar correctly', () => {
    const actual = Actions.closeSidebar();
    const expected = {
      type: 'CLOSE_SIDEBAR',
    };

    deepEqual(actual, expected, 'the objects match');
  });


});