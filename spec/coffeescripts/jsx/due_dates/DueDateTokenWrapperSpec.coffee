define [
  'react'
  'underscore'
  'jsx/due_dates/DueDateTokenWrapper'
  'jsx/due_dates/OverrideStudentStore'
  'helpers/fakeENV'
], (React, _, DueDateTokenWrapper, OverrideStudentStore, fakeENV) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'DueDateTokenWrapper',
    setup: ->
      fakeENV.setup(context_asset_string = "course_1")
      @clock = sinon.useFakeTimers()
      @sandbox = sinon.sandbox.create()
      props =
        tokens: [
          {name: "Atilla", student_id: "3", type: "student"},
          {name: "Huns", course_section_id: "4", type: "section"},
        ]
        potentialOptions: [
          {course_section_id: "1", name: "Patricians"},
          {id: "1", name: "Seneca The Elder"},
          {id: "2", name: "Agrippa"},
          {id: "3", name: "Publius"},
          {id: "4", name: "Scipio"},
          {course_section_id: "2", name: "Plebs | [ $"} # named strangely to test regex
        ]
        handleTokenAdd: ->
        handleTokenRemove: ->
        defaultSectionNamer: ->
        allStudentsFetched: false
        currentlySearching: false
        rowKey: "nullnullnull"

      @DueDateTokenWrapper = React.render(DueDateTokenWrapper(props), $('<div>').appendTo('body')[0])
      @TokenInput = @DueDateTokenWrapper.refs.TokenInput

    teardown: ->
      @clock.restore()
      @sandbox.restore()
      React.unmountComponentAtNode(@DueDateTokenWrapper.getDOMNode().parentNode)
      fakeENV.teardown()

  test 'renders', ->
    ok @DueDateTokenWrapper.isMounted()

  test 'renders a TokenInput', ->
    ok @TokenInput.isMounted()

  test 'call to fetchStudents on input changes', ->
    fetch = @sandbox.stub(@DueDateTokenWrapper, "fetchStudents")
    @DueDateTokenWrapper.handleInput("to")
    equal fetch.callCount, 1
    @DueDateTokenWrapper.handleInput("tre")
    equal fetch.callCount, 2

  test 'if a user types handleInput filters the options', ->
    # 1 prompt, 2 sections, 4 students, 2 headers = 8
    equal @DueDateTokenWrapper.optionsForMenu().length, 9

    @DueDateTokenWrapper.handleInput("scipio")
    @clock.tick(2000)
    # 0 sections, 1 student, 1 header = 2
    equal @DueDateTokenWrapper.optionsForMenu().length, 2

  test 'menu options are grouped by type', ->
    equal @DueDateTokenWrapper.optionsForMenu()[1].props.value, "course_section"
    equal @DueDateTokenWrapper.optionsForMenu()[2].props.value, "Patricians"
    equal @DueDateTokenWrapper.optionsForMenu()[4].props.value, "student"
    equal @DueDateTokenWrapper.optionsForMenu()[5].props.value, "Seneca The Elder"

  test 'handleTokenAdd is called when a token is added', ->
    addProp = @sandbox.stub(@DueDateTokenWrapper.props, "handleTokenAdd")
    @DueDateTokenWrapper.handleTokenAdd("sene")
    ok addProp.calledOnce

  test 'handleTokenRemove is called when a token is removed', ->
    removeProp = @sandbox.stub(@DueDateTokenWrapper.props, "handleTokenRemove")
    @DueDateTokenWrapper.handleTokenRemove("sene")
    ok removeProp.calledOnce

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
