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
import Backbone from '@canvas/backbone'
import ContentMigration from '@canvas/content-migrations/backbone/models/ContentMigration.coffee'
import CopyCourseView from 'ui/features/content_migrations/backbone/views/CopyCourseView.coffee'
import DateShiftView from '@canvas/content-migrations/backbone/views/DateShiftView.coffee'
import ImportBlueprintSettingsView from 'ui/features/content_migrations/backbone/views/subviews/ImportBlueprintSettingsView.coffee'
import assertions from 'helpers/assertions'

QUnit.module('CopyCourseView: Initializer', {
  setup() {
    this.copyCourseView = new CopyCourseView({
      courseFindSelect: new Backbone.View(),
      dateShift: new DateShiftView({
        collection: new Backbone.Collection(),
        model: new ContentMigration(),
      }),
      importBlueprintSettings: new ImportBlueprintSettingsView({model: new ContentMigration()}),
    })
  },
  teardown() {
    return this.copyCourseView.remove()
  },
})

/* eslint-disable qunit/resolve-async */
test('it should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.copyCourseView, done, {a11yReport: true})
})
/* eslint-enable qunit/resolve-async */

test('after init, calls updateNewDates when @courseFindSelect.triggers "course_changed" event', function () {
  $('#fixtures').html(this.copyCourseView.render().el)
  const sinonSpy = sandbox.spy(this.copyCourseView.dateShift, 'updateNewDates')
  const course = {
    start_at: 'foo',
    end_at: 'bar',
  }
  this.copyCourseView.courseFindSelect.trigger('course_changed', course)
  ok(sinonSpy.calledWith(course), 'Called updateNewDates with passed in object')
})

test('does not show import blueprint settings checkbox if dest course is ineligible', function () {
  $('#fixtures').html(this.copyCourseView.render().el)
  this.copyCourseView.courseFindSelect.trigger('course_changed', {blueprint: true})
  notOk($('#importBlueprintSettingsCheckbox').is(':visible'))
})

QUnit.module('CopyCourseView: blueprint eligible course', {
  setup() {
    this.contentMigration = new ContentMigration()
    this.copyCourseView = new CopyCourseView({
      courseFindSelect: new Backbone.View(),
      dateShift: new DateShiftView({
        collection: new Backbone.Collection(),
        model: this.contentMigration,
      }),
      importBlueprintSettings: new ImportBlueprintSettingsView({model: this.contentMigration}),
      blueprint_eligible: true,
    })
  },
  teardown() {
    return this.copyCourseView.remove()
  },
})

test('does not show import blueprint settings checkbox if selected course is not blueprint', function () {
  $('#fixtures').html(this.copyCourseView.render().el)
  this.copyCourseView.courseFindSelect.trigger('course_changed', {blueprint: false})
  notOk($('#importBlueprintSettingsCheckbox').is(':visible'))
})

test('has working blueprint settings checkbox if dest course is eligible', function () {
  $('#fixtures').html(this.copyCourseView.render().el)
  this.copyCourseView.courseFindSelect.trigger('course_changed', {blueprint: true})
  ok($('#importBlueprintSettingsCheckbox').is(':visible'))
  $('#importBlueprintSettingsCheckbox').click()
  ok(this.contentMigration.get('settings').import_blueprint_settings)
})
