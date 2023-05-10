/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import fakeENV from 'helpers/fakeENV'
import qs from 'qs'
import {map} from 'lodash'
import {
  getAssignmentColumnId,
  getAssignmentGroupColumnId,
} from 'ui/features/gradebook/react/default_gradebook/Gradebook.utils'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook - initial .gridDisplaySettings')

test('sets .filterColumnsBy.assignmentGroupId to the value from the given settings', () => {
  const gradebook = createGradebook({settings: {filter_columns_by: {assignment_group_id: '2201'}}})
  strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2201')
})

test('sets .filterColumnsBy.contextModuleId to the value from the given settings', () => {
  const gradebook = createGradebook({settings: {filter_columns_by: {context_module_id: '2601'}}})
  strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), '2601')
})

test('sets .filterColumnsBy.gradingPeriodId to the value from the given settings', () => {
  const gradebook = createGradebook({settings: {filter_columns_by: {grading_period_id: '1401'}}})
  strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1401')
})

test('sets .filterColumnsBy.sectionId to the value from the given settings', () => {
  const gradebook = createGradebook({settings: {filter_columns_by: {section_id: '2001'}}})
  strictEqual(gradebook.getFilterColumnsBySetting('sectionId'), '2001')
})

test('defaults .filterColumnsBy.assignmentGroupId to null when not present in the given settings', () => {
  const gradebook = createGradebook()
  strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), null)
})

test('defaults .filterColumnsBy.contextModuleId to null when not present in the given settings', () => {
  const gradebook = createGradebook()
  strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), null)
})

test('defaults .filterColumnsBy.gradingPeriodId to null when not present in the given settings', () => {
  const gradebook = createGradebook()
  strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), null)
})

test('defaults .filterRowsBy.sectionId to null when not present in the given settings', () => {
  const gradebook = createGradebook()
  strictEqual(gradebook.getFilterRowsBySetting('sectionId'), null)
})

test('updates partial .filterColumnsBy settings with the default values', () => {
  const gradebook = createGradebook({settings: {filter_columns_by: {assignment_group_id: '2201'}}})
  strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2201')
  strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), null)
  strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), null)
})

