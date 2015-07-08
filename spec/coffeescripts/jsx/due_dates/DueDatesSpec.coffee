define [
  'react'
  'underscore'
  'jsx/due_dates/DueDates'
  'compiled/models/AssignmentOverride',
  'helpers/fakeENV'
], (React, _, DueDates, AssignmentOverride, fakeENV) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'DueDates',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @override1 = new AssignmentOverride name: "Plebs", course_section_id: "1", due_at: null
      @override2 = new AssignmentOverride name: "Patricians", course_section_id: "2", due_at: "2015-04-05"
      @override3 = new AssignmentOverride name: "Students", student_ids: ["1","3"], due_at: null

      props =
        overrides: [@override1, @override2, @override3]
        defaultSectionId: 0
        sections: [{attributes: {id: 1, name: "Plebs"}},{attributes: {id: 2, name: "Patricians"}}]
        students: {1:{id: "1", name: "Scipio Africanus"}, 2: {id: "2", name: "Cato The Elder"}, 3:{id: 3, name: "Publius Publicoa"}}
        overrideModel: AssignmentOverride
        syncWithBackbone: ->

      @syncWithBackboneStub = @stub(props, 'syncWithBackbone')
      @dueDates = React.render(DueDates(props), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@dueDates.getDOMNode().parentNode)
      fakeENV.teardown()

  test 'renders', ->
    ok @dueDates.isMounted()

  test 'formats sectionHash properly', ->
    equal @dueDates.state.sections[1]["name"], "Plebs"

  test 'overrides with different dates are sorted into separate rows', ->
    sortedOverrides = _.map(@dueDates.state.rows, (r)-> r.overrides)
    ok _.contains(sortedOverrides[0], @override1)
    ok _.contains(sortedOverrides[0], @override3)
    ok _.contains(sortedOverrides[1], @override2)

  test 'syncs with backbone on update', ->
    initialCount = @syncWithBackboneStub.callCount
    @dueDates.setState(rows: {})
    equal @syncWithBackboneStub.callCount, initialCount + 1

  test 'will add multiple rows of overrides if AddRow is called', ->
    equal @dueDates.sortedRowKeys().length, 2
    @dueDates.addRow()
    equal @dueDates.sortedRowKeys().length, 3
    @dueDates.addRow()
    equal @dueDates.sortedRowKeys().length, 4

  test 'will filter out picked sections and students from validDropdownOptions', ->
    ok !_.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.name), "Patricians")
    @dueDates.setState(rows: {1: {overrides: []}})
    ok _.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.name), "Patricians")

  test 'properly removes a row', ->
    @dueDates.setState(rows: {"1":{}, "2":{}})
    equal @dueDates.sortedRowKeys().length, 2
    equal @dueDates.removeRow("2")
    equal @dueDates.sortedRowKeys().length, 1

  test 'will not allow removing the last row', ->
    @dueDates.setState(rows: {"1":{}, "2":{}})
    equal @dueDates.sortedRowKeys().length, 2
    ok @dueDates.canRemoveRow()
    equal @dueDates.removeRow("2")
    equal @dueDates.sortedRowKeys().length, 1
    ok !@dueDates.canRemoveRow()
    equal @dueDates.removeRow("1")
    equal @dueDates.sortedRowKeys().length, 1

  test 'defaultSection namer shows Everyone if no token is selected', ->
    equal @dueDates.defaultSectionNamer(0), "Everyone Else"

  test 'defaultSection namer shows Everyone Else if a section or student is selected', ->
    @dueDates.setState(rows: {})
    equal @dueDates.defaultSectionNamer(0), "Everyone"

  test 'can replace the dates of a row properly', ->
    initialDueAts = _.map @dueDates.state.rows, (row) ->
      row.dates.due_at
    ok !_.all(initialDueAts, (due_at_val) -> due_at_val == null)
    _.each @dueDates.sortedRowKeys(), (key) =>
      @dueDates.replaceDate(key, "due_at", null)
    updatedDueAts = _.map @dueDates.state.rows, (row) ->
      row.dates.due_at
    ok _.all(updatedDueAts, (due_at_val) -> due_at_val == null)
