/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import Assignment from 'compiled/models/Assignment'
import WikiPage from 'compiled/models/WikiPage'
import WikiPageEditView from 'compiled/views/wiki/WikiPageEditView'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import fixtures from 'helpers/fixtures'
import editorUtils from 'helpers/editorUtils'
import fakeENV from 'helpers/fakeENV'

QUnit.module('WikiPageEditView:Init', {
  setup() {
    this.initSpy = sinon.spy(RichContentEditor, 'initSidebar')
  },

  teardown() {
    RichContentEditor.initSidebar.restore()
    editorUtils.resetRCE()
    $(window).off('beforeunload')
    $('.ui-dialog').remove()
  }
})

test('init wiki sidebar during render', function() {
  const wikiPageEditView = new WikiPageEditView()
  wikiPageEditView.render()
  ok(this.initSpy.calledOnce, 'Called richContentEditor.initSidebar once')
})

test('renders escaped angle brackets properly', () => {
  const body = '<p>&lt;E&gt;</p>'
  const wikiPage = new WikiPage({body})
  const view = new WikiPageEditView({model: wikiPage})
  view.render()
  equal(view.$wikiPageBody.val(), body)
})

test('conditional content is hidden when disabled', () => {
  const view = new WikiPageEditView({WIKI_RIGHTS: {manage: true}})
  view.render()

  const conditionalToggle = view.$el.find('#conditional_content')
  equal(conditionalToggle.length, 0, 'Toggle is hidden')
})

QUnit.module('WikiPageEditView:StudentPlanner', {
  setup() {
    fakeENV.setup({student_planner_enabled: true})
  },

  teardown() {
    fakeENV.teardown()
    $('.ui-dialog').remove()
  }
})

test('student planner option hidden for insufficient rights', () => {
  const view = new WikiPageEditView({
    WIKI_RIGHTS: {read: true},
    PAGE_RIGHTS: {
      read: true,
      update_content: true
    }
  })
  view.render()
  const studentPlannerContainer = view.$el.find('#todo_date_container')
  equal(studentPlannerContainer.length, 0, 'Toggle is hidden')
})

test('student planner option appears', () => {
  const view = new WikiPageEditView({WIKI_RIGHTS: {manage: true}})
  view.render()

  const studentPlannerToggle = view.$el.find('#student_planner_checkbox')
  equal(studentPlannerToggle.length, 1, 'Toggle is visible')
  equal(studentPlannerToggle.prop('checked'), false, 'Toggle is unchecked')
})

test('student planner date picker appears', () => {
  const wikiPage = new WikiPage({todo_date: 'Jan 3'})
  const view = new WikiPageEditView({
    model: wikiPage,
    WIKI_RIGHTS: {manage: true}
  })
  view.render()

  const studentPlannerToggle = view.$el.find('#student_planner_checkbox')
  const studentPlannerDateInput = view.$el.find('#todo_date_container')
  equal(studentPlannerToggle.prop('checked'), true, 'Toggle is checked')
  equal(studentPlannerDateInput.length, 1, 'Date picker is visible')
})

test('student planner option does stuff', () => {
  const wikiPage = new WikiPage({todo_date: 'Jan 3'})
  const view = new WikiPageEditView({
    model: wikiPage,
    WIKI_RIGHTS: {manage: true}
  })
  view.render()

  const studentPlannerToggle = view.$el.find('#student_planner_checkbox')
  const studentPlannerDateInput = view.$el.find('#todo_date')
  equal(studentPlannerToggle.prop('checked'), true, 'Toggle is checked')
  equal(studentPlannerDateInput.val(), 'Jan 3 at 12am')
})

QUnit.module('WikiPageEditView:ConditionalContent', {
  setup() {
    fakeENV.setup({CONDITIONAL_RELEASE_SERVICE_ENABLED: true})
  },

  teardown() {
    fakeENV.teardown()
    $('.ui-dialog').remove()
  }
})

test('conditional content option hidden for insufficient rights', () => {
  const view = new WikiPageEditView({
    WIKI_RIGHTS: {read: true},
    PAGE_RIGHTS: {
      read: true,
      update_content: true
    }
  })
  view.render()

  const conditionalToggle = view.$el.find('#conditional_content')
  equal(conditionalToggle.length, 0, 'Toggle is hidden')
})

test('conditional content option appears', () => {
  const view = new WikiPageEditView({WIKI_RIGHTS: {manage: true}})
  view.render()
  const conditionalToggle = view.$el.find('#conditional_content')
  equal(conditionalToggle.length, 1, 'Toggle is visible')
  equal(conditionalToggle.prop('checked'), false, 'Toggle is unchecked')
})