QUnit.module('Gradebook Column Order', suiteHooks => {
  let gradebook

  function createWithSettings(settings) {
    gradebook = createGradebook({gradebook_column_order_settings: settings})
    gradebook.setContextModules([{id: '2601', name: 'Algebra', position: 1}])
  }

  suiteHooks.beforeEach(() => {
    setFixtureHtml($fixtures)
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $fixtures.innerHTML = ''
  })

  QUnit.module('#setColumnOrder', hooks => {
    hooks.beforeEach(() => {
      createWithSettings({direction: 'descending', sortType: 'module_position'})
    })

    test('updates "direction"', () => {
      gradebook.setColumnOrder({direction: 'ascending', sortType: 'due_date'})
      equal(gradebook.gradebookColumnOrderSettings.direction, 'ascending')
    })

    test('updates "sortType"', () => {
      gradebook.setColumnOrder({direction: 'ascending', sortType: 'due_date'})
      equal(gradebook.gradebookColumnOrderSettings.sortType, 'due_date')
    })

    test('does not update "direction" when not included', () => {
      gradebook.setColumnOrder({direction: undefined, sortType: 'due_date'})
      equal(gradebook.gradebookColumnOrderSettings.direction, 'descending')
    })

    test('does not update "sortType" when "direction" is not included', () => {
      gradebook.setColumnOrder({direction: undefined, sortType: 'due_date'})
      equal(gradebook.gradebookColumnOrderSettings.sortType, 'module_position')
    })

    test('does not update "sortType" when not included', () => {
      gradebook.setColumnOrder({direction: 'ascending', sortType: undefined})
      equal(gradebook.gradebookColumnOrderSettings.sortType, 'module_position')
    })

    test('does not update "direction" when "sortType" is not included', () => {
      gradebook.setColumnOrder({direction: 'ascending', sortType: undefined})
      equal(gradebook.gradebookColumnOrderSettings.direction, 'descending')
    })

    test('updates a "sortType" of "custom"', () => {
      const originalOrder = ['assignment_2301', 'total_grade']
      gradebook.setColumnOrder({customOrder: originalOrder, sortType: 'custom'})
      equal(gradebook.gradebookColumnOrderSettings.sortType, 'custom')
    })

    test('updates "customOrder" with a "sortType" of "custom"', () => {
      const customOrder = ['assignment_2301', 'total_grade']
      gradebook.setColumnOrder({customOrder, sortType: 'custom'})
      equal(gradebook.gradebookColumnOrderSettings.customOrder, customOrder)
    })

    test('does not update "sortType" of "custom" when "customOrder" is not included', () => {
      gradebook.setColumnOrder({customOrder: undefined, sortType: 'custom'})
      equal(gradebook.gradebookColumnOrderSettings.sortType, 'module_position')
    })

    test('does not update "customOrder" when "sortType" is not included', () => {
      gradebook.setColumnOrder({
        customOrder: ['assignment_2301', 'total_grade'],
        sortType: undefined,
      })
      strictEqual(typeof gradebook.gradebookColumnOrderSettings.customOrder, 'undefined')
    })

    test('does not update "customOrder" when "sortType" is not "custom"', () => {
      const originalOrder = ['assignment_2301', 'total_grade']
      gradebook.setColumnOrder({customOrder: originalOrder, sortType: 'custom'})
      gradebook.setColumnOrder({
        customOrder: ['total_grade', 'assignment_2301'],
        sortType: 'due_date',
      })
      equal(gradebook.gradebookColumnOrderSettings.customOrder, originalOrder)
    })

    test('updates "freezeTotalGrade"', () => {
      gradebook.setColumnOrder({freezeTotalGrade: true})
      strictEqual(gradebook.gradebookColumnOrderSettings.freezeTotalGrade, true)
    })

    test('does not update "freezeTotalGrade" when not included', () => {
      gradebook.setColumnOrder({freezeTotalGrade: undefined})
      strictEqual(gradebook.gradebookColumnOrderSettings.freezeTotalGrade, false)
    })
  })

  QUnit.module('#saveColumnOrder', hooks => {
    let server

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.setColumnOrder({sortType: 'name', direction: 'ascending'})
      server = sinon.fakeServer.create({respondImmediately: true})
    })

    hooks.afterEach(() => {
      server.restore()
    })

    test('sends a request to the "gradebook custom order settings" url', () => {
      gradebook.saveColumnOrder()
      const requests = server.requests.filter(
        request => request.url === 'http://example.com/gradebook_column_order_settings_url'
      )
      strictEqual(requests.length, 1)
    })

    test('sends a POST request', () => {
      gradebook.saveColumnOrder()
      const saveRequest = server.requests.find(
        request => request.url === 'http://example.com/gradebook_column_order_settings_url'
      )
      equal(saveRequest.method, 'POST')
    })

    test('includes the column order', () => {
      gradebook.saveColumnOrder()
      const saveRequest = server.requests.find(
        request => request.url === 'http://example.com/gradebook_column_order_settings_url'
      )
      const requestBody = qs.parse(saveRequest.requestBody)
      deepEqual(
        qs.stringify(requestBody.column_order),
        qs.stringify(gradebook.gradebookColumnOrderSettings)
      )
    })

    test('does not send a request when the order setting is invalid', () => {
      gradebook.gradebookColumnOrderSettings = {sortType: 'custom'}
      gradebook.saveColumnOrder()
      const requests = server.requests.filter(
        request => request.url === 'http://example.com/gradebook_column_order_settings_url'
      )
      strictEqual(requests.length, 0)
    })
  })

  QUnit.module('#saveCustomColumnOrder', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'},
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)

      gradebook.setColumnOrder({sortType: 'name', direction: 'ascending'})
      sinon.stub(gradebook, 'saveColumnOrder')
    })

    test('includes the "sortType" when storing the order', () => {
      gradebook.saveCustomColumnOrder()
      equal(gradebook.gradebookColumnOrderSettings.sortType, 'custom')
    })

    test('includes the column order when storing the order', () => {
      gradebook.saveCustomColumnOrder()
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gradebook.gradebookColumnOrderSettings.customOrder, expectedOrder)
    })

    test('saves the column order', () => {
      gradebook.saveCustomColumnOrder()
      strictEqual(gradebook.saveColumnOrder.callCount, 1)
    })

    test('saves the column order after setting the new settings', () => {
      gradebook.saveColumnOrder.callsFake(() => {
        equal(gradebook.gradebookColumnOrderSettings.sortType, 'custom')
      })
      gradebook.saveCustomColumnOrder()
    })
  })

  QUnit.module('#freezeTotalGradeColumn', hooks => {
    let server
    let options

    hooks.beforeEach(() => {
      server = sinon.fakeServer.create({respondImmediately: true})
      options = {gradebook_column_order_settings_url: 'gradebook_column_order_setting_url'}
      server.respondWith('POST', options.gradebook_column_order_settings_url, [
        200,
        {'Content-Type': 'application/json'},
        '{}',
      ])
      gradebook = createGradebook(options)
      gradebook.setColumnOrder({freezeTotalGrade: false})
      sinon.stub(gradebook, 'saveColumnOrder')
      sinon.stub(gradebook, 'updateGrid')
      sinon.stub(gradebook, 'updateColumnHeaders')
    })

    hooks.afterEach(() => {
      server.restore()
    })

    test('sets the total grade column as frozen', () => {
      gradebook.freezeTotalGradeColumn()
      strictEqual(gradebook.gradebookColumnOrderSettings.freezeTotalGrade, true)
    })

    test('saves column order', () => {
      gradebook.freezeTotalGradeColumn()
      strictEqual(gradebook.saveColumnOrder.callCount, 1)
    })

    test('saves column order after setting the total grade column as frozen', () => {
      gradebook.saveColumnOrder.callsFake(() => {
        strictEqual(gradebook.gradebookColumnOrderSettings.freezeTotalGrade, true)
      })
      gradebook.freezeTotalGradeColumn()
    })

    test('updates the grid', () => {
      gradebook.freezeTotalGradeColumn()
      strictEqual(gradebook.updateGrid.callCount, 1)
    })

    test('updates column headers', () => {
      gradebook.freezeTotalGradeColumn()
      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
    })

    test('calls scrollToStart', () => {
      const scrollToStartStub = sinon.stub(
        gradebook.gradebookGrid.gridSupport.columns,
        'scrollToStart'
      )
      gradebook.freezeTotalGradeColumn()
      strictEqual(scrollToStartStub.callCount, 1)
    })
  })

  QUnit.module('#moveTotalGradeColumnToEnd', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.setColumnOrder({freezeTotalGrade: true})
      sinon.stub(gradebook, 'saveColumnOrder')
      sinon.stub(gradebook, 'saveCustomColumnOrder')
      sinon.stub(gradebook, 'updateGrid')
      sinon.stub(gradebook, 'updateColumnHeaders')
    })

    test('sets the total grade column as not frozen', () => {
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(gradebook.gradebookColumnOrderSettings.freezeTotalGrade, false)
    })

    test('saves column order when not using a custom order', () => {
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(gradebook.saveColumnOrder.callCount, 1)
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 0)
    })

    test('saves custom column order when using a custom order', () => {
      gradebook.setColumnOrder({
        customOrder: ['assignment_2301', 'total_grade'],
        sortType: 'custom',
      })
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(gradebook.saveColumnOrder.callCount, 0)
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 1)
    })

    test('saves column order after setting the total grade column as not frozen', () => {
      gradebook.saveColumnOrder.callsFake(() => {
        strictEqual(gradebook.gradebookColumnOrderSettings.freezeTotalGrade, false)
      })
      gradebook.moveTotalGradeColumnToEnd()
    })

    test('updates the grid', () => {
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(gradebook.updateGrid.callCount, 1)
    })

    test('updates column headers', () => {
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
    })

    test('calls scrollToEnd', () => {
      const scrollToEndStub = sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'scrollToEnd')
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(scrollToEndStub.callCount, 1)
    })
  })
})

