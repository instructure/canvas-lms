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
import Backbone from '@canvas/backbone'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import assert from 'helpers/assertions'
import {closeDialog} from 'helpers/util'
import '@canvas/jquery/jquery.simulate'

let server = null
let view = null
let model = null
let trigger = null

const openDialog = () => view.$trigger.simulate('click')
const sendResponse = (method, json) =>
  server.respond(method, model.url, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(json),
  ])

QUnit.module('DialogFormView', {
  setup() {
    this.closeSpy = sandbox.spy(DialogFormView.prototype, 'close')
    server = sinon.fakeServer.create()
    model = new Backbone.Model({
      id: 1,
      is_awesome: true,
    })
    model.url = '/test'
    trigger = $('<button title="Edit Stuff" />').appendTo($('#fixtures'))
    view = new DialogFormView({
      model,
      trigger,
      template({is_awesome}) {
        return `
          <label><input
            type="checkbox"
            name="is_awesome"
            ${is_awesome ? 'checked' : undefined}
          > is awesome</label>
        `
      },
    })
  },
  teardown() {
    trigger.remove()
    server.restore()
    view.remove()
  },
})

test('opening and closing the dialog with the trigger', () => {
  assert.isHidden(view.$el, 'before click')
  openDialog()
  assert.isVisible(view.$el, 'after click')
  closeDialog()
  return assert.isHidden(view.$el, 'after dialog close')
})

test('submitting the form', () => {
  const clock = sinon.useFakeTimers()
  openDialog()
  equal(view.model.get('is_awesome'), true, 'is_awesome starts true')
  view.$('label').simulate('click')
  view.$('button[type=submit]').simulate('click')
  sendResponse('PUT', {
    id: 1,
    is_awesome: false,
  })
  clock.tick(1)
  equal(view.model.get('is_awesome'), false, 'is_awesome is updated to false')
  clock.restore()
  return assert.isHidden(view.$el, 'when form submission is complete')
})
const assertDialogTitle = function (expected, message) {
  const dialogTitle = $('.ui-dialog-title:last').html()
  equal(dialogTitle, expected, message)
}
test('gets dialog title from tigger title', () => {
  openDialog()
  assertDialogTitle(trigger.attr('title'), 'dialog title is taken from triggers title attribute')
})

test('gets dialog title from option', () => {
  view.options.title = 'different title'
  openDialog()
  assertDialogTitle(view.options.title, 'dialog title is taken from triggers title attribute')
})

test('gets dialog title from trigger aria-describedby', () => {
  trigger.removeAttr('title')
  const describer = $('<div/>', {
    html: 'aria title',
    id: 'aria-describer',
  }).appendTo($('#fixtures'))
  trigger.attr('aria-describedby', 'aria-describer')
  openDialog()
  assertDialogTitle('aria title', 'dialog title is taken from triggers title attribute')
  describer.remove()
})

test('rendering', () => {
  view.wrapperTemplate = () => 'wrapper:<div class="outlet"></div>'
  view.template = ({foo}) => foo
  view.model.set('foo', 'hello')
  equal(view.$el.html(), '', "doesn't render until opened for the first time")
  openDialog()
  ok(view.$el.html().match(/wrapper/, 'renders wrapper'))
  equal(view.$el.find('.outlet').html(), 'hello', 'renders template into outlet')
})

test('closing the dialog calls view#close', function () {
  openDialog()
  closeDialog()
  ok(this.closeSpy.called)
})

test('focuses close button when opened', () => {
  openDialog()
  equal(document.activeElement, $('.ui-dialog-titlebar-close')[0])
})
