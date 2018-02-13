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
import ProgressStatusView from 'compiled/views/content_migrations/ProgressStatusView'
import ProgressingModel from 'compiled/models/ProgressingContentMigration'
import assertions from 'helpers/assertions'

QUnit.module('ProgressStatusViewSpec', {
  setup() {
    this.progressingModel = new ProgressingModel()
    this.psv = new ProgressStatusView({model: this.progressingModel})
    this.$fixtures = $('#fixtures')
  },
  teardown() {
    return this.psv.remove()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.$fixtures, done, {a11yReport: true})
})

test('displays progress workflow_state when migrations workflow_state is running', function() {
  this.progressingModel.set('workflow_state', 'running') // this is a migration
  this.progressingModel.progressModel.set('workflow_state', 'foo')
  this.$fixtures.append(this.psv.render().el)
  equal(this.psv.$el.find('.label').text(), 'Foo', 'Displays correct workflow state')
})

test('displays migration workflow_state when migrations workflow_state is not running', function() {
  this.progressingModel.set('workflow_state', 'some_not_running_state')
  this.$fixtures.append(this.psv.render().el)
  equal(
    this.psv.$el.find('.label').text(),
    'Some not running state',
    'Displays correct workflow state'
  )
})

test('adds label-success class to status when status is complete', function() {
  this.progressingModel.set('workflow_state', 'complete')
  this.$fixtures.append(this.psv.render().el)
  ok(this.psv.$el.find('.label-success'), 'Adds the label-success class')
})

test('adds label-important class to status when status is failed', function() {
  this.progressingModel.set('workflow_state', 'failed')
  this.$fixtures.append(this.psv.render().el)
  ok(this.psv.$el.find('.label-important'), 'Adds the label-important class')
})

test('adds label-info class to status when status is running', function() {
  this.progressingModel.set('workflow_state', 'running')
  this.progressingModel.progressModel.set('workflow_state', 'running')
  this.$fixtures.append(this.psv.render().el)
  ok(this.psv.$el.find('.label-info'), 'Adds the label-info class')
})
