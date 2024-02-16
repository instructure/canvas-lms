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

import $ from 'jquery'
import 'jquery-migrate'
import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import GradebookApi from 'ui/features/gradebook/react/default_gradebook/apis/GradebookApi'

QUnit.module('Gradebook#setTeacherNotesHidden - showing teacher notes', {
  setup() {
    this.promise = {
      then(thenFn) {
        this.thenFn = thenFn
        return this
      },

      catch(catchFn) {
        this.catchFn = catchFn
        return this
      },
    }
    sandbox.stub(GradebookApi, 'updateTeacherNotesColumn').returns(this.promise)
    this.gradebook = createGradebook({context_id: '1201'})
    this.gradebook.gradebookContent.customColumns = [
      {id: '2401', teacher_notes: true, hidden: true, title: 'Notes'},
      {id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes'},
    ]
    this.gradebook.gradebookGrid.grid = {
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
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu')
  },
})

test('sets teacherNotesUpdating to true before sending the api request', function () {
  this.gradebook.setTeacherNotesHidden(false)
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true)
})

test('re-renders the view options menu after setting teacherNotesUpdating', function () {
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true)
  })
  this.gradebook.setTeacherNotesHidden(false)
})

test('calls GradebookApi.updateTeacherNotesColumn', function () {
  this.gradebook.setTeacherNotesHidden(false)
  equal(GradebookApi.updateTeacherNotesColumn.callCount, 1)
  const [courseId, columnId, attr] = GradebookApi.updateTeacherNotesColumn.getCall(0).args
  equal(courseId, '1201', 'parameter 1 is the course id')
  equal(columnId, '2401', 'parameter 2 is the column id')
  equal(attr.hidden, false, 'attr.hidden is true')
})

test('shows the notes column after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false)
  equal(this.gradebook.getTeacherNotesColumn().hidden, true)
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
  })
  equal(this.gradebook.getTeacherNotesColumn().hidden, false)
})

test('sets teacherNotesUpdating to false after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false)
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
  })
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('re-renders the view options menu after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false)
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
  })
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('displays a flash message after request rejects', function () {
  sandbox.stub($, 'flashError')
  this.gradebook.setTeacherNotesHidden(false)
  this.promise.catchFn(new Error('FAIL'))
  equal($.flashError.callCount, 1)
})

test('sets teacherNotesUpdating to false after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(false)
  this.promise.catchFn(new Error('FAIL'))
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('re-renders the view options menu after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(false)
  this.promise.catchFn(new Error('FAIL'))
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

QUnit.module('Gradebook#setTeacherNotesHidden - hiding teacher notes', {
  setup() {
    this.promise = {
      then(thenFn) {
        this.thenFn = thenFn
        return this
      },

      catch(catchFn) {
        this.catchFn = catchFn
        return this
      },
    }
    sandbox.stub(GradebookApi, 'updateTeacherNotesColumn').returns(this.promise)
    this.gradebook = createGradebook({
      context_id: '1201',
      teacher_notes: {id: '2401', teacher_notes: true, hidden: false},
    })
    this.gradebook.gradebookGrid.grid = {
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
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu')
  },
})

test('sets teacherNotesUpdating to true before sending the api request', function () {
  this.gradebook.setTeacherNotesHidden(true)
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true)
})

test('re-renders the view options menu after setting teacherNotesUpdating', function () {
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true)
  })
  this.gradebook.setTeacherNotesHidden(true)
})

test('calls GradebookApi.updateTeacherNotesColumn', function () {
  this.gradebook.setTeacherNotesHidden(true)
  equal(GradebookApi.updateTeacherNotesColumn.callCount, 1)
  const [courseId, columnId, attr] = GradebookApi.updateTeacherNotesColumn.getCall(0).args
  equal(courseId, '1201', 'parameter 1 is the course id')
  equal(columnId, '2401', 'parameter 2 is the column id')
  equal(attr.hidden, true, 'attr.hidden is true')
})

test('hides the notes column after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true)
  equal(this.gradebook.getTeacherNotesColumn().hidden, false)
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true},
  })
  equal(this.gradebook.getTeacherNotesColumn().hidden, true)
})

test('sets teacherNotesUpdating to false after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true)
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true},
  })
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('re-renders the view options menu after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true)
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true},
  })
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('displays a flash message after request rejects', function () {
  sandbox.stub($, 'flashError')
  this.gradebook.setTeacherNotesHidden(true)
  this.promise.catchFn(new Error('FAIL'))
  equal($.flashError.callCount, 1)
})

test('sets teacherNotesUpdating to false after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(true)
  this.promise.catchFn(new Error('FAIL'))
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('re-renders the view options menu after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(true)
  this.promise.catchFn(new Error('FAIL'))
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

QUnit.module('Gradebook#showNotesColumn', {
  setup() {
    const teacherNotes = {
      id: '2401',
      title: 'Notes',
      position: 1,
      teacher_notes: true,
      hidden: true,
    }
    this.gradebook = createGradebook({teacher_notes: teacherNotes})
    sandbox.stub(this.gradebook, 'toggleNotesColumn')
  },
})

QUnit.module('Gradebook#getTeacherNotesViewOptionsMenuProps')

test('includes teacherNotes', () => {
  const gradebook = createGradebook()
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(typeof props.disabled, 'boolean', 'props include "disabled"')
  equal(typeof props.onSelect, 'function', 'props include "onSelect"')
  equal(typeof props.selected, 'boolean', 'props include "selected"')
})

test('disabled defaults to true', () => {
  const gradebook = createGradebook()
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.disabled, true)
})

test('disabled is false when the grid is ready', () => {
  const gradebook = createGradebook()
  sinon.stub(gradebook.gridReady, 'state').get(() => 'resolved')
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.disabled, false)
})