QUnit.module('Gradebook Grid Events', function (suiteHooks) {
  suiteHooks.beforeEach(function () {
    setFixtureHtml($fixtures)

    $fixtures.innerHTML += `
      <div id="example-gradebook-cell">
        <a class="student-grades-link" href="#">Student Name</a>
      </div>
-    `

    this.studentColumnHeader = {
      focusAtEnd: sinon.spy(),
      focusAtStart: sinon.spy(),
      handleKeyDown: sinon.stub(),
    }

    this.gradebook = createGradebook()
    sinon.stub(this.gradebook, 'setVisibleGridColumns')
    sinon.stub(this.gradebook, 'onGridInit')

    this.gradebook.createGrid()
    this.gradebook.setHeaderComponentRef('student', this.studentColumnHeader)
  })

  suiteHooks.afterEach(function () {
    this.gradebook.destroy()
    $fixtures.innerHTML = ''
  })

  this.triggerEvent = function (eventName, event, location) {
    return this.gradebook.gradebookGrid.gridSupport.events[eventName].trigger(event, location)
  }

  QUnit.module('onActiveLocationChanged', {
    setup() {
      this.$studentGradesLink = $fixtures.querySelector('.student-grades-link')
    },
  })

  test('sets focus on the student grades link when a "student" body cell becomes active', function () {
    const clock = sinon.useFakeTimers()
    sandbox
      .stub(this.gradebook.gradebookGrid.gridSupport.state, 'getActiveNode')
      .returns($fixtures.querySelector('#example-gradebook-cell'))
    this.triggerEvent('onActiveLocationChanged', {}, {columnId: 'student', region: 'body'})
    clock.tick(0)
    strictEqual(document.activeElement, this.$studentGradesLink)
    clock.restore()
  })

  test('does nothing when a "student" body cell without a student grades link becomes active', function () {
    const clock = sinon.useFakeTimers()
    const previousActiveElement = document.activeElement
    $fixtures.querySelector('#example-gradebook-cell').innerHTML = 'Student Name'
    sandbox
      .stub(this.gradebook.gradebookGrid.gridSupport.state, 'getActiveNode')
      .returns($fixtures.querySelector('#example-gradebook-cell'))
    this.triggerEvent('onActiveLocationChanged', {}, {columnId: 'student', region: 'body'})
    clock.tick(0)
    strictEqual(document.activeElement, previousActiveElement)
    clock.restore()
  })

  test('does not change focus when a "student" header cell becomes active', function () {
    const clock = sinon.useFakeTimers()
    this.triggerEvent('onActiveLocationChanged', {}, {columnId: 'student', region: 'header'})
    clock.tick(0)
    notEqual(document.activeElement, this.$studentGradesLink)
    clock.restore()
  })

  test('does not change focus when body cells of other columns become active', function () {
    const clock = sinon.useFakeTimers()
    this.triggerEvent('onActiveLocationChanged', {}, {columnId: 'total_grade', region: 'body'})
    clock.tick(0)
    notEqual(document.activeElement, this.$studentGradesLink)
    clock.restore()
  })

  QUnit.module('onKeyDown')

  test('calls handleKeyDown on the column header component associated with the event location', function () {
    this.triggerEvent('onKeyDown', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.handleKeyDown.callCount, 1)
  })

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onKeyDown', {}, {columnId: 'student', region: 'body'})
    strictEqual(this.studentColumnHeader.handleKeyDown.callCount, 0)
  })

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student')
    this.triggerEvent('onKeyDown', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.handleKeyDown.callCount, 0)
  })

  test('includes the event when calling handleKeyDown', function () {
    const event = {}
    this.triggerEvent('onKeyDown', event, {columnId: 'student', region: 'header'})
    const {args} = this.studentColumnHeader.handleKeyDown.lastCall
    equal(args[0], event)
  })

  test('returns the return value of the handled event', function () {
    this.studentColumnHeader.handleKeyDown.returns(false)
    const returnValue = this.triggerEvent('onKeyDown', {}, {columnId: 'student', region: 'header'})
    strictEqual(returnValue, false)
  })

  QUnit.module('onNavigatePrev')

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigatePrev', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1)
  })

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigatePrev', {}, {columnId: 'student', region: 'body'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student')
    this.triggerEvent('onNavigatePrev', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  QUnit.module('onNavigateNext')

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigateNext', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1)
  })

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigateNext', {}, {columnId: 'student', region: 'body'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student')
    this.triggerEvent('onNavigateNext', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  QUnit.module('onNavigateLeft')

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigateLeft', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1)
  })

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigateLeft', {}, {columnId: 'student', region: 'body'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student')
    this.triggerEvent('onNavigateLeft', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  QUnit.module('onNavigateRight')

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigateRight', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1)
  })

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigateRight', {}, {columnId: 'student', region: 'body'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student')
    this.triggerEvent('onNavigateRight', {}, {columnId: 'student', region: 'header'})
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
  })

  QUnit.module('onNavigateUp')

  test('calls focusAtStart on the column header component associated with the event location', function () {
    const clock = sinon.useFakeTimers()
    this.triggerEvent('onNavigateUp', {}, {columnId: 'student', region: 'header'})
    clock.tick(0)
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1)
    clock.restore()
  })

  test('does nothing when the location region is not "header"', function () {
    const clock = sinon.useFakeTimers()
    this.triggerEvent('onNavigateUp', {}, {columnId: 'student', region: 'body'})
    clock.tick(0)
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
    clock.restore()
  })

  test('does nothing when no component is referenced for the given column', function () {
    const clock = sinon.useFakeTimers()
    this.gradebook.removeHeaderComponentRef('student')
    this.triggerEvent('onNavigateUp', {}, {columnId: 'student', region: 'header'})
    clock.tick(0)
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0)
    clock.restore()
  })

  QUnit.module('onColumnsReordered', hooks => {
    let gradebook
    let allColumns
    let columns

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      allColumns = [
        {id: 'student', type: 'student'},
        {id: 'custom_col_2401', type: 'custom_column', customColumnId: '2401'},
        {id: 'custom_col_2402', type: 'custom_column', customColumnId: '2402'},
        {id: 'assignment_2301', type: 'assignment'},
        {id: 'assignment_2302', type: 'assignment'},
        {id: 'assignment_group_2201', type: 'assignment_group'},
        {id: 'assignment_group_2202', type: 'assignment_group'},
        {id: 'total_grade', type: 'total_grade'},
      ]
      columns = {
        frozen: allColumns.slice(0, 3),
        scrollable: allColumns.slice(3),
      }

      gradebook.gridData.columns.definitions = allColumns.reduce(
        (map, column) => ({...map, [column.id]: column}),
        {}
      )
      gradebook.gridData.columns.frozen = columns.frozen.map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.scrollable.map(column => column.id)

      sinon.stub(gradebook.props, 'reorderCustomColumns').returns(Promise.resolve())
      sinon.stub(gradebook, 'renderViewOptionsMenu')
      sinon.stub(gradebook, 'updateColumnHeaders')
      sinon.stub(gradebook, 'saveCustomColumnOrder')
    })

    test('reorders custom columns when frozen columns were reordered', () => {
      columns.frozen = [allColumns[0], allColumns[2], allColumns[1]]
      columns.scrollable = allColumns.slice(3, 8)
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns)
      strictEqual(gradebook.props.reorderCustomColumns.callCount, 1)
    })

    test('does not reorder custom columns when custom column order was not affected', () => {
      columns.frozen = [allColumns[1], allColumns[0], allColumns[2]]
      columns.scrollable = allColumns.slice(3, 8)
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns)
      strictEqual(gradebook.props.reorderCustomColumns.callCount, 0)
    })

    test('stores custom column order when scrollable columns were reordered', () => {
      columns.frozen = allColumns.slice(0, 3)
      columns.scrollable = [allColumns[7], ...allColumns.slice(3, 7)]
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns)
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 1)
    })

    test('re-renders the View options menu', () => {
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns)
      strictEqual(gradebook.renderViewOptionsMenu.callCount, 1)
    })

    test('re-renders all column headers', () => {
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns)
      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
    })
  })
})