test('conditional content option appears populated', () => {
  const wikiPage = new WikiPage({
    set_assignment: true,
    assignment: new Assignment({set_assignment: true})
  })
  const view = new WikiPageEditView({
    model: wikiPage,
    WIKI_RIGHTS: {manage: true}
  })
  view.render()

  const conditionalToggle = view.$el.find('#conditional_content')
  equal(conditionalToggle.prop('checked'), true, 'Toggle is checked')
})

test('conditional content option does stuff', () => {
  const wikiPage = new WikiPage()
  const view = new WikiPageEditView({
    model: wikiPage,
    WIKI_RIGHTS: {manage: true}
  })
  view.render()

  const conditionalToggle = view.$el.find('#conditional_content')
  equal(conditionalToggle.prop('checked'), false, 'Toggle is unchecked')
  conditionalToggle.prop('checked', true)
  const {assignment} = view.getFormData()
  equal(assignment.get('set_assignment'), '1', 'Sets assignment')
  equal(assignment.get('only_visible_to_overrides'), '1', 'Sets override visibility')
})

QUnit.module('WikiPageEditView:UnsavedChanges', {
  setup() {
    fixtures.setup()
  },

  teardown() {
    fixtures.teardown()
    editorUtils.resetRCE()
    $(window).off('beforeunload')
    $('.ui-dialog').remove()
  }
})

const setupUnsavedChangesTest = function(test, attributes) {
  const setup = function() {
    this.wikiPage = new WikiPage(attributes)
    this.view = new WikiPageEditView({model: this.wikiPage})
    this.view.$el.appendTo('#fixtures')
    this.view.render()

    this.titleInput = this.view.$el.find('[name=title]')
    this.bodyInput = this.view.$el.find('[name=body]')

    // stub the 'is_dirty' RCE command. NOTE: this stubs only the editorBox
    // version with the feature flag off. force these specs to start failing
    // when run with the feature flag on, at which point this will need to be
    // updated to stub remoteEditor instead
    ok(!this.bodyInput.data('remoteEditor'))
    ok(this.bodyInput.data('rich_text'))
    const model = this.wikiPage
    const {bodyInput} = this
    const {editorBox} = bodyInput
    this.stub($.fn, 'editorBox').callsFake(function(options) {
      if (options === 'is_dirty') {
        return bodyInput.val() !== model.get('body')
      } else {
        return editorBox.apply(this, arguments)
      }
    })
  }

  return setup.call(test, attributes)
}

test('check for unsaved changes on new model', function() {
  setupUnsavedChangesTest(this, {title: '', body: ''})

  this.titleInput.val('blah')
  ok(this.view.getFormData().title === 'blah', 'blah')
  ok(this.view.hasUnsavedChanges(), 'Changed title')
  this.titleInput.val('')
  ok(!this.view.hasUnsavedChanges(), 'Unchanged title')
  this.bodyInput.val('bloo')
  ok(this.view.hasUnsavedChanges(), 'Changed body')
  this.bodyInput.val('')
  ok(!this.view.hasUnsavedChanges(), 'Unchanged body')
})

test('check for unsaved changes on model with data', function() {
  setupUnsavedChangesTest(this, {title: 'nooo', body: 'blargh'})

  ok(!this.view.hasUnsavedChanges(), 'No changes')
  this.titleInput.val('')
  ok(this.view.hasUnsavedChanges(), 'Changed title')
  this.titleInput.val('nooo')
  ok(!this.view.hasUnsavedChanges(), 'Unchanged title')
  this.bodyInput.val('')
  ok(this.view.hasUnsavedChanges(), 'Changed body')
})

test('warn on cancel if unsaved changes', function() {
  setupUnsavedChangesTest(this, {title: 'nooo', body: 'blargh'})
  this.spy(this.view, 'trigger')
  this.stub(window, 'confirm')
  this.titleInput.val('mwhaha')

  window.confirm.returns(false)
  this.view.$el.find('.cancel').click()
  ok(window.confirm.calledOnce, 'Warn on cancel')
  ok(!this.view.trigger.calledWith('cancel'), "Don't trigger cancel if declined")

  window.confirm.reset()
  this.view.trigger.reset()

  window.confirm.returns(true)
  this.view.$el.find('.cancel').click()
  ok(window.confirm.calledOnce, 'Warn on cancel again')
  ok(this.view.trigger.calledWith('cancel'), 'Do trigger cancel if accepted')
})

test('warn on leaving if unsaved changes', function() {
  setupUnsavedChangesTest(this, {title: 'nooo', body: 'blargh'})

  strictEqual(this.view.onUnload({}), undefined, 'No warning if not changed')

  this.titleInput.val('mwhaha')

  ok(this.view.onUnload({}) !== undefined, 'Returns warning if changed')
})

