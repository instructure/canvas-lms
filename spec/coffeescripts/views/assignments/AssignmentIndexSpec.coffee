#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'Backbone'
  'compiled/models/AssignmentGroup'
  'compiled/models/Course'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/IndexView'
  'compiled/views/assignments/ToggleShowByView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, AssignmentGroup, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, ToggleShowByView, $, fakeENV) ->


  fixtures = $('#fixtures')

  assignmentGroups = null

  assignmentIndex = () ->
    $('<div id="content"></div>').appendTo fixtures

    course = new Course {id: 1}

    group1 = new AssignmentGroup
      name: "Group 1"
      assignments: [{id: 1, name: 'Foo Name'}, {id: 2, name: 'Bar Title'}]
    group2 = new AssignmentGroup
      name: "Group 2"
      assignments: [{id: 1, name: 'Baz Title'}, {id: 2, name: 'Qux Name'}]
    assignmentGroups = new AssignmentGroupCollection [group1, group2],
      course: course

    assignmentGroupsView = new AssignmentGroupListView
      collection: assignmentGroups
      course: course

    showByView = false
    if !ENV.PERMISSIONS.manage
      showByView = new ToggleShowByView
        course: course
        assignmentGroups: assignmentGroups

    app = new IndexView
      assignmentGroupsView: assignmentGroupsView
      collection: assignmentGroups
      createGroupView: false
      assignmentSettingsView: false
      showByView: showByView

    app.render()

  QUnit.module 'assignmentIndex',
    setup: ->
      fakeENV.setup(PERMISSIONS: {manage: true})
      @enable_spy = @spy(IndexView.prototype, 'enableSearch')

    teardown: ->
      fakeENV.teardown()
      assignmentGroups = null
      fixtures.empty()

  test 'should filter by search term', ->

    view = assignmentIndex()
    $('#search_term').val('foo')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 1

    $('#search_term').val('BooBerry')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 0

    $('#search_term').val('name')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 2

  test 'should have search disabled on render', ->
    view = assignmentIndex()
    ok view.$('#search_term').is(':disabled')

  test 'should enable search on assignmentGroup reset', ->
    view = assignmentIndex()
    assignmentGroups.reset()
    ok !view.$('#search_term').is(':disabled')

  test 'enable search handler should only fire on the first reset', ->
    view = assignmentIndex()
    assignmentGroups.reset()
    ok @enable_spy.calledOnce
    #reset a second time and make sure it was still only called once
    assignmentGroups.reset()
    ok @enable_spy.calledOnce

  test 'should show modules column', ->
    view = assignmentIndex()

    [a1, a2] = assignmentGroups.assignments()
    a1.set 'modules', ['One', 'Two']
    a2.set 'modules', ['Three']

    ok view.$("#assignment_1 .modules .tooltip_link").text().match(/Multiple Modules/)
    ok view.$("#assignment_1 .modules").text().match(/One\s+Two/)
    ok view.$("#assignment_2 .modules").text().match(/Three Module/)

  test "should show 'Add Quiz/Test' button if quiz lti is enabled", ->
    ENV.PERMISSIONS.manage_course = true
    ENV.QUIZ_LTI_ENABLED = true
    view = assignmentIndex()
    $button = view.$('.new_quiz_lti')
    equal $button.length, 1
    ok /\?quiz_lti$/.test $button.attr('href')

  test "should not show 'Add Quiz/Test' button if quiz lti is not enabled", ->
    ENV.PERMISSIONS.manage_course = true
    ENV.QUIZ_LTI_ENABLED = false
    view = assignmentIndex()
    equal $('.new_quiz_lti').length, 0


  QUnit.module 'student index view',
    setup: ->
      fakeENV.setup(PERMISSIONS: {manage: false})

    teardown: ->
      fakeENV.teardown()
      assignmentGroups = null
      fixtures.empty()

  test 'should clear search on toggle', ->
    clear_spy = @spy(IndexView.prototype, 'clearSearch')
    view = assignmentIndex()
    view.$('#search_term').val('something')
    view.showByView.toggleShowBy({preventDefault: -> })
    equal view.$('#search_term').val(), ""
    ok clear_spy.called
