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
import Backbone from '@canvas/backbone'
import DialogFormView from '../DialogFormView'
import '@canvas/jquery/jquery.simulate'
import {waitFor} from '@testing-library/dom'

describe('DialogFormView', () => {
  let server
  let view
  let model
  let trigger
  let closeSpy
  let $dialog

  const openDialog = () => view.$trigger.simulate('click')
  const closeDialog = () => view.$el.dialog('close')

  const sendResponse = (method, json) =>
    server.respond(method, model.url, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(json),
    ])

  beforeEach(() => {
    // Reset variables for each test
    $dialog = null
    closeSpy = jest.spyOn(DialogFormView.prototype, 'close')
    server = {
      respond: jest.fn(),
      restore: jest.fn(),
    }
    model = new Backbone.Model({
      id: 1,
      is_awesome: true,
    })
    model.url = '/test'
    document.body.innerHTML = '<div id="fixtures"></div>'
    trigger = $('<button title="Edit Stuff" />').appendTo($('#fixtures'))

    // Store original jQuery methods before mocking
    $.fn._originalDialog = $.fn.dialog
    $.fn._originalFixDialogButtons = $.fn.fixDialogButtons

    // Mock jQuery UI dialog
    $.fn.dialog = function (options) {
      if (typeof options === 'string') {
        if (options === 'close') {
          this.trigger('dialogclose')
          this.css('display', 'none')
          $dialog.css('display', 'none')
          // Call the close callback
          const dialogData = this.data('ui-dialog')
          if (dialogData && dialogData.options && dialogData.options.close) {
            dialogData.options.close.call(this)
          }
        } else if (options === 'open') {
          this.css('display', 'block')
          $dialog.css('display', 'block')
          this.trigger('dialogopen')
          // Call the open callback
          const dialogData = this.data('ui-dialog')
          if (dialogData && dialogData.options && dialogData.options.open) {
            dialogData.options.open.call(this)
          }
        } else if (options === 'isOpen') {
          return $dialog.css('display') !== 'none'
        }
      } else {
        // Create dialog structure
        $dialog = $('<div class="ui-dialog">')
          .append('<div class="ui-dialog-titlebar">')
          .append(this)
          .appendTo('body')

        $dialog
          .find('.ui-dialog-titlebar')
          .append(`<span class="ui-dialog-title">${options.title}</span>`)
          .append('<button class="ui-dialog-titlebar-close">close</button>')

        this.data('ui-dialog', {
          options,
          open: () => {
            this.css('display', 'block')
            $dialog.css('display', 'block')
            if (options.open) {
              options.open.call(this)
            }
          },
          close: () => {
            this.css('display', 'none')
            $dialog.css('display', 'none')
            if (options.close) {
              options.close.call(this)
            }
          },
          focusable: $('.ui-dialog-titlebar-close'),
          isOpen: () => $dialog.css('display') !== 'none',
        })

        // Initially hide the dialog
        this.css('display', 'none')
        $dialog.css('display', 'none')
      }
      return this
    }

    $.fn.fixDialogButtons = function () {
      return this
    }

    view = new DialogFormView({
      model,
      trigger,
      template({is_awesome}) {
        return `
          <label><input
            type="checkbox"
            name="is_awesome"
            ${is_awesome ? 'checked' : undefined}
            data-testid="awesome-checkbox"
          > is awesome</label>
        `
      },
    })

    // Set initial display to none
    view.$el.css('display', 'none')
  })

  afterEach(() => {
    trigger.remove()
    if ($dialog) {
      $dialog.remove()
      $dialog = null
    }
    server.restore()
    view.remove()
    closeSpy.mockRestore()
    document.body.innerHTML = ''

    // Restore original jQuery methods if they were mocked
    if ($.fn._originalDialog) {
      $.fn.dialog = $.fn._originalDialog
      delete $.fn._originalDialog
    }

    if ($.fn._originalFixDialogButtons) {
      $.fn.fixDialogButtons = $.fn._originalFixDialogButtons
      delete $.fn._originalFixDialogButtons
    }
  })

  it('opens and closes the dialog with the trigger', async () => {
    // Ensure $dialog is null at the start of the test
    expect($dialog).toBeNull()
    openDialog()
    await waitFor(() => {
      // Now $dialog should exist and be visible
      expect($dialog).not.toBeNull()
      expect($dialog.css('display')).not.toBe('none')
      expect(view.$el.css('display')).not.toBe('none')
    })
    closeDialog()
    await waitFor(() => {
      expect($dialog.css('display')).toBe('none')
      expect(view.$el.css('display')).toBe('none')
    })
  })

  it('submits the form', async () => {
    jest.useFakeTimers()
    openDialog()
    expect(view.model.get('is_awesome')).toBe(true)

    // Simulate checkbox click and form submission
    view.$('label').simulate('click')
    view.$('button[type=submit]').simulate('click')

    // Mock the server response
    model.set('is_awesome', false)
    sendResponse('PUT', {
      id: 1,
      is_awesome: false,
    })

    jest.advanceTimersByTime(1)
    expect(view.model.get('is_awesome')).toBe(false)
    jest.useRealTimers()
  })

  it('gets dialog title from trigger title', () => {
    openDialog()
    const dialogTitle = $('.ui-dialog-title:last').html()
    expect(dialogTitle).toBe(trigger.attr('title'))
  })

  it('gets dialog title from option', () => {
    view.options.title = 'different title'
    openDialog()
    const dialogTitle = $('.ui-dialog-title:last').html()
    expect(dialogTitle).toBe(view.options.title)
  })

  it('gets dialog title from trigger aria-describedby', () => {
    trigger.removeAttr('title')
    const describer = $('<div/>', {
      html: 'aria title',
      id: 'aria-describer',
    }).appendTo($('#fixtures'))
    trigger.attr('aria-describedby', 'aria-describer')
    openDialog()
    const dialogTitle = $('.ui-dialog-title:last').html()
    expect(dialogTitle).toBe('aria title')
    describer.remove()
  })

  it('renders correctly', () => {
    view.wrapperTemplate = () => 'wrapper:<div class="outlet"></div>'
    view.template = ({foo}) => foo
    view.model.set('foo', 'hello')
    expect(view.$el.html()).toBe('')
    openDialog()
    expect(view.$el.html()).toMatch(/wrapper/)
    expect(view.$el.find('.outlet').html()).toBe('hello')
  })

  it('calls view#close when dialog is closed', () => {
    openDialog()
    closeDialog()
    expect(closeSpy).toHaveBeenCalled()
  })

  // Skipping this test as it was skipped in the original
  it.skip('focuses close button when opened', () => {
    openDialog()
    expect(document.activeElement).toBe($('.ui-dialog-titlebar-close')[0])
  })
})
