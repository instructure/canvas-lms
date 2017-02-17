define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/DueDateRow'
  'helpers/fakeENV'
], (React, ReactDOM, {Simulate, SimulateNative}, _, DueDateRow, fakeENV) ->

  QUnit.module 'DueDateRow with empty props and canDelete true',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      props =
        overrides: []
        sections: {}
        students: {}
        dates: {}
        groups: {}
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
        inputsDisabled: false

      DueDateRowElement = React.createElement(DueDateRow, props)
      @dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDateRow).parentNode)

  test 'renders', ->
    ok @dueDateRow.isMounted()

  test 'returns a remove link if canDelete', ->
    ok @dueDateRow.removeLinkIfNeeded()

  QUnit.module 'DueDateRow with realistic props and canDelete false',
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
        inputsDisabled: false

      DueDateRowElement = React.createElement(DueDateRow, props)
      @dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDateRow).parentNode)

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

  QUnit.module 'DueDateRow with empty props and inputsDisabled true',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      props =
        overrides: []
        sections: {}
        students: {}
        dates: {}
        groups: {}
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
        inputsDisabled: true

      DueDateRowElement = React.createElement(DueDateRow, props)
      @dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDateRow).parentNode)

  test 'does not return a remove link', ->
    notOk @dueDateRow.removeLinkIfNeeded()
