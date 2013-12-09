define [
  './start_app'
  'ember'
  'ic-ajax'
], (startApp, Ember, ajax) ->

  App = null

  window.ENV.GRADEBOOK_OPTIONS = {
    students_url: '/api/v1/enrollments'
    assignment_groups_url: '/api/v1/assignment_groups'
    submissions_url: '/api/v1/submissions'
    sections_url: '/api/v1/sections'
  }

  ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.students_url,
    response: [
      {
        user: { id: 1, name: 'Bob' }
      }
      {
        user: { id: 2, name: 'Fred' }
      }
    ]
    jqXHR: { getResponseHeader: -> {} }
    textStatus: ''

  ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.assignment_groups_url,
    response: [
      {
        id: 1
        name: 'AG1'
        assignments: [
          { id: 1, name: 'Eat Soup', points_possible: 5 }
          { id: 2, name: 'Drink Water', points_possible: null }
        ]
      }
    ]
    jqXHR: { getResponseHeader: -> {} }
    textStatus: ''

  ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.submissions_url,
    response: [
      { id: 1, user_id: 1, assignment_id: 1, grade: '3' }
      { id: 2, user_id: 1, assignment_id: 2, grade: null }
    ]
    jqXHR: { getResponseHeader: -> {} }
    textStatus: ''

  ajax.defineFixture window.ENV.GRADEBOOK_OPTIONS.sections_url,
    response: [
      { id: 1, name: 'Section 1' }
      { id: 2, name: 'Section 2' }
    ]
    jqXHR: { getResponseHeader: -> {} }
    textStatus: ''

  module 'screenreader_gradebook',
    setup: ->
      App = startApp()
    teardown: ->
      Ember.run App, 'destroy'

  test 'fetches enrollments', ->
    controller = App.__container__.lookup('controller:screenreader_gradebook')
    equal controller.get('enrollments').objectAt(0).user.name, 'Bob'
    equal controller.get('enrollments').objectAt(1).user.name, 'Fred'

  test 'fetches assignment_groups', ->
    controller = App.__container__.lookup('controller:screenreader_gradebook')
    equal controller.get('assignment_groups').objectAt(0).name, 'AG1'

  test 'fetches submissions', ->
    controller = App.__container__.lookup('controller:screenreader_gradebook')
    equal controller.get('submissions').objectAt(0).grade, '3'
    equal controller.get('submissions').objectAt(1).grade, null

  test 'fetches sections', ->
    controller = App.__container__.lookup('controller:screenreader_gradebook')
    equal controller.get('sections').objectAt(0).name, 'Section 1'
    equal controller.get('sections').objectAt(1).name, 'Section 2'
