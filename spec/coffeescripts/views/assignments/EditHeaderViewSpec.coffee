#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'compiled/models/Assignment'
  'compiled/views/assignments/EditHeaderView'
  'jst/assignments/EditView'
  'helpers/fakeENV'
  'Backbone'
], ($, _, Assignment, EditHeaderView, editViewTemplate, fakeENV, Backbone) ->

  defaultAssignmentOpts =
    name: 'Test Assignment'
    assignment_overrides: []

  editHeaderView = (assignmentOptions = {}, viewOptions = {}) ->
    $.extend(assignmentOptions, defaultAssignmentOpts)
    assignment = new Assignment assignmentOptions

    app = new EditHeaderView
      model: assignment
      views:
        'edit_assignment_form': new Backbone.View
          template: editViewTemplate
      userIsAdmin: viewOptions.userIsAdmin

    app.render()

  QUnit.module 'EditHeaderView',
    setup: ->
      fakeENV.setup({
        current_user_roles: ['teacher']
      })
      $(document).on 'submit', -> false
    teardown: ->
      fakeENV.teardown()
      $(document).off 'submit'

  test 'renders', ->
    view = editHeaderView()
    ok view.$('.header-bar-right').length > 0, 'header bar is rendered'

  test 'delete works for an un-saved assignment', ->
    view = editHeaderView()
    cb = @stub(view, 'onDeleteSuccess')

    view.delete()
    equal cb.called, true, 'onDeleteSuccess was called'

  test "disallows deleting frozen assignments", ->
    view = editHeaderView(frozen: true)
    ok view.$(".delete_assignment_link.disabled").length

  test "disallows deleting assignments due in closed grading periods", ->
    view = editHeaderView(in_closed_grading_period: true)
    ok view.$(".delete_assignment_link.disabled").length

  test "allows deleting non-frozen assignments not due in closed grading periods", ->
    view = editHeaderView(frozen: false, in_closed_grading_period: false)
    ok view.$(".delete_assignment_link:not(.disabled)").length

  test "allows deleting frozen assignments for admins", ->
    view = editHeaderView({ frozen: true }, { userIsAdmin: true })
    ok view.$(".delete_assignment_link:not(.disabled)").length

  test "allows deleting assignments due in closed grading periods for admins", ->
    view = editHeaderView({ in_closed_grading_period: true }, { userIsAdmin: true })
    ok view.$(".delete_assignment_link:not(.disabled)").length

  test 'does not attempt to delete an assignment due in a closed grading period', ->
    view = editHeaderView(in_closed_grading_period: true)

    @stub(window, "confirm").returns(true)
    @spy view, "delete"

    view.$(".delete_assignment_link").click()

    ok window.confirm.notCalled
    ok view.delete.notCalled

  QUnit.module 'EditHeaderView - ConditionalRelease',
    setup: ->
      fakeENV.setup()
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    teardown: ->
      fakeENV.teardown()

  test 'disables conditional release tab on load when grading type is not_graded', ->
    view = editHeaderView({ grading_type: 'not_graded' })
    equal true, view.$headerTabsCr.tabs('option', 'disabled')

  test 'enables conditional release tab when grading type switched from not_graded', ->
    view = editHeaderView({ grading_type: 'not_graded' })
    view.onGradingTypeUpdate({target: { value: 'points' }})
    equal false, view.$headerTabsCr.tabs('option', 'disabled')

  test 'disables conditional release tab when grading type switched to not_graded', ->
    view = editHeaderView({ grading_type: 'points' })
    view.onGradingTypeUpdate({target: { value: 'not_graded' }})
    equal true, view.$headerTabsCr.tabs('option', 'disabled')

  test 'switches to conditional release tab if save error contains conditional release error', ->
    view = editHeaderView({ grading_type: 'points' })
    view.editView.updateConditionalRelease = () => {}

    view.$headerTabsCr.tabs('option', 'active', 0)
    view.onShowErrors({ foo: 'bar', conditional_release: 'baz' })
    equal 1, view.$headerTabsCr.tabs('option', 'active')

  test 'switches to details tab if save error does not contain conditional release error', ->
    view = editHeaderView({ grading_type: 'points' })
    view.editView.updateConditionalRelease = () => {}

    view.$headerTabsCr.tabs('option', 'active', 1)
    view.onShowErrors({ foo: 'bar', baz: 'bat' })
    equal 0, view.$headerTabsCr.tabs('option', 'active')
