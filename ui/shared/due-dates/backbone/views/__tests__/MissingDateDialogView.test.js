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
import {registerFixDialogButtonsPlugin} from '@canvas/enhanced-user-content/jquery'
import MissingDateDialogView from '../MissingDateDialogView'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

// Mock getClientRects for jQuery UI positioning - must be before any jQuery UI usage
Element.prototype.getClientRects = function () {
  return [
    {
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
      width: 0,
      height: 0,
    },
  ]
}

let dialog

describe('MissingDateDialogView', () => {
  beforeAll(() => {
    // Register jQuery plugin needed by dialogs
    registerFixDialogButtonsPlugin()
  })

  beforeEach(() => {
    $('#fixtures').append(
      '<label for="date">Section one</label><input type="text" id="date" name="date" />',
    )

    dialog = new MissingDateDialogView({
      validationFn() {
        const invalidFields = []
        $('input[name=date]').each(function () {
          if ($(this).val() === '') {
            invalidFields.push($(this))
          }
        })
        if (invalidFields.length > 0) {
          return invalidFields
        } else {
          return true
        }
      },
      success: vi.fn(),
    })
  })

  afterEach(() => {
    dialog.cancel({})
    $('input[name=date]').remove()
    $('label[for=date]').remove()
    $('.ui-dialog').remove()
    $('#fixtures').empty()
  })

  test('should display a dialog if the given fields are invalid', function () {
    ok(dialog.render())
    // Use existence check instead of :visible which doesn't work in JSDOM
    ok($('.ui-dialog').length > 0)
  })

  test('should not display a dialog if the given fields are valid', function () {
    $('input[name=date]').val('2013-01-01')
    equal(dialog.render(), false)
    equal($('.ui-dialog').length, 0)
  })

  test('should close the dialog on secondary button press', function () {
    dialog.render()
    dialog.$dialog.find('.btn:not(.btn-primary)').click()
    equal($('.ui-dialog').length, 0)
  })

  test('should run the success callback on on primary button press', function () {
    dialog.render()
    dialog.$dialog.find('.btn-primary').click()
    expect(dialog.options.success).toHaveBeenCalledTimes(1)
  })
})
