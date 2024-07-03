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
import MissingDateDialogView from '../MissingDateDialogView'
import sinon from 'sinon'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let dialog

describe('MissingDateDialogView', () => {
  beforeEach(() => {
    $('#fixtures').append(
      '<label for="date">Section one</label><input type="text" id="date" name="date" />'
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
      success: sinon.spy(),
    })
  })

  afterEach(() => {
    dialog.cancel({})
    $('input[name=date]').remove()
    $('label[for=date]').remove()
    $('.ui-dialog').remove()
    $('#fixtures').empty()
  })

  // :visible doesn't work with our jsdom
  test.skip('should display a dialog if the given fields are invalid', function () {
    ok(dialog.render())
    ok($('.ui-dialog:visible').length > 0)
  })

  test('it should list the names of the sections w/o dates', function () {
    dialog.render()
    ok(
      $('.ui-dialog')
        .text()
        .match(/Section one/)
    )
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
    ok(dialog.options.success.calledOnce)
  })

  test('it displays the name for all invalid sections', function () {
    $('#fixtures').append(
      '<label for="date">Section two</label><input type="text" id="date-2" name="date" />'
    )
    $('#fixtures').append(
      '<label for="date">Section three</label><input type="text" id="date-3" name="date" />'
    )
    dialog.render()
    const dialogText = $('.ui-dialog').text()
    ok(dialogText.match(/Section one/))
    ok(dialogText.match(/Section two/))
    ok(dialogText.match(/Section three/))
  })
})
