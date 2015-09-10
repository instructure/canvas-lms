define [
  'react'
  'jsx/gradebook/grid/stores/studentEnrollmentsStore'
  'jsx/gradebook/grid/actions/studentEnrollmentsActions'
], (React, StudentEnrollmentsStore) ->
  TestUtils = React.addons.TestUtils

  module 'ReactGradebook.studentEnrollmentStore',
    setup: ->
      StudentEnrollmentsStore.getInitialState()
    teardown: ->

  test 'initial state values are set to null', () ->
    expected =
      data: null
      error: null
      all: null

    actual = StudentEnrollmentsStore.getInitialState()
    deepEqual(actual, expected)

  test 'returns all records by default', () ->
    expected = [1,2,3]
    actual = null
    StudentEnrollmentsStore.listen (state) ->
      actual = state.data
    StudentEnrollmentsStore.onLoadCompleted([1,2,3])
    deepEqual(actual, expected)

  test 'filters enrollments by name', () ->
    loaded = [
      {
        user_id: 1
        user:
          id: 1,
          name: 'some name'
      }
      {
        user_id: 2,
        user:
          id: 2,
          name: 'another name'
      }
    ]
    expected = [
      {
        user_id: 2,
        user:
          id: 2,
          name: 'another name'
      }
    ]
    actual = null
    StudentEnrollmentsStore.onLoadCompleted(loaded)
    StudentEnrollmentsStore.listen (state) ->
      actual = state.data
    StudentEnrollmentsStore.onSearch('an')
    deepEqual(actual, expected)

  test 'filters enrollments by sis login id', () ->
    loaded = [
      {
        user_id: 1
        user:
          id: 1
          sis_login_id: 'some_id'
      }
      {
        user_id: 2
        user:
          id: 2
          sis_login_id: 'another_id'
      }
    ]
    expected = [
      {
        user_id: 2
        user:
          id: 2
          sis_login_id: 'another_id'
      }
    ]
    actual = null
    StudentEnrollmentsStore.onLoadCompleted(loaded)
    StudentEnrollmentsStore.listen (state) ->
      actual = state.data
    StudentEnrollmentsStore.onSearch('ano')
    deepEqual(actual, expected)

  test 'filters enrollments by user login id', () ->
    loaded = [
      {
        user_id: 1
        user:
          id: 1
          login_id: 'some_id'
      }
      {
        user_id: 2
        user:
          id: 2
          login_id: 'another_id'
      }
    ]
    expected = [
      {
        user_id: 2
        user:
          id: 2
          login_id: 'another_id'
      }
    ]
    actual = null
    StudentEnrollmentsStore.onLoadCompleted(loaded)
    StudentEnrollmentsStore.listen (state) ->
      actual = state.data
    StudentEnrollmentsStore.onSearch('ano')
    deepEqual(actual, expected)

  test 'shows nobody if search string has no matches', () ->
    loaded = [
      {
        user_id: 1
        user:
          id: 1
          sis_login_id: 'unmatched'
          login_id: 'unmatched'
          name: 'unmatched'
      }
      {
        user_id: 2
        user:
          id: 2
          sis_login_id: 'unmatched'
          login_id: 'unmatched'
          name: 'unmatched'
      }
    ]
    expected = []
    actual = null
    StudentEnrollmentsStore.onLoadCompleted(loaded)
    StudentEnrollmentsStore.listen (state) ->
      actual = state.data
    StudentEnrollmentsStore.onSearch('ano')
    deepEqual(actual, expected)

  test 'shows everybody if search string is empty or null', () ->
    loaded = [
      {
        user_id: 1
        user:
          id: 1
          sis_login_id: 'unmatched'
          login_id: 'unmatched'
          name: 'unmatched'
      }
      {
        user_id: 2
        user:
          id: 2
          sis_login_id: 'unmatched'
          login_id: 'unmatched'
          name: 'unmatched'
      }
    ]
    expected = loaded
    actual = null
    StudentEnrollmentsStore.onLoadCompleted(loaded)
    StudentEnrollmentsStore.listen (state) ->
      actual = state.data
    StudentEnrollmentsStore.onSearch('')
    deepEqual(actual, expected)
