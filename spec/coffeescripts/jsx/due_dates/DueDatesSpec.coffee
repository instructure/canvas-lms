define [
  'react'
  'react-dom'
  'underscore'
  'jsx/due_dates/DueDates'
  'jsx/due_dates/OverrideStudentStore'
  'jsx/due_dates/StudentGroupStore'
  'compiled/models/AssignmentOverride'
  'helpers/fakeENV'
], (React, ReactDOM, _, DueDates, OverrideStudentStore, StudentGroupStore, AssignmentOverride, fakeENV) ->

  findAllByTag = React.addons.TestUtils.scryRenderedDOMComponentsWithTag
  findAllByClass = React.addons.TestUtils.scryRenderedDOMComponentsWithClass

  module 'DueDates',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @override1 = new AssignmentOverride name: "Plebs", course_section_id: "1", due_at: null
      @override2 = new AssignmentOverride name: "Patricians", course_section_id: "2", due_at: "2015-04-05"
      @override3 = new AssignmentOverride name: "Students", student_ids: ["1","3"], due_at: null
      @override4 = new AssignmentOverride name: "Reading Group One", group_id: "1", due_at: null
      @override5 = new AssignmentOverride name: "Reading Group Two", group_id: "2", due_at: "2015-05-05"

      props =
        overrides: [@override1, @override2, @override3, @override4, @override5]
        defaultSectionId: '0'
        sections: [{attributes: {id: 1, name: "Plebs"}},{attributes: {id: 2, name: "Patricians"}}]
        students: {1:{id: "1", name: "Scipio Africanus"}, 2: {id: "2", name: "Cato The Elder"}, 3:{id: 3, name: "Publius Publicoa"}}
        groups: {1:{id: "1", name: "Reading Group One"}, 2: {id: "2", name: "Reading Group Two"}}
        overrideModel: AssignmentOverride
        syncWithBackbone: ->
        multipleGradingPeriodsEnabled: false
        gradingPeriods: []
        isOnlyVisibleToOverrides: false
        dueAt: null

      @syncWithBackboneStub = @stub(props, 'syncWithBackbone')
      DueDatesElement = React.createElement(DueDates, props)
      @dueDates = ReactDOM.render(DueDatesElement, $('<div>').appendTo('body')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDates).parentNode)
      fakeENV.teardown()

  test 'renders', ->
    ok @dueDates.isMounted()

  test 'formats sectionHash properly', ->
    equal @dueDates.state.sections[1]["name"], "Plebs"

  test 'overrides with different dates are sorted into separate rows', ->
    sortedOverrides = _.map(@dueDates.state.rows, (r)-> r.overrides)
    ok _.contains(sortedOverrides[0], @override1)
    ok _.contains(sortedOverrides[0], @override3)
    ok _.contains(sortedOverrides[0], @override4)
    ok _.contains(sortedOverrides[1], @override2)
    ok _.contains(sortedOverrides[2], @override5)

  test 'syncs with backbone on update', ->
    initialCount = @syncWithBackboneStub.callCount
    @dueDates.setState(rows: {})
    equal @syncWithBackboneStub.callCount, initialCount + 1

  test 'will add multiple rows of overrides if AddRow is called', ->
    equal @dueDates.sortedRowKeys().length, 3
    @dueDates.addRow()
    equal @dueDates.sortedRowKeys().length, 4
    @dueDates.addRow()
    equal @dueDates.sortedRowKeys().length, 5

  test 'will filter out picked sections from validDropdownOptions', ->
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

  test 'defaultSection namer shows Everyone Else if a section or student is selected', ->
    equal @dueDates.defaultSectionNamer('0'), "Everyone Else"

  test 'defaultSection namer shows Everyone if no token is selected', ->
    @dueDates.setState(rows: {})
    equal @dueDates.defaultSectionNamer('0'), "Everyone"

  test 'can replace the dates of a row properly', ->
    initialDueAts = _.map @dueDates.state.rows, (row) ->
      row.dates.due_at
    ok !_.all(initialDueAts, (due_at_val) -> due_at_val == null)
    _.each @dueDates.sortedRowKeys(), (key) =>
      @dueDates.replaceDate(key, "due_at", null)
    updatedDueAts = _.map @dueDates.state.rows, (row) ->
      row.dates.due_at
    ok _.all(updatedDueAts, (due_at_val) -> due_at_val == null)

  test 'focuses on the new row begin added', ->
    @spy(@dueDates, 'focusRow')
    @dueDates.addRow()
    equal @dueDates.focusRow.callCount, 1

  test 'filters available groups based on selected group category', ->
    groups = [
      {id: "3", group_category_id: "1"},
      {id: "4", group_category_id: "2"}
    ]
    StudentGroupStore.setSelectedGroupSet(null)
    StudentGroupStore.addGroups(groups)
    ok !_.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.group_id), "3")
    ok !_.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.group_id), "4")
    StudentGroupStore.setSelectedGroupSet("1")
    ok  _.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.group_id), "3")
    ok !_.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.group_id), "4")
    StudentGroupStore.setSelectedGroupSet("2")
    ok !_.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.group_id), "3")
    ok  _.contains(@dueDates.validDropdownOptions().map( (opt) -> opt.group_id), "4")

  test 'includes the persisted state on the overrides', ->
    attributes = _.keys(@dueDates.getAllOverrides()[0].attributes)
    ok _.contains(attributes, "persisted")

  module 'DueDates with Multiple Grading Periods enabled',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      ENV.current_user_roles = ["teacher"]
      overrides = [
        new AssignmentOverride
          id: "70"
          assignment_id: "64"
          title: "Section 1"
          due_at: "2014-07-16T05:59:59Z"
          all_day: true
          all_day_date: "2014-07-16"
          unlock_at: null
          lock_at: null
          course_section_id: "19"
          due_at_overridden: true
          unlock_at_overridden: true
          lock_at_overridden: true

        new AssignmentOverride
          id: "71"
          assignment_id: "64"
          title: "1 student"
          due_at: "2014-07-17T05:59:59Z"
          all_day: true
          all_day_date: "2014-07-17"
          unlock_at: null
          lock_at: null
          student_ids: ["2"]
          due_at_overridden: true
          unlock_at_overridden: true
          lock_at_overridden: true

        new AssignmentOverride
          id: "72"
          assignment_id: "64"
          title: "1 student"
          due_at: "2014-07-18T05:59:59Z"
          all_day: true
          all_day_date: "2014-07-18"
          unlock_at: null
          lock_at: null
          student_ids: ["4"]
          due_at_overridden: true
          unlock_at_overridden: true
          lock_at_overridden: true
      ]

      sections = [
        { attributes: { id: "0", name: "Everyone" } }
        { attributes: { id: "19", name: "Section 1", start_at: null, end_at: null, override_course_and_term_dates: null } }
        { attributes: { id: "4", name: "Section 2", start_at: null, end_at: null, override_course_and_term_dates: null } }
        { attributes: { id: "7", name: "Section 3", start_at: null, end_at: null, override_course_and_term_dates: null } }
        { attributes: { id: "8", name: "Section 4", start_at: null, end_at: null, override_course_and_term_dates: null } }
      ]

      gradingPeriods = [
        {
          id: "101",
          title: "Account Closed Period",
          startDate: new Date("2014-07-01T06:00:00.000Z"),
          endDate: new Date("2014-08-31T06:00:00.000Z"),
          closeDate: new Date("2014-08-31T06:00:00.000Z"),
          isLast: false,
          isClosed: true
        }
        {
          id: "127",
          title: "Account Open Period",
          startDate: new Date("2014-09-01T06:00:00.000Z"),
          endDate: new Date("2014-12-15T07:00:00.000Z"),
          closeDate: new Date("2014-12-15T07:00:00.000Z"),
          isLast: true,
          isClosed: false
        }
      ]

      students =
        1:
          id: "1"
          name: "Scipio Africanus"
          sections: ["19"]
          group_ids: []
        2:
          id: "2"
          name: "Cato The Elder"
          sections: ["4"]
          group_ids: []
        3:
          id: "3"
          name: "Publius Publicoa"
          sections: ["4"]
          group_ids: []
        4:
          id: "4"
          name: "Louie Anderson"
          sections: ["8"]
          group_ids: []

      @stub(OverrideStudentStore, 'getStudents', -> students)
      @stub(OverrideStudentStore, 'currentlySearching', -> false)
      @stub(OverrideStudentStore, 'allStudentsFetched', -> true)

      props =
        overrides: overrides
        overrideModel: AssignmentOverride
        defaultSectionId: '0'
        sections: sections
        groups: {1:{id: "1", name: "Reading Group One"}, 2: {id: "2", name: "Reading Group Two"}}
        syncWithBackbone: ->
        multipleGradingPeriodsEnabled: true
        gradingPeriods: gradingPeriods
        isOnlyVisibleToOverrides: true
        dueAt: null

      @syncWithBackboneStub = @stub(props, 'syncWithBackbone')
      DueDatesElement = React.createElement(DueDates, props)
      @dueDates = ReactDOM.render(DueDatesElement, $('<div>').appendTo('body')[0])
      @dueDates.handleStudentStoreChange()
      @dropdownOptions = @dueDates.validDropdownOptions().map((opt) -> opt.name)

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDates).parentNode)
      fakeENV.teardown()

  test 'sets inputs to readonly for overrides in closed grading periods', ->
    inputs = findAllByTag(@dueDates, "input")
    ok _.all(inputs, (input) -> input.readOnly)

  test 'disables the datepicker button for overrides in closed grading periods', ->
    buttons = findAllByClass(@dueDates, "Button--icon-action")
    ok _.all(buttons, (button) -> button.className.match("disabled"))

  test 'dropdown options do not include sections assigned in closed periods', ->
    notOk _.contains(@dropdownOptions, "Section 1")

  test 'dropdown options do not include students assigned in closed periods', ->
    notOk _.contains(@dropdownOptions, "Cato The Elder")

  test 'dropdown options do not include sections with any students assigned in closed periods', ->
    ok _.isEmpty(_.intersection(@dropdownOptions, ["Section 2", "Section 4"]))

  test 'dropdown options do not include students whose sections are assigned in closed periods', ->
    notOk _.contains(@dropdownOptions, "Scipio Africanus")

  test 'dropdown options include sections that are not assigned in closed periods and do not have'/
  'any students assigned in closed periods', ->
    ok _.contains(@dropdownOptions, "Section 3")

  test 'dropdown options include students that do not belong to sections assigned in closed periods', ->
    ok _.contains(@dropdownOptions, "Publius Publicoa")

  module 'DueDates render callbacks',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @override = new AssignmentOverride name: "Students", student_ids: ["1", "3"], due_at: null

      @dueDates

      @props =
        overrides: [@override]
        defaultSectionId: '0'
        sections: []
        students: {"1":{id: "1", name: "Scipio Africanus"}, "3":{id: 3, name: "Publius Publicoa"}}
        overrideModel: AssignmentOverride
        syncWithBackbone: ->
        multipleGradingPeriodsEnabled: false
        gradingPeriods: []
        isOnlyVisibleToOverrides: false
        dueAt: null

    teardown: ->
      fakeENV.teardown()

  test 'fetchAdhocStudents does not fire until state is set', ->
    getInitialStateStub = @stub(DueDates.prototype, "getInitialState")
    fetchAdhocStudentsStub = @stub(OverrideStudentStore, "fetchStudentsByID")

    DueDatesElement = React.createElement(DueDates, @props)

    # provide an initial state that should not get pssed into the
    # fetchStudentsByID call
    getInitialStateStub.returns(
      rows: [{1: {overrides: {student_ids: ["18", "22"]}}}]
      students: {}
    )

    # render with the props (which should provide info for fetchStudentsByID call)
    @dueDates = ReactDOM.render(DueDatesElement, $('<div>').appendTo('body')[0])

    ok !fetchAdhocStudentsStub.calledWith(["18", "22"])
    ok fetchAdhocStudentsStub.calledWith(["1","3"])

    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDates).parentNode)
