#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'Backbone'
  'helpers/fakeENV'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/OutcomeGroupView'
  'helpers/fixtures'
], ($, Backbone, fakeENV, OutcomeGroup, OutcomeGroupView, fixtures) ->

  createView = (opts) ->
    view = new OutcomeGroupView(opts)
    view.$el.appendTo($("#fixtures"))
    view.render()

  QUnit.module 'OutcomeGroupView',
    setup: ->
      fixtures.setup()
      fakeENV.setup()
      ENV.PERMISSIONS = {manage_outcomes: true}
      @outcomeGroup = new OutcomeGroup({
        "context_type" : "Course",
        'url': 'www.example.com',
        "context_id" : 1,
        'parent_outcome_group': {
          'subgroups_url': "www.example.com"
        }
      })

    teardown: ->
      fixtures.teardown()
      fakeENV.teardown()

  test 'placeholder text is rendered properly for new outcome groups', ->
    view = createView(state: 'add', model: @outcomeGroup)
    equal view.$('input[name="title"]').attr("placeholder"), 'New Outcome Group'
    view.remove()

  test 'validates title is present', ->
    view = createView(state: 'add', model: @outcomeGroup)
    view.$('#outcome_group_title').val("")
    ok !view.isValid()
    ok view.errors.title
    view.remove()
