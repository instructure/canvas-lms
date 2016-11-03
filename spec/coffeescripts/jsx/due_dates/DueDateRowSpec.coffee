define [
  'react'
  'react-dom'
  'underscore'
  'jsx/due_dates/DueDateRow'
  'helpers/fakeENV'
], (React, ReactDOM, _, DueDateRow, fakeENV) ->

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

      DueDateRowElement = React.createElement(DueDateRow, props)
      @dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(@dueDateRow.getDOMNode().parentNode)

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
          {get: ((attr) -> {group_id: 2 }[attr])}
        ]
        sections: {2: {name: "section name"}}
        students: {2: {name: "student name"}}
        groups: {2: {name: "group name"}}
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

      DueDateRowElement = React.createElement(DueDateRow, props)
      @dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(@dueDateRow.getDOMNode().parentNode)

  test 'renders', ->
    ok @dueDateRow.isMounted()

  test 'does not return remove link if not canDelete', ->
    ok !@dueDateRow.removeLinkIfNeeded()

  test 'tokenizing ADHOC overrides works', ->
    tokens = @dueDateRow.tokenizedOverrides()
    equal 6, tokens.length
    equal 3, _.filter(tokens, (t) -> t["type"] == "student").length

  test 'tokenizing section overrides works', ->
    tokens = @dueDateRow.tokenizedOverrides()
    equal 6, tokens.length
    equal 2, _.filter(tokens, (t) -> t["type"] == "section").length

  test 'tokenizing group overrides works', ->
    tokens = @dueDateRow.tokenizedOverrides()
    equal 6, tokens.length
    equal 1, _.filter(tokens, (t) -> t["type"] == "group").length

  test 'section tokens are given their proper name if loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "section name")
    ok !!token

  test 'student tokens are their proper name if loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "student name")
    ok !!token

  test 'group tokens are their proper name if loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "group name")
    ok !!token

  test 'student tokens are given the name "Loading..." if they havent loaded', ->
    tokens = @dueDateRow.tokenizedOverrides()
    token = _.find(tokens, (t) -> t["name"] == "Loading...")
    ok !!token
