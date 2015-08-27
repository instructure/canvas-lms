define [
  'react'
  'jsx/gradebook/grid/stores/gradebookToolbarStore'
  'underscore'
  'helpers/fakeENV'
  'compiled/userSettings'
], (React, GradebookToolbarStore, _, fakeENV, userSettings) ->

  module 'ReactGradebook.gradebookToolbarStore',
    setup: ->
      fakeENV.setup()
      @defaultOptions =
        hideStudentNames: false
        hideNotesColumn: true
        treatUngradedAsZero: false
        showAttendanceColumns: false
        arrangeColumnsBy: 'assignment_group'
        totalColumnInFront: false
        warnedAboutTotalsDisplay: false
        showTotalGradeAsPoints: false
      ENV.GRADEBOOK_OPTIONS = {}
    teardown: ->
      fakeENV.teardown()
      GradebookToolbarStore.toolbarOptions = null

  test '#getInitialState returns default options if the user does not have saved preferences', ->
    initialState = GradebookToolbarStore.getInitialState()
    propEqual(initialState, @defaultOptions)

  test '#getInitialState returns the saved preferences of the user, otherwise it returns defaults', ->
    userSettings.contextSet('hideStudentNames', true)
    userSettings.contextSet('treatUngradedAsZero', true)
    expectedState = _.defaults(
      { hideStudentNames: true, treatUngradedAsZero: true }
      @defaultOptions)
    initialState = GradebookToolbarStore.getInitialState()

    propEqual(initialState, expectedState)
    userSettings.contextRemove('hideStudentNames')
    userSettings.contextRemove('treatUngradedAsZero')

  test '#onToggleStudentNames should set toolbarOptions.hideStudentNames and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleStudentNames(true)

    deepEqual GradebookToolbarStore.toolbarOptions.hideStudentNames, true
    ok(triggerExpectation.once())

  test '#onToggleNotesColumnCompleted should set toolbarOptions.hideNotesColumn and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleNotesColumnCompleted(false)

    deepEqual GradebookToolbarStore.toolbarOptions.hideNotesColumn, false
    ok(triggerExpectation.once())

  test '#onArrangeColumnsBy should set toolbarOptions.arrangeColumnsBy and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onArrangeColumnsBy('due_date')

    deepEqual GradebookToolbarStore.toolbarOptions.arrangeColumnsBy, 'due_date'
    ok(triggerExpectation.once())

  test '#onToggleTreatUngradedAsZero should set toolbarOptions.treatUngradedAsZero and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleTreatUngradedAsZero(true)

    deepEqual GradebookToolbarStore.toolbarOptions.treatUngradedAsZero, true
    ok(triggerExpectation.once())

  test '#onToggleShowAttendanceColumns should set toolbarOptions.showAttendanceColumns and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleShowAttendanceColumns(true)

    deepEqual GradebookToolbarStore.toolbarOptions.showAttendanceColumns, true
    ok(triggerExpectation.once())

  test '#onShowTotalGradeAsPoints should set toolbarOptions.showTotalGradeAsPoints and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onShowTotalGradeAsPoints(true)

    deepEqual GradebookToolbarStore.toolbarOptions.showTotalGradeAsPoints, true
    ok(triggerExpectation.once())

  test '#onHideTotalDisplayWarning should set toolbarOptions.warnedAboutTotalsDisplay and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onHideTotalDisplayWarning(true)

    deepEqual GradebookToolbarStore.toolbarOptions.warnedAboutTotalsDisplay, true
    ok(triggerExpectation.once())
