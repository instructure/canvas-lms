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
import ContentMigration from '../../../models/ContentMigration'
import SelectContentCheckbox from '../SelectContentCheckboxView'

const ok = value => expect(value).toBeTruthy()
const notOk = value => expect(value).toBeFalsy()
const equal = (value, expected) => expect(value).toEqual(expected)

let contentMigration
let selectContentCheckbox

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

describe('SelectContentCheckbox: Blueprint Settings', () => {
  beforeEach(() => {
    contentMigration = new ContentMigration()
    selectContentCheckbox = new SelectContentCheckbox({model: contentMigration})
  })

  afterEach(() => {
    selectContentCheckbox.remove()
    $('#fixtures').html('')
  })

  test('does not show import blueprint settings checkbox if dest course is ineligible', function () {
    window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = false
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
    $('#fixtures').html(selectContentCheckbox.render().el)
    selectContentCheckbox.courseSelected({blueprint: true})
    equal($('#importBlueprintSettingsCheckbox').length, 0)
  })

  test('does not show import blueprint settings checkbox if selected course is not blueprint', function () {
    window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = true
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
    $('#fixtures').html(selectContentCheckbox.render().el)
    selectContentCheckbox.courseSelected({blueprint: false})
    $('[name=selective_import]')[0].click()
    notOk($('#importBlueprintSettingsCheckbox').is(':visible'))
  })

  test('does not show import blueprint settings checkbox if selective import is selected', function () {
    window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = true
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
    $('#fixtures').html(selectContentCheckbox.render().el)
    selectContentCheckbox.courseSelected({blueprint: false})
    $('[name=selective_import]')[1].click()
    notOk($('#importBlueprintSettingsCheckbox').is(':visible'))
  })

  test('has working blueprint settings checkbox if dest course is eligible', function () {
    window.ENV.BLUEPRINT_ELIGIBLE_IMPORT = true
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
    $('#fixtures').html(selectContentCheckbox.render().el)
    selectContentCheckbox.courseSelected({blueprint: true})
    $('[name=selective_import]')[0].click()
    // :visible doesn't work in Jest
    // ok($('#importBlueprintSettingsCheckbox').is(':visible'))
    $('#importBlueprintSettingsCheckbox').click()
    ok(contentMigration.get('settings').import_blueprint_settings)
  })
})
