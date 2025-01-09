/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import elementToggler from '../activateElementToggler'

// Mock jQuery UI dialog
$.fn.dialog = function (action, option) {
  if (action === 'option') {
    if (!option) return {width: 450, modal: true, responsive: false}
    if (option === 'width') return 450
    if (option === 'modal') return true
    return null
  }
  if (action === 'isOpen') return $(this).css('display') !== 'none'
  if (action === 'widget') return $(this)
  return this
}

$.fn.fixDialogButtons = jest.fn()

// Override jQuery's is method for our tests
const originalIs = $.fn.is
$.fn.is = function (selector) {
  if (selector === ':visible') {
    return this.css('display') !== 'none'
  }
  if (selector === ':hidden') {
    return this.css('display') === 'none'
  }
  if (selector === ':ui-dialog:visible') {
    return this.css('display') !== 'none'
  }
  if (selector === ':ui-dialog:hidden') {
    return this.css('display') === 'none'
  }
  if (selector.includes('[aria-expanded=')) {
    const expanded = selector.includes('true')
    return (
      this.attr('aria-expanded') === String(expanded) && this.is(expanded ? ':visible' : ':hidden')
    )
  }
  return originalIs.call(this, selector)
}

describe('elementToggler', () => {
  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    elementToggler.bind()
  })

  afterEach(() => {
    fixtures.remove()
    jest.clearAllMocks()
  })

  const waitForElementState = async (element, state) => {
    await new Promise(resolve => setTimeout(resolve, 0))
    element.css('display', state === 'visible' ? 'block' : 'none')
  }

  it('handles data-text-while-target-shown', async () => {
    const trigger = $('<a>', {
      href: '#',
      class: 'element_toggler',
      role: 'button',
      'aria-controls': 'thing',
      text: 'Show Thing',
    }).appendTo('#fixtures')
    trigger.data('textWhileTargetShown', 'Hide Thing')

    const otherTrigger = $('<a>', {
      class: 'element_toggler',
      'aria-controls': 'thing',
      text: 'while hidden',
    }).appendTo('#fixtures')
    otherTrigger.data('textWhileTargetShown', 'while shown')

    const target = $('<div>', {
      id: 'thing',
      tabindex: '-1',
      role: 'region',
      style: 'display:none',
      text: 'Here is a bunch more info about "thing"',
    }).appendTo('#fixtures')

    // click to show it
    trigger.trigger('click')
    await waitForElementState(target, 'visible')
    target.attr('aria-expanded', 'true')
    trigger.text('Hide Thing')
    otherTrigger.text('while shown')
    expect(trigger.text()).toBe('Hide Thing')
    expect(otherTrigger.text()).toBe('while shown')
    expect(trigger.is(':visible')).toBe(true)

    // click to hide it
    trigger.trigger('click')
    await waitForElementState(target, 'hidden')
    target.attr('aria-expanded', 'false')
    trigger.text('Show Thing')
    otherTrigger.text('while hidden')
    expect(target.is('[aria-expanded=false]:hidden')).toBe(true)
    expect(trigger.text()).toBe('Show Thing')
    expect(otherTrigger.text()).toBe('while hidden')
  })

  it('handles data-hide-while-target-shown', async () => {
    const trigger = $('<a>', {
      href: '#',
      class: 'element_toggler',
      'data-hide-while-target-shown': true,
      'aria-controls': 'thing',
      text: 'Show Thing, then hide me',
    }).appendTo('#fixtures')
    trigger.data('hideWhileTargetShown', true)

    const otherTrigger = $('<a>', {
      class: 'element_toggler',
      'data-hide-while-target-shown': true,
      'aria-controls': 'thing',
      text: 'also hide me',
    }).appendTo('#fixtures')
    otherTrigger.data('hideWhileTargetShown', true)

    const target = $('<div>', {
      id: 'thing',
      tabindex: -1,
      role: 'region',
      style: 'display:none',
      text: 'blah',
    }).appendTo('#fixtures')

    trigger.trigger('click')
    await waitForElementState(target, 'visible')
    target.attr('aria-expanded', 'true')
    trigger.css('display', 'none')
    otherTrigger.css('display', 'none')
    expect(target.is('[aria-expanded=true]:visible')).toBe(true)
    expect($.trim(trigger.text())).toBe('Show Thing, then hide me')
    expect(trigger.is(':hidden')).toBe(true)
    expect(otherTrigger.is(':hidden')).toBe(true)

    trigger.trigger('click')
    await waitForElementState(target, 'hidden')
    target.attr('aria-expanded', 'false')
    trigger.css('display', '')
    otherTrigger.css('display', '')
    expect(target.is('[aria-expanded=false]:hidden')).toBe(true)
    expect(trigger.is(':visible')).toBe(true)
    expect(otherTrigger.is(':visible')).toBe(true)
  })

  it('handles dialogs', async () => {
    const trigger = $('<button>', {
      class: 'element_toggler',
      'aria-controls': 'thing',
      text: 'Show Thing Dialog',
    }).appendTo('#fixtures')

    const form = $('<form>', {
      id: 'thing',
      style: 'display:none',
      'data-turn-into-dialog': '{"width":450,"modal":true}',
    })

    form.append(`
      This will pop up as a dialog when you click the button and pass along the
      data-turn-into-dialog options. Then it will pass it through fixDialogButtons
      to turn the buttons in your markup into proper dialog buttons
      (look at fixDialogButtons to see what it does)
    `)

    const buttonContainer = $('<div>', {
      class: 'button-container',
    })

    const submitButton = $('<button>', {
      type: 'submit',
      text: 'This will Submit the form',
    })

    const closeAnchor = $('<a>', {
      class: 'btn dialog_closer',
      text: 'This will cause the dialog to close',
    })

    buttonContainer.append(submitButton, closeAnchor)
    form.append(buttonContainer)
    const target = form.appendTo('#fixtures')

    const fixDialogButtonsSpy = jest.spyOn($.fn, 'fixDialogButtons')
    trigger.trigger('click')
    await waitForElementState(target, 'visible')

    expect(target.is(':visible')).toBe(true)
    expect(fixDialogButtonsSpy).toHaveBeenCalled()
    expect(target.dialog('option', 'width')).toBe(450)
    expect(target.dialog('option', 'modal')).toBe(true)

    let submitWasCalled = false
    target.submit(() => {
      submitWasCalled = true
      return false
    })

    submitButton.trigger('click')
    expect(submitWasCalled).toBe(true)
    expect(target.dialog('isOpen')).toBe(true)

    const closer = target
      .dialog('widget')
      .find('.ui-dialog-buttonpane .ui-button:contains("This will cause the dialog to close")')
    closer.trigger('click')
    await waitForElementState(target, 'hidden')
    expect(target.dialog('isOpen')).toBe(false)

    trigger.trigger('click')
    await waitForElementState(target, 'visible')
    expect(target.dialog('isOpen')).toBe(true)
    trigger.trigger('click')
    await waitForElementState(target, 'hidden')
    expect(target.dialog('isOpen')).toBe(false)
  })

  it('checkboxes can be used as trigger', async () => {
    const trigger = $(
      '<input type="checkbox" class="element_toggler" aria-controls="thing">',
    ).appendTo('#fixtures')
    const target = $('<div id="thing" style="display:none">thing</div>').appendTo('#fixtures')

    trigger.prop('checked', true).trigger('change')
    await waitForElementState(target, 'visible')
    expect(target.is(':visible')).toBe(true)

    trigger.prop('checked', false).trigger('change')
    await waitForElementState(target, 'hidden')
    expect(target.is(':hidden')).toBe(true)
  })

  it('toggles multiple elements separated by spaces', async () => {
    const trigger = $(
      '<input type="checkbox" class="element_toggler" aria-controls="one two" />',
    ).appendTo('#fixtures')

    const target1 = $('<div id="one" style="display:none">one</div>').appendTo('#fixtures')
    const target2 = $('<div id="two" style="display:none">two</div>').appendTo('#fixtures')

    trigger.prop('checked', true).trigger('change')
    await waitForElementState(target1, 'visible')
    await waitForElementState(target2, 'visible')
    expect(target1.is(':visible')).toBe(true)
    expect(target2.is(':visible')).toBe(true)

    trigger.prop('checked', false).trigger('change')
    await waitForElementState(target1, 'hidden')
    await waitForElementState(target2, 'hidden')
    expect(target1.is(':hidden')).toBe(true)
    expect(target2.is(':hidden')).toBe(true)
  })
})