test('disabled is true if the teacher notes column is updating', () => {
  const gradebook = createGradebook()
  sinon.stub(gradebook.gridReady, 'state').get(() => 'resolved')
  gradebook.setTeacherNotesColumnUpdating(true)
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.disabled, true)
})

test('disabled is false if the teacher notes column is not updating', () => {
  const gradebook = createGradebook()
  sinon.stub(gradebook.gridReady, 'state').get(() => 'resolved')
  gradebook.setTeacherNotesColumnUpdating(false)
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.disabled, false)
})

test('onSelect calls createTeacherNotes if there are no teacher notes', () => {
  const gradebook = createGradebook({teacher_notes: null})
  sandbox.stub(gradebook, 'createTeacherNotes')
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  props.onSelect()
  equal(gradebook.createTeacherNotes.callCount, 1)
})

test('onSelect calls setTeacherNotesHidden with false if teacher notes are visible', () => {
  const teacherNotes = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true}
  const gradebook = createGradebook({teacher_notes: teacherNotes})
  sandbox.stub(gradebook, 'setTeacherNotesHidden')
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  props.onSelect()
  equal(gradebook.setTeacherNotesHidden.callCount, 1)
  equal(gradebook.setTeacherNotesHidden.getCall(0).args[0], false)
})

test('onSelect calls setTeacherNotesHidden with true if teacher notes are hidden', () => {
  const teacherNotes = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false}
  const gradebook = createGradebook({teacher_notes: teacherNotes})
  sandbox.stub(gradebook, 'setTeacherNotesHidden')
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  props.onSelect()
  equal(gradebook.setTeacherNotesHidden.callCount, 1)
  equal(gradebook.setTeacherNotesHidden.getCall(0).args[0], true)
})

test('selected is false if there are no teacher notes', () => {
  const gradebook = createGradebook({teacher_notes: null})
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.selected, false)
})

test('selected is false if teacher notes are hidden', () => {
  const teacherNotes = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true}
  const gradebook = createGradebook({teacher_notes: teacherNotes})
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.selected, false)
})

test('selected is true if teacher notes are visible', () => {
  const teacherNotes = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false}
  const gradebook = createGradebook({teacher_notes: teacherNotes})
  const props = gradebook.getTeacherNotesViewOptionsMenuProps()
  equal(props.selected, true)
})

QUnit.module('Gradebook#createTeacherNotes', {
  setup() {
    this.promise = {
      then(thenFn) {
        this.thenFn = thenFn
        return this
      },

      catch(catchFn) {
        this.catchFn = catchFn
        return this
      },
    }
    sandbox.stub(GradebookApi, 'createTeacherNotesColumn').returns(this.promise)
    this.gradebook = createGradebook({context_id: '1201'})
    sandbox.stub(this.gradebook, 'showNotesColumn')
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu')
  },
})

test('sets teacherNotesUpdating to true before sending the api request', function () {
  this.gradebook.createTeacherNotes()
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true)
})

test('re-renders the view options menu after setting teacherNotesUpdating', function () {
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true)
  })
  this.gradebook.createTeacherNotes()
})

test('calls GradebookApi.createTeacherNotesColumn', function () {
  this.gradebook.createTeacherNotes()
  equal(GradebookApi.createTeacherNotesColumn.callCount, 1)
  const [courseId] = GradebookApi.createTeacherNotesColumn.getCall(0).args
  equal(courseId, '1201', 'the only parameter is the course id')
})

test('updates teacher notes with response data after request resolves', function () {
  const column = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false}
  this.gradebook.createTeacherNotes()
  this.promise.thenFn({data: column})
  equal(this.gradebook.getTeacherNotesColumn(), column)
})

test('updates custom columns with response data after request resolves', function () {
  const column = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false}
  this.gradebook.createTeacherNotes()
  this.promise.thenFn({data: column})
  deepEqual(this.gradebook.gradebookContent.customColumns, [column])
})

test('shows the notes column after request resolves', function () {
  this.gradebook.createTeacherNotes()
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
  })
  equal(this.gradebook.getTeacherNotesColumn().hidden, false)
})

test('sets teacherNotesUpdating to false after request resolves', function () {
  this.gradebook.createTeacherNotes()
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
  })
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('re-renders the view options menu after request resolves', function () {
  this.gradebook.createTeacherNotes()
  this.promise.thenFn({
    data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
  })
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('displays a flash error after request rejects', function () {
  sandbox.stub($, 'flashError')
  this.gradebook.createTeacherNotes()
  this.promise.catchFn(new Error('FAIL'))
  equal($.flashError.callCount, 1)
})

test('sets teacherNotesUpdating to false after request rejects', function () {
  this.gradebook.createTeacherNotes()
  this.promise.catchFn(new Error('FAIL'))
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})

test('re-renders the view options menu after request rejects', function () {
  this.gradebook.createTeacherNotes()
  this.promise.catchFn(new Error('FAIL'))
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false)
})
