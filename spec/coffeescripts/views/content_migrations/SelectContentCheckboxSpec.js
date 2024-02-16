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
import 'jquery-migrate'
import ContentMigration from '@canvas/content-migrations/backbone/models/ContentMigration'
import SelectContentCheckbox from '@canvas/content-migrations/backbone/views/subviews/SelectContentCheckboxView'

QUnit.module('SelectContentCheckbox: Blueprint Settings', {
  setup() {
    this.contentMigration = new ContentMigration()
    this.SelectContentCheckbox = new SelectContentCheckbox({model: this.contentMigration})
  },
  teardown() {
    return this.SelectContentCheckbox.remove()
  },
})

test('does not show import blueprint settings checkbox if dest course is ineligible', function () {
  window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = false
  window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
  $('#fixtures').html(this.SelectContentCheckbox.render().el)
  this.SelectContentCheckbox.courseSelected({blueprint: true})
  equal($('#importBlueprintSettingsCheckbox').length, 0)
})

test('does not show import blueprint settings checkbox if selected course is not blueprint', function () {
  window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = true
  window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
  $('#fixtures').html(this.SelectContentCheckbox.render().el)
  this.SelectContentCheckbox.courseSelected({blueprint: false})
  $('[name=selective_import]')[0].click()
  notOk($('#importBlueprintSettingsCheckbox').is(':visible'))
})

test('does not show import blueprint settings checkbox if selective import is selected', function () {
  window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = true
  window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
  $('#fixtures').html(this.SelectContentCheckbox.render().el)
  this.SelectContentCheckbox.courseSelected({blueprint: false})
  $('[name=selective_import]')[1].click()
  notOk($('#importBlueprintSettingsCheckbox').is(':visible'))
})

test('has working blueprint settings checkbox if dest course is eligible', function () {
  window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = true
  window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
  $('#fixtures').html(this.SelectContentCheckbox.render().el)
  this.SelectContentCheckbox.courseSelected({blueprint: true})
  $('[name=selective_import]')[0].click()
  ok($('#importBlueprintSettingsCheckbox').is(':visible'))
  $('#importBlueprintSettingsCheckbox').click()
  ok(this.contentMigration.get('settings').import_blueprint_settings)
})
