/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import 'compiled/jquery/fixDialogButtons'
import 'jquery.disableWhileLoading'
import 'helpers/jquery.simulate'

QUnit.module('fixDialogButtons', {
  setup() {
    this.clock = sinon.useFakeTimers()
  },
  teardown() {
    this.clock.restore()
    $('#fixtures').empty()
  }
})

test('handles buttons', function() {
  const $dialog = $(`
<form style="display:none">
  when this gets turned into a dialog, it should
  turn the buttons in the markup into proper dialog buttons
  <button class="btn">Should NOT be converted</button>
  <div class="button-container">
    <button class="btn" data-text-while-loading="while loading" type="submit">
      This will Submit the form
    </button>
    <a class="btn dialog_closer">
      This will cause the dialog to close
    </a>
  </div>
</form>
`)
    .appendTo('#fixtures')
    .dialog()
    .fixDialogButtons()
  ok($dialog.is(':ui-dialog:visible'), 'pops up dialog')
  equal($dialog.dialog('option', 'buttons').length, 2, 'converts both buttons in .button-pane only')
  let msg = 'hides the original .buttons in the .button-container only'
  $dialog.find('.btn').each(function() {
    equal($(this).is(':hidden'), $(this).text() !== 'Should NOT be converted', msg)
  })
  msg =
    'make sure clicking on converted ui-dialog-button causes submit handler to be called on form'
  const $submitButton = $dialog
    .dialog('widget')
    .find('.ui-dialog-buttonpane .ui-button:contains("This will Submit the form")')
  const originalButtonText = $submitButton.text()
  const deferred = new $.Deferred()
  let submitWasCalled = false
  $dialog.submit(e => {
    e.preventDefault()
    $dialog.disableWhileLoading(deferred)
    return (submitWasCalled = true)
  })
  $submitButton.click()
  ok(submitWasCalled, msg)
  equal($dialog.dialog('isOpen'), true, 'doesnt cause dialog to hide')

  // give disabledWhileLoadingTimeToDoIts Thing
  this.clock.tick(14)
  equal($submitButton.text(), 'while loading', 'copies over text-while-loading on buttons')
  deferred.resolve()
  equal($submitButton.text(), originalButtonText, 'restores text-while-loading')
  msg = 'make sure clicking on the .dialog_closer causes dialog to close'
  const $closer = $dialog
    .dialog('widget')
    .find('.ui-dialog-buttonpane .ui-button:contains("This will cause the dialog to close")')
  $closer.click()
  equal($dialog.dialog('isOpen'), false, msg)
  $dialog.remove() // clean up
})