QUnit.module('Gradebook Grid Events (2)', () => {
  QUnit.module('#onBeforeEditCell', hooks => {
    let gradebook
    let eventObject

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.initSubmissionStateMap()
      gradebook.gradebookContent.customColumns = [
        {id: '1', teacher_notes: false, hidden: false, title: 'Read Only', read_only: true},
        {id: '2', teacher_notes: false, hidden: false, title: 'Not Read Only', read_only: false},
      ]
      gradebook.students = {1101: {id: '1101', isConcluded: false}}
      eventObject = {
        column: {assignmentId: '2301', type: 'assignment'},
        item: {id: '1101'},
      }
      sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({locked: false})
    })

    test('returns true to allow editing the cell', () => {
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), true)
    })

    test('returns false when the student does not exist', () => {
      delete gradebook.students[1101]
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), false)
    })

    test('returns true when the cell is not in an assignment column', () => {
      eventObject.column = {type: 'custom_column'}
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), true)
    })

    test('returns false when the cell is read_only', () => {
      eventObject.column = {type: 'custom_column', customColumnId: '1'}
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), false)
    })
  })

  QUnit.module('onColumnsResized', hooks => {
    let gradebook
    let columns

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      columns = [
        {id: 'student', width: 120},
        {id: 'assignment_2301', width: 140},
        {id: 'total_grade', width: 100},
      ]
      sinon.stub(gradebook, 'saveColumnWidthPreference')
    })

    test('saves the column width preference', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns.slice(0, 1))
      strictEqual(gradebook.saveColumnWidthPreference.callCount, 1)
    })

    test('saves the column width preference for multiple columns', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns)
      strictEqual(gradebook.saveColumnWidthPreference.callCount, 3)
    })

    test('includes the column id when saving the column width preference', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns)
      const ids = gradebook.saveColumnWidthPreference.getCalls().map(call => call.args[0])
      deepEqual(ids, ['student', 'assignment_2301', 'total_grade'])
    })

    test('includes the column width when saving the column width preference', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns)
      const widths = gradebook.saveColumnWidthPreference.getCalls().map(call => call.args[1])
      deepEqual(widths, [120, 140, 100])
    })
  })
})

QUnit.module('Gradebook#updateColumnHeaders', {
  setup() {
    const columns = [
      {type: 'assignment_group', assignmentGroupId: '2201'},
      {type: 'assignment', assignmentId: '2301'},
      {type: 'custom_column', customColumnId: '2401'},
      {type: 'total_grade'},
    ]
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub(),
      },
    }
    this.gradebook.gradebookGrid.grid = {
      getColumns() {
        return columns
      },
    }
  },
})

test('uses Grid Support to update the column headers', function () {
  this.gradebook.updateColumnHeaders()
  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
})

test('takes an optional array of column ids', function () {
  this.gradebook.updateColumnHeaders(['2301', '2401'])
  const {args} = this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.firstCall
  deepEqual(args[0], ['2301', '2401'])
})

QUnit.module('Gradebook#invalidateRowsForStudentIds', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [{id: '1101'}, {id: '1102'}]
    sandbox.stub(this.gradebook.gradebookGrid, 'invalidateRow')
    sandbox.stub(this.gradebook.gradebookGrid, 'render')
  },
})

test('invalidates each student row', function () {
  this.gradebook.invalidateRowsForStudentIds(['1101', '1102'])
  strictEqual(
    this.gradebook.gradebookGrid.invalidateRow.callCount,
    2,
    'called once per student row'
  )
})

test('includes the row index of the student when invalidating', function () {
  this.gradebook.invalidateRowsForStudentIds(['1101', '1102'])
  const rows = map(this.gradebook.gradebookGrid.invalidateRow.args, args => args[0]) // get the first arg of each call
  deepEqual(rows, [0, 1])
})

test('does not invalidate rows for students not included', function () {
  this.gradebook.invalidateRowsForStudentIds(['1102'])
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 1, 'called once')
  strictEqual(
    this.gradebook.gradebookGrid.invalidateRow.lastCall.args[0],
    1,
    'called for the row (1) of student 1102'
  )
})

test('has no effect when the grid has not been initialized', function () {
  this.gradebook.gradebookGrid.grid = null
  this.gradebook.invalidateRowsForStudentIds(['1101'])
  ok(true, 'no error was thrown')
})

QUnit.module('Gradebook#updateColumns', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    sinon.stub(gradebook.gradebookGrid, 'updateColumns')
    sinon.stub(gradebook, 'setVisibleGridColumns')
    sinon.stub(gradebook, 'updateColumnHeaders')
  })

  test('sets the visible grid columns', () => {
    gradebook.updateColumns()
    strictEqual(gradebook.setVisibleGridColumns.callCount, 1)
  })

  test('calls updateColumnHeaders', () => {
    gradebook.updateColumns()
    strictEqual(gradebook.updateColumnHeaders.callCount, 1)
  })
})

