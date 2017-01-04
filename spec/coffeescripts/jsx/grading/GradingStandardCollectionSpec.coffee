define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'underscore'
  'jsx/grading/gradingStandardCollection'
  'jsx/grading/gradingStandard'
], (React, ReactDOM, TestUtils, $, _, GradingStandardCollection, GradingStandard) ->

  Simulate = TestUtils.Simulate

  module 'GradingStandardCollection',
    setup: ->
      @stub($, 'flashMessage', ->)
      @stub($, 'flashError', ->)
      @stub(window, 'confirm', -> )
      @server = sinon.fakeServer.create()
      ENV.current_user_roles = ["admin", "teacher"]
      ENV.GRADING_STANDARDS_URL = "/courses/1/grading_standards"
      ENV.DEFAULT_GRADING_STANDARD_DATA = [
        ['A', 0.94], ['A-', 0.90], ['B+', 0.87],
        ['B', 0.84], ['B-', 0.80], ['C+', 0.77],
        ['C', 0.74], ['C-', 0.70], ['D+', 0.67],
        ['D', 0.64], ['D-', 0.61], ['F', 0.0]
      ]
      @processedDefaultData = [
        ['A', 94], ['A-', 90], ['B+', 87],
        ['B', 84], ['B-', 80], ['C+', 77],
        ['C', 74], ['C-', 70], ['D+', 67],
        ['D', 64], ['D-', 61], ['F', 0]
      ]
      @indexData = [
        grading_standard:
          id: 1
          title: "Hard to Fail"
          data: [['A', 0.20], ['F', 0.0]]
          permissions:
            read: true
            manage: true
      ]
      @processedIndexData = [
        grading_standard:
          id: 1
          title: "Hard to Fail"
          data: [['A', 20], ['F', 0]]
          permissions:
            read: true
            manage: true
      ]
      @updatedStandard =
        grading_standard:
          title: "Updated Standard"
          id: 1
          data: [['A', 0.90], ['F', 0.50]]
          permissions:
            read: true
            manage: true
      @createdStandard =
        grading_standard:
          title: "Newly Created Standard"
          id: 2
          data: ENV.DEFAULT_GRADING_STANDARD_DATA
          permissions:
            read: true
            manage: true
      @server.respondWith "GET", ENV.GRADING_STANDARDS_URL + ".json", [200, {"Content-Type":"application/json"}, JSON.stringify @indexData]
      @server.respondWith "POST", ENV.GRADING_STANDARDS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @createdStandard]
      @server.respondWith "PUT", ENV.GRADING_STANDARDS_URL + "/1", [200, {"Content-Type":"application/json"}, JSON.stringify @updatedStandard]
      GradingStandardCollectionElement = React.createElement(GradingStandardCollection)
      @gradingStandardCollection = TestUtils.renderIntoDocument(GradingStandardCollectionElement)
      @server.respond()

    teardown: ->
      ReactDOM.unmountComponentAtNode(@gradingStandardCollection.getDOMNode().parentNode)
      ENV.current_user_roles = null
      ENV.GRADING_STANDARDS_URL = null
      ENV.DEFAULT_GRADING_STANDARD_DATA = null
      @server.restore()

  test 'gets the standards data from the grading standards controller, and multiplies data values by 100 (i.e. .20 becomes 20)', ->
    deepEqual @gradingStandardCollection.state.standards, @processedIndexData

  test 'getStandardById gets the correct standard by its id', ->
    deepEqual @gradingStandardCollection.getStandardById(1), _.first(@processedIndexData)

  test 'getStandardById returns undefined for a id that doesn\'t match a standard', ->
    deepEqual @gradingStandardCollection.getStandardById(10), undefined

  test 'adds a new standard when the add button is clicked', ->
    deepEqual @gradingStandardCollection.state.standards.length, 1
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    deepEqual @gradingStandardCollection.state.standards.length, 2

  test 'adds the default standard when the add button is clicked', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    newStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    deepEqual newStandard.data, @processedDefaultData


  test 'does not save the new standard on the backend when the add button is clicked', ->
    saveGradingStandard = @spy(@gradingStandardCollection, 'saveGradingStandard')
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    ok saveGradingStandard.notCalled

  test 'standardNotCreated returns true for a new standard that hasn\'t been saved yet', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    newStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    ok @gradingStandardCollection.standardNotCreated(newStandard)

  test 'standardNotCreated returns false for standards that have been saved on the backend', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    unsavedStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    ok @gradingStandardCollection.standardNotCreated(unsavedStandard)
    @gradingStandardCollection.saveGradingStandard(unsavedStandard)
    @server.respond()
    savedStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    deepEqual savedStandard.title, "Newly Created Standard"
    deepEqual @gradingStandardCollection.standardNotCreated(savedStandard), false

  test 'saveGradingStandard updates an already-saved grading standard', ->
    savedStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    @gradingStandardCollection.saveGradingStandard(savedStandard)
    @server.respond()
    updatedStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    deepEqual updatedStandard.title, "Updated Standard"

  test 'setEditingStatus removes the standard if the user clicks "Cancel" on a not-yet-saved standard', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    deepEqual @gradingStandardCollection.state.standards.length, 2
    deepEqual _.first(@gradingStandardCollection.state.standards).grading_standard.data, @processedDefaultData
    @gradingStandardCollection.setEditingStatus(-1, false)
    deepEqual @gradingStandardCollection.state.standards.length, 1
    deepEqual _.first(@gradingStandardCollection.state.standards).grading_standard.data, _.first(@processedIndexData).grading_standard.data

  test 'setEditingStatus sets the editing status to true on a saved standard, when true is passed in', ->
    @gradingStandardCollection.setEditingStatus(1, true)
    deepEqual _.first(@gradingStandardCollection.state.standards).editing, true

  test 'setEditingStatus sets the editing status to false on a saved standard, when false is passed in', ->
    @gradingStandardCollection.setEditingStatus(1, false)
    deepEqual _.first(@gradingStandardCollection.state.standards).editing, false

  test 'anyStandardBeingEdited returns false if no standards are being edited', ->
    deepEqual @gradingStandardCollection.anyStandardBeingEdited(), false

  test 'anyStandardBeingEdited returns true after the user clicks "Add grading scheme"', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    deepEqual @gradingStandardCollection.anyStandardBeingEdited(), true

  test 'anyStandardBeingEdited returns false if the user clicks "Add grading scheme" and then clicks "Cancel"', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    @gradingStandardCollection.setEditingStatus(-1, false)
    deepEqual @gradingStandardCollection.anyStandardBeingEdited(), false

  test 'anyStandardBeingEdited returns false if the user clicks "Add grading scheme" and then clicks "Save"', ->
    Simulate.click(@gradingStandardCollection.refs.addButton.getDOMNode())
    unsavedStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    @gradingStandardCollection.saveGradingStandard(unsavedStandard)
    @server.respond()
    deepEqual @gradingStandardCollection.anyStandardBeingEdited(), false

  test 'anyStandardBeingEdited returns true if any standards are being edited', ->
    @gradingStandardCollection.setEditingStatus(1, true)
    deepEqual @gradingStandardCollection.anyStandardBeingEdited(), true

  test 'roundToTwoDecimalPlaces rounds correctly', ->
    deepEqual @gradingStandardCollection.roundToTwoDecimalPlaces(20), 20.0
    deepEqual @gradingStandardCollection.roundToTwoDecimalPlaces(20.7), 20.7
    deepEqual @gradingStandardCollection.roundToTwoDecimalPlaces(20.23), 20.23
    deepEqual @gradingStandardCollection.roundToTwoDecimalPlaces(20.234123), 20.23
    deepEqual @gradingStandardCollection.roundToTwoDecimalPlaces(20.23523), 20.24

  test 'dataFormattedForCreate formats the grading standard correctly for the create AJAX call', ->
    gradingStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    deepEqual @gradingStandardCollection.dataFormattedForCreate(gradingStandard),
      grading_standard:
        id: 1
        title: "Hard to Fail"
        data: [["A", 0.2], ["F", 0.0]]
        permissions:
          manage: true
          read: true

  test 'dataFormattedForUpdate formats the grading standard correctly for the update AJAX call', ->
    gradingStandard = _.first(@gradingStandardCollection.state.standards).grading_standard
    deepEqual @gradingStandardCollection.dataFormattedForUpdate(gradingStandard),
      grading_standard:
        title: "Hard to Fail"
        standard_data:
          scheme_0:
            name: "A"
            value: 20.0
          scheme_1:
            name: "F"
            value: 0.0

  test 'hasAdminOrTeacherRole returns true if the user has an admin or teacher role', ->
    ENV.current_user_roles = []
    deepEqual @gradingStandardCollection.hasAdminOrTeacherRole(), false
    ENV.current_user_roles = ["teacher"]
    deepEqual @gradingStandardCollection.hasAdminOrTeacherRole(), true
    ENV.current_user_roles = ["admin"]
    deepEqual @gradingStandardCollection.hasAdminOrTeacherRole(), true
    ENV.current_user_roles = ["teacher", "admin"]
    deepEqual @gradingStandardCollection.hasAdminOrTeacherRole(), true

  test 'disables the "Add grading scheme" button if any standards are being edited', ->
    @gradingStandardCollection.setEditingStatus(1, true)
    ok @gradingStandardCollection.getAddButtonCssClasses().indexOf("disabled") > -1

  test 'disables the "Add grading scheme" button if the user is not a teacher or admin', ->
    ENV.current_user_roles = []
    ok @gradingStandardCollection.getAddButtonCssClasses().indexOf("disabled") > -1

  test 'shows a message that says "No grading schemes to display" if there are no standards', ->
    deepEqual @gradingStandardCollection.refs.noSchemesMessage, undefined
    @gradingStandardCollection.setState({standards: []})
    ok @gradingStandardCollection.refs.noSchemesMessage

  test 'deleteGradingStandard calls confirmDelete', ->
    confirmDelete = @spy($.fn, "confirmDelete")
    deleteButton = @gradingStandardCollection.refs.gradingStandard1.refs.deleteButton.getDOMNode()
    Simulate.click(deleteButton)
    ok confirmDelete.calledOnce
