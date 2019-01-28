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
import elementToggler from 'compiled/behaviors/elementToggler'

QUnit.module('elementToggler', {
  teardown() {
    ;[this.$trigger, this.$otherTrigger, this.$target, this.$target1, this.$target2].forEach(el => {
      if (el) el.remove()
    })
    $('#fixtures').empty()
  }
})

test('handles data-text-while-target-shown', function() {
  this.$trigger = $(`
    <a
      href="#"
      class="element_toggler"
      role="button"
      data-text-while-target-shown="Hide Thing"
      aria-controls="thing"
    >Show Thing</a>
  `).appendTo('#fixtures')

  this.$otherTrigger = $(`
    <a
      class="element_toggler"
      data-text-while-target-shown="while shown"
      aria-controls="thing"
    >while hidden</a>
  `).appendTo('#fixtures')

  this.$target = $(`
    <div id="thing" tabindex="-1" role="region" style="display:none">
      Here is a bunch more info about "thing"
    </div>
  `).appendTo('#fixtures')

  // click to show it
  this.$trigger.click()
  const msg = 'Handles `data-text-while-target-shown`'
  equal(this.$trigger.text(), 'Hide Thing', msg)
  equal(this.$otherTrigger.text(), 'while shown', msg)
  ok(
    this.$trigger.is(':visible'),
    'does not hide trigger unless `data-hide-while-target-shown` is specified'
  )
  this.$trigger.click()
  // click to hide it
  ok(this.$target.is('[aria-expanded=false]:hidden'), 'target is hidden')
  equal(this.$trigger.text(), 'Show Thing', msg)
  equal(this.$otherTrigger.text(), 'while hidden', msg)
})

test('handles data-hide-while-target-shown', function() {
  this.$trigger = $(`
    <a
      href="#"
      class="element_toggler"
      data-hide-while-target-shown="true"
      aria-controls="thing"
    >
      Show Thing, then hide me
    </a>`).appendTo('#fixtures')

  this.$otherTrigger = $(`
    <a
      class="element_toggler"
      data-hide-while-target-shown=true
      aria-controls="thing"
    >
      also hide me
    </a>
  `).appendTo('#fixtures')

  this.$target = $(`
    <div
      id="thing"
      tabindex="-1"
      role="region"
      style="display:none"
    >
      blah
    </div>
  `).appendTo('#fixtures')
  this.$trigger.click()
  ok(this.$target.is('[aria-expanded=true]:visible'), 'target is shown')
  let msg = 'Does not change text unless `data-text-while-target-shown` is specified'
  equal($.trim(this.$trigger.text()), 'Show Thing, then hide me', msg)
  msg = 'Handles `data-hide-while-target-shown`'
  ok(this.$trigger.is(':hidden'), msg)
  ok(this.$otherTrigger.is(':hidden'), msg)
  this.$trigger.click()
  ok(this.$target.is('[aria-expanded=false]:hidden'), 'target is hidden')
  ok(this.$trigger.is(':visible'), msg)
  ok(this.$otherTrigger.is(':visible'), msg)
})

test('handles dialogs', function() {
  this.$trigger = $(`<button class="element_toggler" \
aria-controls="thing">Show Thing Dialog</button>`).appendTo('#fixtures')
  this.$target = $(`
    <form id="thing" data-turn-into-dialog='{"width":450,"modal":true}' style="display:none">
      This will pop up as a dilog when you click the button and pass along the
      data-turn-into-dialog options.  then it will pass it through fixDialogButtons
      to turn the buttons in your markup into proper dialog buttons
      (look at fixDialogButtons to see what it does)
      <div class="button-container">
        <button type="submit">This will Submit the form</button>
        <a class="btn dialog_closer">This will cause the dialog to close</a>
      </div>
    </form>
  `).appendTo('#fixtures')
  let msg = 'target pops up as a dialog'
  const spy = sandbox.spy($.fn, 'fixDialogButtons')
  this.$trigger.click()
  ok(this.$target.is(':ui-dialog:visible'), msg)
  ok(spy.thisValues[0].is(this.$target), 'calls fixDialogButton on @$trigger')
  msg = 'handles `data-turn-into-dialog` options correctly'
  equal(this.$target.dialog('option', 'width'), 450, msg)
  equal(this.$target.dialog('option', 'modal'), true, msg)
  msg =
    'make sure clicking on converted ui-dialog-buttonpane .ui-button causes submit handler to be called on form'
  let submitWasCalled = false
  this.$target.submit(() => {
    submitWasCalled = true
    return false
  })
  const $submitButton = this.$target
    .dialog('widget')
    .find('.ui-dialog-buttonpane .ui-button:contains("This will Submit the form")')
  $submitButton.click()
  ok(submitWasCalled, msg)
  equal(this.$target.dialog('isOpen'), true, 'doesnt cause dialog to hide')
  msg = 'make sure clicking on the .dialog_closer causes dialog to close'
  const $closer = this.$target
    .dialog('widget')
    .find('.ui-dialog-buttonpane .ui-button:contains("This will cause the dialog to close")')
  $closer.click()
  equal(this.$target.dialog('isOpen'), false, msg)
  this.$trigger.click()
  equal(this.$target.dialog('isOpen'), true)
  this.$trigger.click()
  equal(this.$target.dialog('isOpen'), false)
})

test('checkboxes can be used as trigger', function() {
  this.$trigger = $(
    '<input type="checkbox" class="element_toggler" aria-controls="thing">'
  ).appendTo('#fixtures')
  this.$target = $('<div id="thing" style="display:none">thing</div>').appendTo('#fixtures')
  this.$trigger.prop('checked', true).trigger('change')
  ok(this.$target.is(':visible'), 'target is shown')
  this.$trigger.prop('checked', false).trigger('change')
  ok(this.$target.is(':hidden'), 'target is hidden')
})

test('toggles multiple elements separated by spaces', function() {
  this.$trigger = $(
    '<input type="checkbox" class="element_toggler" aria-controls="one two" />'
  ).appendTo('#fixtures')
  this.$target1 = $('<div id="one" style="display: none;">one</div>').appendTo('#fixtures')
  this.$target2 = $('<div id="two" style="display: none;">two</div>').appendTo('#fixtures')
  this.$trigger.prop('checked', true).trigger('change')
  ok(this.$target1.is(':visible'), 'first target is shown')
  ok(this.$target2.is(':visible'), 'second target is shown')
})
