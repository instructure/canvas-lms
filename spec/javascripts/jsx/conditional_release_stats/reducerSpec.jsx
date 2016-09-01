define([
  'jsx/conditional_release_stats/actions',
  'jsx/conditional_release_stats/reducers/root-reducer',
], ({ actions }, reducer) => {
  module('Conditional Release Stats reducer')

  const reduce = (action, state = {}) => {
    return reducer(state, action)
  }

  test('sets correct number of students enrolled', () => {
    const newState = reduce(actions.setEnrolled(10))
    equal(newState.enrolled, 10, 'enrolled is changed')
  })

  test('sets the correct trigger assignment', () => {
    const newState = reduce(actions.setAssignment(2))
    equal(newState.assignment, 2, 'assignment is changed')
  })

  test('updates range boundaries with correct values', () => {
    const ranges = [
      { upper_bound: '10' },
      { upper_bound: '11' },
    ]

    const newState = reduce(actions.setScoringRanges(ranges))
    deepEqual(newState.ranges, ranges, 'scoring range is changed')
  })

  test('sets the correct errors', () => {
    const errors = ['Invalid Rule', 'Unable to Load']

    const newState = reduce(actions.setErrors(errors))
    deepEqual(newState.errors, errors, 'errors is changed')
  })

  test('open sidebar correctly', () => {
    const newState = reduce(actions.openSidebar())
    equal(newState.showDetails, true, 'opens sidebar')
  })

  test('open sidebar on select range', () => {
    const newState = reduce(actions.selectRange(1))
    equal(newState.showDetails, true, 'opens sidebar')
  })

  test('closes sidebar correctly', () => {
    const newState = reduce(actions.closeSidebar())
    equal(newState.showDetails, false, 'closes sidebar')
  })

  test('closes sidebar resets selected student', () => {
    const newState = reduce(actions.closeSidebar())
    equal(newState.selectedPath.student, null, 'resets student')
  })

  test('selects range', () => {
    const newState = reduce(actions.selectRange(1))
    equal(newState.selectedPath.range, 1, 'selects range')
  })

  test('selects student', () => {
    const newState = reduce(actions.selectStudent(1))
    equal(newState.selectedPath.student, 1, 'selects student')
  })

  test('load start', () => {
    const newState = reduce(actions.loadStart())
    equal(newState.isLoading, true, 'starts load')
  })

  test('load end', () => {
    const newState = reduce(actions.loadEnd())
    equal(newState.isLoading, false, 'ends load')
  })
})
