/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import fakeENV from 'helpers/fakeENV'
import OutcomeContentBase from '@canvas/outcomes/content-view/backbone/views/OutcomeContentBase'
import OutcomeGroup from '@canvas/outcomes/backbone/models/OutcomeGroup'
import OutcomeGroupView from '@canvas/outcomes/content-view/backbone/views/OutcomeGroupView'
import fixtures from 'helpers/fixtures'

// stub function that creates the RCE to avoid
// its async initializationa
OutcomeContentBase.prototype.readyForm = () => {}

const createView = function (opts) {
  const view = new OutcomeGroupView(opts)
  view.$el.appendTo($('#fixtures'))
  return view.render()
}

QUnit.module('OutcomeGroupView as a teacher', {
  setup() {
    fixtures.setup()
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    this.outcomeGroup = new OutcomeGroup({
      context_type: 'Course',
      url: 'www.example.com',
      context_id: 1,
      parent_outcome_group: {subgroups_url: 'www.example.com'},
      description: 'blah',
      can_edit: true,
    })
  },
  teardown() {
    fixtures.teardown()
    fakeENV.teardown()
  },
})

test('placeholder text is rendered properly for new outcome groups', function () {
  const view = createView({
    state: 'add',
    model: this.outcomeGroup,
  })
  equal(view.$('input[name="title"]').attr('placeholder'), 'New Outcome Group')
  view.remove()
})

test('validates title is present', function () {
  const view = createView({
    state: 'add',
    model: this.outcomeGroup,
  })
  view.$('#outcome_group_title').val('')
  ok(!view.isValid())
  ok(view.errors.title)
  view.remove()
})

test('move, edit, and delete buttons appear', function () {
  const view = createView({
    state: 'show',
    model: this.outcomeGroup,
  })
  ok(view.$('.move_group_button').is(':visible'))
  view.remove()
})

test('move, edit, and delete buttons do not appear when read only', function () {
  const view = createView({
    state: 'show',
    model: this.outcomeGroup,
    readOnly: true,
  })
  ok(!view.$('.move_group_button').is(':visible'))
  view.remove()
})

QUnit.module('OutcomeGroupView as a student', {
  setup() {
    fixtures.setup()
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: false}
    this.outcomeGroup = new OutcomeGroup({
      context_type: 'Course',
      url: 'www.example.com',
      context_id: 1,
      parent_outcome_group: {subgroups_url: 'www.example.com'},
      description: 'blah',
      can_edit: false,
    })
  },
  teardown() {
    fixtures.teardown()
    fakeENV.teardown()
  },
})

test('move, edit, and delete buttons do not appear', function () {
  const view = createView({
    state: 'show',
    model: this.outcomeGroup,
  })
  ok(!view.$('.move_group_button').is(':visible'))
  view.remove()
})
