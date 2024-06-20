/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import DialogBaseView from '../index'

describe('DialogBaseView', () => {
  beforeEach(() => {
    // Setup by removing any existing dialogs
    const $dialog = $('.ui-dialog')
    if ($dialog.length) {
      $dialog.remove()
    }
    document.body.innerHTML = '<div id="fixtures"></div>' // Container for dialogs
  })

  afterEach(() => {
    // Cleanup by removing dialogs after each test
    const $dialog = $('.ui-dialog')
    if ($dialog.length) {
      $dialog.remove()
    }
  })

  test('it removes the created dialog upon close when the destroy option is set', () => {
    const dialog = new DialogBaseView({destroy: true, container: '#fixtures'})
    expect($('.ui-dialog').length).toBe(1)
    dialog.close()
    expect($('.ui-dialog').length).toBe(0)
  })

  test('if destroy is not specified as an option it only hides the dialog', () => {
    const dialog = new DialogBaseView({id: 'test_id_314', container: '#fixtures'})
    expect($('.ui-dialog').length).toBe(1)
    dialog.close()
    expect($('.ui-dialog').length).toBe(1)
    expect($('.ui-dialog:visible').length).toBe(0)
  })
})