QUnit.module('Gradebook#getInitialGridDisplaySettings', () => {
  test('sets selectedPrimaryInfo based on the settings passed in', () => {
    const settings = {student_column_display_as: 'last_first'}
    const {
      gridDisplaySettings: {selectedPrimaryInfo},
    } = createGradebook({settings})
    strictEqual(selectedPrimaryInfo, settings.student_column_display_as)
  })

  test('sets selectedPrimaryInfo to default if no settings passed in', () => {
    const {
      gridDisplaySettings: {selectedPrimaryInfo},
    } = createGradebook()
    strictEqual(selectedPrimaryInfo, 'first_last')
  })

  test('sets selectedPrimaryInfo to default if unknown settings passed in', () => {
    const settings = {student_column_display_as: 'gary_42'}
    const {
      gridDisplaySettings: {selectedPrimaryInfo},
    } = createGradebook({settings})
    strictEqual(selectedPrimaryInfo, 'first_last')
  })

  test('sets selectedSecondaryInfo based on the settings passed in', () => {
    const settings = {student_column_secondary_info: 'login_id'}
    const {
      gridDisplaySettings: {selectedSecondaryInfo},
    } = createGradebook({settings})
    strictEqual(selectedSecondaryInfo, settings.student_column_secondary_info)
  })

  test('sets selectedSecondaryInfo to default if no settings passed in', () => {
    const {
      gridDisplaySettings: {selectedSecondaryInfo},
    } = createGradebook()
    strictEqual(selectedSecondaryInfo, 'none')
  })

  test('sets sortRowsBy > columnId based on the settings passed in', () => {
    const settings = {sort_rows_by_column_id: 'assignment_1'}
    const {
      gridDisplaySettings: {
        sortRowsBy: {columnId},
      },
    } = createGradebook({settings})
    strictEqual(columnId, settings.sort_rows_by_column_id)
  })

  test('sets sortRowsBy > columnId to default if no settings passed in', () => {
    const {
      gridDisplaySettings: {
        sortRowsBy: {columnId},
      },
    } = createGradebook()
    strictEqual(columnId, 'student')
  })

  test('sets sortRowsBy > settingKey based on the settings passed in', () => {
    const settings = {sort_rows_by_setting_key: 'grade'}
    const {
      gridDisplaySettings: {
        sortRowsBy: {settingKey},
      },
    } = createGradebook({settings})
    strictEqual(settingKey, settings.sort_rows_by_setting_key)
  })

  test('sets sortRowsBy > settingKey to default if no settings passed in', () => {
    const {
      gridDisplaySettings: {
        sortRowsBy: {settingKey},
      },
    } = createGradebook()
    strictEqual(settingKey, 'sortable_name')
  })

  test('sets sortRowsBy > Direction based on the settings passed in', () => {
    const settings = {sort_rows_by_direction: 'descending'}
    const {
      gridDisplaySettings: {
        sortRowsBy: {direction},
      },
    } = createGradebook({settings})
    strictEqual(direction, settings.sort_rows_by_direction)
  })

  test('sets sortRowsBy > Direction to default if no settings passed in', () => {
    const {
      gridDisplaySettings: {
        sortRowsBy: {direction},
      },
    } = createGradebook()
    strictEqual(direction, 'ascending')
  })

  test('sets showEnrollments.concluded to a default value', () => {
    const {
      gridDisplaySettings: {
        showEnrollments: {concluded},
      },
    } = createGradebook()
    strictEqual(concluded, false)
  })

  test('sets showEnrollments.inactive to a default value', () => {
    const {
      gridDisplaySettings: {
        showEnrollments: {inactive},
      },
    } = createGradebook()
    strictEqual(inactive, false)
  })

  test('sets showUnpublishedAssignment to a default value', () => {
    const {
      gridDisplaySettings: {showUnpublishedAssignments},
    } = createGradebook()
    strictEqual(showUnpublishedAssignments, true)
  })
})

QUnit.module('Gradebook#setSelectedSecondaryInfo', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub(),
      },
    }
    sandbox.stub(this.gradebook, 'saveSettings')
    sandbox.stub(this.gradebook, 'buildRows')
  },
})

test('updates the selectedSecondaryInfo in the grid display settings', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', true)

  strictEqual(this.gradebook.gridDisplaySettings.selectedSecondaryInfo, 'last_first')
})

test('saves the new grid display settings', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', true)

  strictEqual(this.gradebook.saveSettings.callCount, 1)
})

test('re-renders the grid unless asked not to do it', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false)

  strictEqual(this.gradebook.buildRows.callCount, 1)
})

test('updates the student column header', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false)

  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
})

test('includes the "student" column id when updating column headers', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false)
  const [columnIds] =
    this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
  deepEqual(columnIds, ['student'])
})

