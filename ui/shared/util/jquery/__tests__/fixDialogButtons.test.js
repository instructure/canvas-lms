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
import '../fixDialogButtons'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/jquery/jquery.simulate'

describe('fixDialogButtons', () => {
  let $dialog
  let fixturesDiv

  beforeEach(() => {
    jest.useFakeTimers()
    fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)

    // Mock offset since jQuery UI uses it for positioning
    const originalOffset = $.fn.offset
    $.fn.offset = function () {
      if (this.length === 0) return {top: 0, left: 0}
      if (originalOffset) {
        return originalOffset.apply(this, arguments)
      }
      return {top: 0, left: 0}
    }

    $dialog = $(`
      <form style="display:none">
        when this gets turned into a dialog, it should
        turn the buttons in the markup into proper dialog buttons
        <button class="btn" type="button">Should NOT be converted</button>
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
      .dialog({
        modal: true,
        zIndex: 1000,
        autoOpen: true,
        height: 'auto',
        width: 400,
      })
      .fixDialogButtons()

    // Force dialog to be visible in JSDOM
    const dialogWidget = $dialog.dialog('widget')
    dialogWidget.css('display', 'block')
    dialogWidget.find('.ui-dialog-content').css('display', 'block')
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
    if ($dialog.data('dialog')) {
      $dialog.dialog('destroy')
    }
    fixturesDiv.remove()
  })

  it('creates a visible dialog with proper buttons', () => {
    const dialogWidget = $dialog.dialog('widget')
    expect(dialogWidget.css('display')).toBe('block')
    expect($dialog.dialog('option', 'buttons')).toHaveLength(2)
  })

  it('only hides buttons in the button-container', () => {
    const $regularButton = $dialog.find('.btn[type="button"]')
    const $containerButtons = $dialog.find('.button-container .btn')

    expect($regularButton.css('display')).not.toBe('none')
    expect($containerButtons.length).toBeGreaterThan(0)
    expect($containerButtons.filter(':visible')).toHaveLength(0)
  })

  it('handles form submission with loading state', () => {
    const $submitButton = $dialog.find('.btn[type="submit"]')
    const originalButtonText = $submitButton.text().trim()
    const deferred = new $.Deferred()
    let submitWasCalled = false

    $dialog.submit(e => {
      e.preventDefault()
      $dialog.disableWhileLoading(deferred)
      submitWasCalled = true
    })

    $submitButton.click()
    expect(submitWasCalled).toBe(true)
    expect($dialog.dialog('isOpen')).toBe(true)

    jest.advanceTimersByTime(14)
    expect($submitButton.text().trim()).toBe('while loading')

    deferred.resolve()
    jest.advanceTimersByTime(14)
    expect($submitButton.text().trim()).toBe(originalButtonText)
  })

  it('closes dialog when clicking dialog_closer button', () => {
    const $closer = $dialog
      .dialog('widget')
      .find('.ui-dialog-buttonpane .ui-button:contains("This will cause the dialog to close")')

    $closer.click()
    expect($dialog.dialog('isOpen')).toBe(false)
  })
})
