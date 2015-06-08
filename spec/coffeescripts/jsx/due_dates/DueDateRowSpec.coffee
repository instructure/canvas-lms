define [
  'react'
  'underscore'
  'jsx/due_dates/DueDateRow'
  'helpers/fakeENV'
], (React, _, DueDateRow, fakeENV) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'DueDateRow with empty props and canDelete true',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      props =
        overrides: []
        sections: {}
        students: {}
        dates: {}
        canDelete: true
        rowKey: "nullnullnull"
        validDropdownOptions: []
        currentlySearching: false
        allStudentsFetched: true
        handleDelete: ->
        defaultSectionNamer: ->
        handleTokenAdd: ->
        handleTokenRemove: ->
        replaceDate: ->

      @dueDateRow = React.render(DueDateRow(props), $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      React.unmountComponentAtNode(@dueDateRow.getDOMNode().parentNode)

  test 'renders', ->
    ok @dueDateRow.isMounted()

  test 'returns a remove link if canDelete', ->
    ok @dueDateRow.removeLinkIfNeeded()

  module 'DueDateRow with realistic props and canDelete false',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      props =
        overrides: [
          {get: ((attr) -> {course_section_id: 1 }[attr])},
          {get: ((attr) -> {course_section_id: 2 }[attr])},
          {get: ((attr) -> {student_ids: [1,2,3] }[attr])},
        ]
        sections: {2: {name: "section name"}}
        students: {2: {name: "student name"}}
        dates: {}
        canDelete: false
        rowKey: "nullnullnull"
        validDropdownOptions: []
        currentlySearching: false
        allStudentsFetched: true
        handleDelete: ->
        defaultSectionNamer: ->
        handleTokenAdd: ->
        handleTokenRemove: ->
        replaceDate: ->

      @dueDateRow = React.render(DueDateRow(props), $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      React.unmountComponentAtNode(@dueDateRow.getDOMNode().parentNode)

  test 'renders', ->
    ok @dueDateRow.isMounted()

  test 'does not return remove link if not canDelete', ->
    ok !@dueDateRow.removeLinkIfNeeded()

  test 'tokenizing ADHOC overrides works', ->
    tokens = @dueDateRow.tokenizedOverrides()
    equal 5, tokens.length
    equal 3, _.filter(tokens, (t) -> t["type"] == "student").length

  test 'tokenizing section overrides works', ->
    tokens = @dueDateRow.tokenizedOverrides()
    equal 5, tokens.length
    equal 2, _.filter(tokens, (t) -> t["type"] == "section").length

  test 'section tokens are given their proper name if loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "section name")
    ok !!token

  test 'student tokens are their proper name if loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "student name")
    ok !!token

  test 'student tokens are given the name "Loading..." if they havent loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "Loading...")
    ok !!token