QUnit.module('Gradebook#onGridBlur', {
  setup() {
    fakeENV.setup()
    ENV.GRADEBOOK_OPTIONS = {
      proxy_submissions_allowed: false,
    }
    setFixtureHtml($fixtures)

    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [{id: '1101'}]
    const students = [
      {
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          id: '2501',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
        enrollment_state: ['active'],
      },
    ]
    this.gradebook.gotChunkOfStudents(students)
    this.gradebook.initGrid()
    this.gradebook.setAssignments({
      2301: {
        id: '2301',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: 'http://assignmentUrl',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    this.gradebook.assignmentGroups = {9000: {group_weight: 100}}

    // Since the activeLocationChanged handlers use delayed calls, we need to
    // hijack timers and tick() before calling setActiveLocation() below.
    const clock = sinon.useFakeTimers()
    clock.tick(0)
    this.gradebook.gradebookGrid.gridSupport.state.setActiveLocation('body', {cell: 0, row: 0})
    clock.restore()

    sinon.spy(this.gradebook.gradebookGrid.gridSupport.state, 'blur')
  },

  teardown() {
    this.gradebook.destroy()
    $fixtures.innerHTML = ''
  },
})

test('closes grid details tray when open', function () {
  this.gradebook.setSubmissionTrayState(true, '1101', '2301')
  this.gradebook.onGridBlur({target: document.body})
  strictEqual(this.gradebook.gridDisplaySettings.submissionTray.open, false)
})

test('does not close grid details tray when not open', function () {
  const closeSubmissionTrayStub = sandbox.stub(this.gradebook, 'closeSubmissionTray')
  this.gradebook.setSubmissionTrayState(false, '1101', '2301')
  this.gradebook.onGridBlur({target: document.body})
  strictEqual(closeSubmissionTrayStub.callCount, 0)
})

test('blurs the grid when clicking off grid cells', function () {
  this.gradebook.onGridBlur({target: document.body})
  strictEqual(this.gradebook.gradebookGrid.gridSupport.state.blur.callCount, 1)
})

test('does not blur the grid when clicking on the active cell', function () {
  const $activeNode = this.gradebook.gradebookGrid.gridSupport.state.getActiveNode()
  this.gradebook.onGridBlur({target: $activeNode})
  strictEqual(this.gradebook.gradebookGrid.gridSupport.state.blur.callCount, 0)
})

test('does not blur the grid when clicking on another grid cell', function () {
  const $activeNode = this.gradebook.gradebookGrid.gridSupport.state.getActiveNode()
  this.gradebook.gradebookGrid.gridSupport.state.setActiveLocation('body', {cell: 1, row: 0})
  this.gradebook.onGridBlur({target: $activeNode})
  strictEqual(this.gradebook.gradebookGrid.gridSupport.state.blur.callCount, 0)
})

QUnit.module('Gradebook#setVisibleGridColumns()', hooks => {
  let gradebook
  let server
  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    const options = {gradebook_column_order_settings_url: '/grade_column_order_settings_url'}
    server.respondWith('POST', options.gradebook_column_order_settings_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])

    setFixtureHtml($fixtures)
  })

  hooks.afterEach(() => {
    $fixtures.innerHTML = ''
    server.restore()
  })

  function createAndInitGradebook(options) {
    gradebook = createGradebook(options)
    gradebook.gotAllAssignmentGroups([
      {
        assignments: [
          {
            assignment_group_id: '2201',
            id: '2301',
            name: 'Math Assignment',
            points_possible: 10,
            published: true,
          },
          {
            assignment_group_id: '2201',
            id: '2302',
            name: 'English Assignment',
            points_possible: 10,
            published: false,
          },
        ],
        group_weight: 40,
        id: '2201',
        name: 'Assignments',
      },
    ])

    const students = [
      {
        id: '1101',
        name: 'Adam Jones',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
      },
      {
        id: '1102',
        name: 'Betty Ford',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
      },
      {
        id: '1199',
        name: 'Test Student',
        enrollments: [{type: 'StudentViewEnrollment', grades: {html_url: 'http://example.url/'}}],
      },
    ]
    gradebook.courseContent.students.setStudentIds(['1101', '1102', '1199'])
    gradebook.buildRows()
    gradebook.gotChunkOfStudents(students)
    gradebook.initGrid()
  }

  function countColumn(columnSection, columnId) {
    return columnSection.filter(id => id === columnId).length
  }

  QUnit.module('when the "Total Grade" column will be frozen', contextHooks => {
    contextHooks.beforeEach(() => {
      createAndInitGradebook()
    })

    test('adds total_grade to frozen columns when not yet included', () => {
      gradebook.gradebookColumnOrderSettings.freezeTotalGrade = true
      strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade'), 0)

      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade'), 1)
    })

    test('does not add total_grade to scrollable columns', () => {
      gradebook.gradebookColumnOrderSettings.freezeTotalGrade = true
      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.scrollable, 'total_grade'), 0)
    })

    test('does not add total_grade to frozen columns when already included', () => {
      gradebook.freezeTotalGradeColumn()
      strictEqual(
        countColumn(gradebook.gridData.columns.frozen, 'total_grade'),
        1,
        'column is frozen before setting visible grid columns'
      )

      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade'), 1)
    })
  })

  QUnit.module('setting scrollable columns', contextHooks => {
    contextHooks.beforeEach(() => {
      createAndInitGradebook({final_grade_override_enabled: true})
      gradebook.courseSettings.setAllowFinalGradeOverride(true)
    })

    test('does not throw an error if the assignment group definition is not yet loaded', () => {
      gradebook.gridData.columns.definitions.assignment_group_2201 = undefined
      let errorThrown = false
      try {
        gradebook.setVisibleGridColumns()
      } catch {
        errorThrown = true
      }
      notOk(errorThrown)
    })

    test('does not throw an error if the total grade definition is not yet loaded', () => {
      gradebook.gridData.columns.definitions.total_grade = undefined
      let errorThrown = false
      try {
        gradebook.setVisibleGridColumns()
      } catch {
        errorThrown = true
      }
      notOk(errorThrown)
    })

    test('does not throw an error if the total grade override definition is not yet loaded', () => {
      gradebook.gridData.columns.definitions.total_grade_override = undefined
      let errorThrown = false
      try {
        gradebook.setVisibleGridColumns()
      } catch {
        errorThrown = true
      }
      notOk(errorThrown)
    })
  })

  QUnit.module('when the "Total Grade Override" column is used', contextHooks => {
    contextHooks.beforeEach(() => {
      createAndInitGradebook({final_grade_override_enabled: true})
      gradebook.courseSettings.setAllowFinalGradeOverride(true)
    })

    test('adds total_grade_override to scrollable columns', () => {
      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.scrollable, 'total_grade_override'), 1)
    })

    test('does not add total_grade_override to frozen columns', () => {
      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade_override'), 0)
    })
  })

  QUnit.module('when the "Total Grade Override" column is not used', contextHooks => {
    contextHooks.beforeEach(() => {
      createAndInitGradebook({final_grade_override_enabled: true})
      gradebook.courseSettings.setAllowFinalGradeOverride(false)
    })

    test('does not add total_grade_override to scrollable columns', () => {
      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.scrollable, 'total_grade_override'), 0)
    })

    test('does not add total_grade_override to frozen columns', () => {
      gradebook.setVisibleGridColumns()
      strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade_override'), 0)
    })
  })
})

QUnit.module('Gradebook#setSortRowsBySetting', {
  setup() {
    this.gradebook = createGradebook()
    sandbox.stub(this.gradebook, 'saveSettings')
    sandbox.stub(this.gradebook, 'sortGridRows')

    this.gradebook.setSortRowsBySetting('assignment_1', 'grade', 'descending')
  },
})

test('updates the sort column in the grid display settings', function () {
  strictEqual(this.gradebook.gridDisplaySettings.sortRowsBy.columnId, 'assignment_1')
})

test('updates the sort setting key in the grid display settings', function () {
  strictEqual(this.gradebook.gridDisplaySettings.sortRowsBy.settingKey, 'grade')
})

test('updates the sort direction in the grid display settings', function () {
  strictEqual(this.gradebook.gridDisplaySettings.sortRowsBy.direction, 'descending')
})

test('saves the new grid display settings', function () {
  strictEqual(this.gradebook.saveSettings.callCount, 1)
})

test('re-sorts the grid rows', function () {
  strictEqual(this.gradebook.sortGridRows.callCount, 1)
})

QUnit.module('Gradebook#setSelectedPrimaryInfo', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub(),
      },
    }
    sandbox.stub(this.gradebook, 'saveSettings')
    sandbox.stub(this.gradebook, 'buildRows')
  },
})

test('updates the selectedPrimaryInfo in the grid display settings', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', true)

  strictEqual(this.gradebook.gridDisplaySettings.selectedPrimaryInfo, 'last_first')
})

test('saves the new grid display settings', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', true)

  strictEqual(this.gradebook.saveSettings.callCount, 1)
})

