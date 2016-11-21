define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/DueDateTokenWrapper'
  'jsx/due_dates/OverrideStudentStore'
  'helpers/fakeENV'
], (React, ReactDOM, {Simulate, SimulateNative}, _, DueDateTokenWrapper, OverrideStudentStore, fakeENV) ->

  module 'DueDateTokenWrapper',
    setup: ->
      fakeENV.setup(context_asset_string = "course_1")
      @clock = sinon.useFakeTimers()
      @props =
        tokens: [
          {id: "1", name: "Atilla", student_id: "3", type: "student"},
          {id: "2", name: "Huns", course_section_id: "4", type: "section"},
          {id: "3", name: "Reading Group 3", group_id: "3", type: "group"}
        ]
        potentialOptions: [
          {course_section_id: "1", name: "Patricians"},
          {id: "1", name: "Seneca The Elder"},
          {id: "2", name: "Agrippa"},
          {id: "3", name: "Publius"},
          {id: "4", name: "Scipio"},
          {id: "5", name: "Baz"},
          {course_section_id: "2", name: "Plebs | [ $"}, # named strangely to test regex
          {course_section_id: "3", name: "Foo"},
          {course_section_id: "4", name: "Bar"},
          {course_section_id: "5", name: "Baz"},
          {course_section_id: "6", name: "Qux"},
          {group_id: "1", name: "Reading Group One"},
          {group_id: "2", name: "Reading Group Two"},
          {noop_id: "1", name: "Mastery Paths"}
        ]
        handleTokenAdd: ->
        handleTokenRemove: ->
        defaultSectionNamer: ->
        allStudentsFetched: false
        currentlySearching: false
        rowKey: "nullnullnull"
        disabled: false

      @mountPoint = $('<div>').appendTo('body')[0]
      DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, @props)
      @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)
      @TokenInput = @DueDateTokenWrapper.refs.TokenInput

    teardown: ->
      @clock.restore()
      ReactDOM.unmountComponentAtNode(@mountPoint)
      fakeENV.teardown()

  test 'renders', ->
    ok @DueDateTokenWrapper.isMounted()

  test 'renders a TokenInput', ->
    ok @TokenInput.isMounted()

  test 'call to fetchStudents on input changes', ->
    fetch = @stub(@DueDateTokenWrapper, "safeFetchStudents")
    @DueDateTokenWrapper.handleInput("to")
    equal fetch.callCount, 1
    @DueDateTokenWrapper.handleInput("tre")
    equal fetch.callCount, 2

  test 'if a user types handleInput filters the options', ->
    # having debouncing enabled for fetching makes tests hard to
    # contend with.
    @DueDateTokenWrapper.removeTimingSafeties()

    # 1 prompt, 3 sections, 4 students, 2 groups, 3 headers, 1 Noop = 14
    equal @DueDateTokenWrapper.optionsForMenu().length, 14

    @DueDateTokenWrapper.handleInput("scipio")
    # 0 sections, 1 student, 1 header = 2
    equal @DueDateTokenWrapper.optionsForMenu().length, 2

  test 'menu options are grouped by type', ->
    equal @DueDateTokenWrapper.optionsForMenu()[1].props.value, "course_section"
    equal @DueDateTokenWrapper.optionsForMenu()[2].props.value, "Patricians"
    equal @DueDateTokenWrapper.optionsForMenu()[5].props.value, "group"
    equal @DueDateTokenWrapper.optionsForMenu()[6].props.value, "Reading Group One"
    equal @DueDateTokenWrapper.optionsForMenu()[8].props.value, "student"
    equal @DueDateTokenWrapper.optionsForMenu()[9].props.value, "Seneca The Elder"

  test 'handleTokenAdd is called when a token is added', ->
    addProp = @stub(@props, "handleTokenAdd")
    DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, @props)
    @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)
    @DueDateTokenWrapper.handleTokenAdd("sene")
    ok addProp.calledOnce
    addProp.restore()

  test 'handleTokenRemove is called when a token is removed', ->
    removeProp = @stub(@props, "handleTokenRemove")
    DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, @props)
    @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)
    @DueDateTokenWrapper.handleTokenRemove("sene")
    ok removeProp.calledOnce
    removeProp.restore()

  test 'findMatchingOption can match a string with a token', ->
    foundToken = @DueDateTokenWrapper.findMatchingOption("sci")
    equal foundToken["name"], "Scipio"
    foundToken = @DueDateTokenWrapper.findMatchingOption("pub")
    equal foundToken["name"], "Publius"

  test 'findMatchingOption can handle strings with weird characters', ->
    foundToken = @DueDateTokenWrapper.findMatchingOption("Plebs | [")
    equal foundToken["name"], "Plebs | [ $"

  test 'findMatchingOption can match characters in the middle of a string', ->
    foundToken = @DueDateTokenWrapper.findMatchingOption("The Elder")
    equal foundToken["name"], "Seneca The Elder"

  test 'findMatchingOption can match tokens by properties', ->
    fakeOption = { props: { set_props: { name: "Baz", course_section_id: "5"} } }
    foundToken = @DueDateTokenWrapper.findMatchingOption("Baz", fakeOption)
    equal foundToken["course_section_id"], "5"

  test 'hidingValidMatches updates as matching tag number changes', ->
    ok @DueDateTokenWrapper.hidingValidMatches()

    @DueDateTokenWrapper.handleInput("scipio")
    ok !@DueDateTokenWrapper.hidingValidMatches()

  test 'overrideTokenAriaLabel method', ->
    equal @DueDateTokenWrapper.overrideTokenAriaLabel('group X'), "Currently assigned to group X, click to remove"

  module 'disabled DueDateTokenWrapper',
    setup: ->
      fakeENV.setup(context_asset_string = "course_1")
      props =
        tokens: [{id: "1", name: "Atilla", student_id: "3", type: "student"}]
        potentialOptions: [{course_section_id: "1", name: "Patricians"}]
        handleTokenAdd: ->
        handleTokenRemove: ->
        defaultSectionNamer: ->
        allStudentsFetched: false
        currentlySearching: false
        rowKey: "wat"
        disabled: true

      @mountPoint = $('<div>').appendTo('body')[0]
      DueDateTokenWrapperElement = React.createElement(DueDateTokenWrapper, props)
      @DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, @mountPoint)

    teardown: ->
      ReactDOM.unmountComponentAtNode(@mountPoint)
      fakeENV.teardown()

  test 'renders a readonly token input', ->
    ok @DueDateTokenWrapper.refs.DisabledTokenInput