QUnit.module('WikiPageEditView:Validate')

test('validation of the title is only performed if the title is present', function() {
  const view = new WikiPageEditView()

  let errors = view.validateFormData({body: 'blah'})
  strictEqual(errors.title, undefined, 'no error when title is omitted')

  errors = view.validateFormData({title: 'blah', body: 'blah'})
  strictEqual(errors.title, undefined, 'no error when title is present')

  errors = view.validateFormData({title: '', body: 'blah'})
  ok(errors.title, 'error when title is present, but blank')
  ok(errors.title[0].message, 'error message when title is present, but blank')
})

QUnit.module('WikiPageEditView:JSON')

const testRights = (subject, options) =>
  test(`${subject}`, () => {
    let key
    const model = new WikiPage(options.attributes, {contextAssetString: options.contextAssetString})
    const view = new WikiPageEditView({
      model,
      WIKI_RIGHTS: options.WIKI_RIGHTS,
      PAGE_RIGHTS: options.PAGE_RIGHTS
    })
    const json = view.toJSON()
    if (options.IS) {
      for (key in options.IS) {
        strictEqual(json.IS[key], options.IS[key], `IS.${key}`)
      }
    }
    if (options.CAN) {
      for (key in options.CAN) {
        strictEqual(json.CAN[key], options.CAN[key], `CAN.${key}`)
      }
    }
    if (options.SHOW) {
      for (key in options.SHOW) {
        strictEqual(json.SHOW[key], options.SHOW[key], `SHOW.${key}`)
      }
    }
  })

testRights('IS (teacher)', {
  attributes: {editing_roles: 'teachers'},
  IS: {
    TEACHER_ROLE: true,
    STUDENT_ROLE: false,
    MEMBER_ROLE: false,
    ANYONE_ROLE: false
  }
})

testRights('IS (student)', {
  attributes: {editing_roles: 'teachers,students'},
  IS: {
    TEACHER_ROLE: false,
    STUDENT_ROLE: true,
    MEMBER_ROLE: false,
    ANYONE_ROLE: false
  }
})

testRights('IS (members)', {
  attributes: {editing_roles: 'members'},
  IS: {
    TEACHER_ROLE: false,
    STUDENT_ROLE: false,
    MEMBER_ROLE: true,
    ANYONE_ROLE: false
  }
})

testRights('IS (course anyone)', {
  attributes: {editing_roles: 'teachers,students,public'},
  IS: {
    TEACHER_ROLE: false,
    STUDENT_ROLE: false,
    MEMBER_ROLE: false,
    ANYONE_ROLE: true
  }
})

testRights('IS (group anyone)', {
  attributes: {editing_roles: 'members,public'},
  IS: {
    TEACHER_ROLE: false,
    STUDENT_ROLE: false,
    MEMBER_ROLE: false,
    ANYONE_ROLE: true
  }
})

testRights('IS (null)', {
  IS: {
    TEACHER_ROLE: true,
    STUDENT_ROLE: false,
    MEMBER_ROLE: false,
    ANYONE_ROLE: false
  }
})

testRights('CAN/SHOW (manage course)', {
  contextAssetString: 'course_73',
  attributes: {url: 'test'},
  WIKI_RIGHTS: {
    manage: true,
    publish_page: true
  },
  PAGE_RIGHTS: {
    read: true,
    update: true,
    delete: true
  },
  CAN: {
    PUBLISH: true,
    DELETE: true,
    EDIT_TITLE: true,
    EDIT_ROLES: true
  },
  SHOW: {COURSE_ROLES: true}
})

testRights('CAN/SHOW (manage group)', {
  contextAssetString: 'group_73',
  WIKI_RIGHTS: {manage: true},
  PAGE_RIGHTS: {read: true},
  CAN: {
    PUBLISH: false,
    DELETE: false,
    EDIT_TITLE: true, // new record
    EDIT_ROLES: true
  },
  SHOW: {COURSE_ROLES: false}
})

testRights('CAN/SHOW (update_content)', {
  contextAssetString: 'course_73',
  attributes: {url: 'test'},
  WIKI_RIGHTS: {read: true},
  PAGE_RIGHTS: {
    read: true,
    update_content: true
  },
  CAN: {
    PUBLISH: false,
    DELETE: false,
    EDIT_TITLE: false,
    EDIT_ROLES: false
  }
})

testRights('CAN/SHOW (null)', {
  attributes: {url: 'test'},
  CAN: {
    PUBLISH: false,
    DELETE: false,
    EDIT_TITLE: false,
    EDIT_ROLES: false
  }
})