test('re-renders the grid unless asked not to do it', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false)

  strictEqual(this.gradebook.buildRows.callCount, 1)
})

test('updates the student column header', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false)

  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
})

test('includes the "student" column id when updating column headers', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false)
  const [columnIds] =
    this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
  deepEqual(columnIds, ['student'])
})

QUnit.module('Gradebook#arrangeColumnsBy', hooks => {
  let server
  let options
  let gradebook

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    options = {gradebook_column_order_settings_url: '/grade_column_order_settings_url'}
    server.respondWith('POST', options.gradebook_column_order_settings_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])
    gradebook = createGradebook(options)
    gradebook.makeColumnSortFn = () => () => 1
    gradebook.gradebookGrid.grid = {
      getColumns() {
        return []
      },
      getOptions() {
        return {
          numberOfColumnsToFreeze: 0,
        }
      },
      invalidate() {},
      setColumns() {},
      setNumberOfColumnsToFreeze() {},
    }
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('renders the view options menu', () => {
    sandbox.stub(gradebook, 'renderViewOptionsMenu')
    sandbox.stub(gradebook, 'updateColumnHeaders')

    gradebook.arrangeColumnsBy({sortBy: 'due_date', direction: 'ascending'}, false)

    strictEqual(gradebook.renderViewOptionsMenu.callCount, 1)
  })
})

QUnit.module('Gradebook#initShowUnpublishedAssignments')

test('if unset, default to true', () => {
  const gradebook = createGradebook()
  gradebook.initShowUnpublishedAssignments(undefined)

  strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true)
})

test('sets to true if passed "true"', () => {
  const gradebook = createGradebook()
  gradebook.initShowUnpublishedAssignments('true')

  strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true)
})

test('sets to false if passed "false"', () => {
  const gradebook = createGradebook()
  gradebook.initShowUnpublishedAssignments('false')

  strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
})

QUnit.module('Gradebook#toggleUnpublishedAssignments', () => {
  test('toggles showUnpublishedAssignments to true when currently false', () => {
    const gradebook = createGradebook()
    gradebook.gridDisplaySettings.showUnpublishedAssignments = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox
      .stub(gradebook, 'saveSettings')
      .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
    gradebook.toggleUnpublishedAssignments()

    strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true)
  })

  test('toggles showUnpublishedAssignments to false when currently true', () => {
    const gradebook = createGradebook()
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
    gradebook.toggleUnpublishedAssignments()

    strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    const gradebook = createGradebook()
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    const stubFn = sandbox
      .stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      .callsFake(() => {
        strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
      })
    sandbox
      .stub(gradebook, 'saveSettings')
      .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
    gradebook.toggleUnpublishedAssignments()

    strictEqual(stubFn.callCount, 1)
  })

  test('calls saveSettings after updateColumnsAndRenderViewOptionsMenu', () => {
    const gradebook = createGradebook()
    const updateColumnsAndRenderViewOptionsMenuStub = sandbox.stub(
      gradebook,
      'updateColumnsAndRenderViewOptionsMenu'
    )
    const saveSettingsStub = sandbox
      .stub(gradebook, 'saveSettings')
      .callsFake(() => Promise.resolve())
    gradebook.toggleUnpublishedAssignments()

    sinon.assert.callOrder(updateColumnsAndRenderViewOptionsMenuStub, saveSettingsStub)
  })

  test('calls saveSettings with showUnpublishedAssignments', () => {
    const settings = {show_unpublished_assignments: 'true'}
    const gradebook = createGradebook({settings})
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    const saveSettingsStub = sandbox
      .stub(gradebook, 'saveSettings')
      .callsFake(() => Promise.resolve())
    gradebook.toggleUnpublishedAssignments()

    const [{showUnpublishedAssignments}] = saveSettingsStub.firstCall.args
    strictEqual(showUnpublishedAssignments, !settings.show_unpublished_assignments)
  })

  test('calls saveSettings successfully', () => {
    const server = sinon.fakeServer.create({respondImmediately: true})
    const options = {settings_update_url: '/course/1/gradebook_settings'}
    server.respondWith('POST', options.settings_update_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])

    const gradebook = createGradebook({options})
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    const saveSettingsStub = sinon.spy(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    strictEqual(saveSettingsStub.callCount, 1)
    server.restore()
  })

  test('calls saveSettings and rolls back on failure', async () => {
    const server = sinon.fakeServer.create({respondImmediately: true})
    const options = {settings_update_url: '/course/1/gradebook_settings'}
    server.respondWith('POST', options.settings_update_url, [
      401,
      {'Content-Type': 'application/json'},
      '{}',
    ])

    const gradebook = createGradebook({options})
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    const stubFn = sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    stubFn.onFirstCall().callsFake(() => {
      strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
    })
    stubFn.onSecondCall().callsFake(() => {
      strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true)
    })
    await gradebook.toggleUnpublishedAssignments()
    strictEqual(stubFn.callCount, 2)
    server.restore()
  })
})

QUnit.module('Gradebook#updateTotalGradeColumn', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    const columns = [
      {id: 'student', type: 'student'},
      {id: 'assignment_232', type: 'assignment'},
      {id: 'total_grade', type: 'total_grade'},
      {id: 'assignment_group_12', type: 'assignment'},
    ]
    gradebook = createGradebook()
    gradebook.gridData.rows = [{id: '1101'}, {id: '1102'}]
    sinon.stub(gradebook.courseContent.students, 'listStudentIds').returns(['1101', '1102'])

    gradebook.gradebookGrid.grid = {
      updateCell: sinon.stub(),
      getColumns() {
        return columns
      },
    }
  })

  test('makes exactly one update for each currently loaded student', () => {
    gradebook.updateTotalGradeColumn()
    strictEqual(gradebook.gradebookGrid.grid.updateCell.callCount, 2)
  })

  test('includes the row index of the student when updating', () => {
    gradebook.updateTotalGradeColumn()
    const rows = map(gradebook.gradebookGrid.grid.updateCell.args, args => args[0])
    deepEqual(rows, [0, 1])
  })

  test('includes the index of the total_grade column when updating', () => {
    gradebook.updateTotalGradeColumn()
    const rows = map(gradebook.gradebookGrid.grid.updateCell.args, args => args[1])
    deepEqual(rows, [2, 2])
  })

  test('has no effect when the grid has not been initialized', () => {
    gradebook.gradebookGrid.grid = null
    gradebook.updateTotalGradeColumn()
    ok(true, 'no error was thrown')
  })
})

QUnit.module('Gradebook#addAssignmentColumnDefinition', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
  })

  test('adds a column definition for the given assignment', () => {
    const assignment = {id: 12, name: 'Some Assignment'}
    gradebook.addAssignmentColumnDefinition(assignment)
    const definitions = gradebook.gridData.columns.definitions
    ok(definitions.assignment_12)
  })

  test('ignores the assignment if a column definition already exists for it', () => {
    const assignment = {id: 12, name: 'Some Assignment'}
    gradebook.addAssignmentColumnDefinition(assignment)
    gradebook.addAssignmentColumnDefinition(assignment)
    const definitions = gradebook.gridData.columns.definitions
    strictEqual(Object.keys(definitions).length, 1)
  })
})

QUnit.module('Gradebook#handleSubmissionPostedChange', hooks => {
  let columnId
  let server
  let options
  let gradebook
  const sortByStudentNameSettings = {
    columnId: 'student',
    settingKey: 'sortable_name',
    direction: 'ascending',
  }

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    options = {settings_update_url: '/course/1/gradebook_settings'}
    server.respondWith('POST', options.settings_update_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])
    gradebook = createGradebook(options)
    columnId = getAssignmentColumnId('2301')
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('resets grading', () => {
    sinon.stub(gradebook, 'resetGrading')
    gradebook.handleSubmissionPostedChange({id: '2301'})
    strictEqual(gradebook.resetGrading.callCount, 1)
    gradebook.resetGrading.restore()
  })

  test('when sorted by an anonymous assignment, gradebook changes sort', () => {
    gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending')
    gradebook.handleSubmissionPostedChange({id: '2301', anonymize_students: true})
    deepEqual(gradebook.getSortRowsBySetting(), sortByStudentNameSettings)
  })

  test('when sorted by assignment group of an anonymous assignment, gradebook changes sort', () => {
    const groupId = '7'
    gradebook.setSortRowsBySetting(getAssignmentGroupColumnId(groupId), 'grade', 'ascending')
    gradebook.handleSubmissionPostedChange({
      id: '2301',
      anonymize_students: true,
      assignment_group_id: groupId,
    })
    deepEqual(gradebook.getSortRowsBySetting(), sortByStudentNameSettings)
  })

  test('when sorted by total grade, gradebook changes sort', () => {
    gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending')
    gradebook.handleSubmissionPostedChange({id: '2301', anonymize_students: true})
    deepEqual(gradebook.getSortRowsBySetting(), sortByStudentNameSettings)
  })

  test('when assignment is not anonymous, gradebook does not change sort', () => {
    gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending')
    const sortSettings = gradebook.getSortRowsBySetting()
    gradebook.handleSubmissionPostedChange({id: '2301', anonymize_students: false})
    deepEqual(gradebook.getSortRowsBySetting(), sortSettings)
  })

  test('when gradebook is sorted by an unrelated column, gradebook does not change sort', () => {
    gradebook.setSortRowsBySetting(getAssignmentColumnId('2222'), 'grade', 'ascending')
    const sortSettings = gradebook.getSortRowsBySetting()
    gradebook.handleSubmissionPostedChange({id: '2301', anonymize_students: true})
    deepEqual(gradebook.getSortRowsBySetting(), sortSettings)
  })
})

QUnit.module('Gradebook#updateStudentRow', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [{id: '1101'}, {id: '1102'}, {id: '1103'}]
    sandbox.stub(this.gradebook.gradebookGrid, 'invalidateRow')
  },
})

test('updates the associated row with the given student', function () {
  const student = {id: '1102', name: 'Adam Jones'}
  this.gradebook.updateStudentRow(student)
  strictEqual(this.gradebook.gridData.rows[1], student)
})

test('invalidates the associated grid row', function () {
  this.gradebook.updateStudentRow({id: '1102', name: 'Adam Jones'})
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 1)
})

test('includes the row index when invalidating the grid row', function () {
  this.gradebook.updateStudentRow({id: '1102', name: 'Adam Jones'})
  const [row] = this.gradebook.gradebookGrid.invalidateRow.lastCall.args
  strictEqual(row, 1)
})

test('does not update rows when the given student is not already included', function () {
  this.gradebook.updateStudentRow({id: '1104', name: 'Dana Smith'})
  equal(typeof this.gradebook.gridData.rows[-1], 'undefined')
  deepEqual(
    this.gradebook.gridData.rows.map(row => row.id),
    ['1101', '1102', '1103']
  )
})

test('does not invalidate rows when the given student is not already included', function () {
  this.gradebook.updateStudentRow({id: '1104', name: 'Dana Smith'})
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 0)
})

QUnit.module('Gradebook#updateRowCellsForStudentIds', {
  setup() {
    const columns = [
      {id: 'student', type: 'student'},
      {id: 'assignment_232', type: 'assignment'},
      {id: 'total_grade', type: 'total_grade'},
      {id: 'assignment_group_12', type: 'assignment'},
    ]
    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [{id: '1101'}, {id: '1102'}]
    this.gradebook.gradebookGrid.grid = {
      updateCell: sinon.stub(),
      getColumns() {
        return columns
      },
    }
  },
})

test('updates cells for each column', function () {
  this.gradebook.updateRowCellsForStudentIds(['1101'])
  strictEqual(this.gradebook.gradebookGrid.grid.updateCell.callCount, 4, 'called once per column')
})

test('includes the row index of the student when updating', function () {
  this.gradebook.updateRowCellsForStudentIds(['1102'])
  const rows = map(this.gradebook.gradebookGrid.grid.updateCell.args, args => args[0]) // get the first arg of each call
  deepEqual(rows, [1, 1, 1, 1], 'each call specified row 1 (student 1102)')
})

test('includes the index of each column when updating', function () {
  this.gradebook.updateRowCellsForStudentIds(['1101', '1102'])
  const rows = map(this.gradebook.gradebookGrid.grid.updateCell.args, args => args[1]) // get the first arg of each call
  deepEqual(rows, [0, 1, 2, 3, 0, 1, 2, 3])
})

test('updates row cells for each student', function () {
  this.gradebook.updateRowCellsForStudentIds(['1101', '1102'])
  strictEqual(
    this.gradebook.gradebookGrid.grid.updateCell.callCount,
    8,
    'called once per student, per column'
  )
})

test('has no effect when the grid has not been initialized', function () {
  this.gradebook.gradebookGrid.grid = null
  this.gradebook.updateRowCellsForStudentIds(['1101'])
  ok(true, 'no error was thrown')
})
