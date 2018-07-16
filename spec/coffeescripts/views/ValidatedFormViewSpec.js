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
import {Model} from 'Backbone'
import ValidatedFormView from 'compiled/views/ValidatedFormView'

QUnit.module('ValidatedFormView', {
  setup() {
    this.server = sinon.fakeServer.create()
    this.clock = sinon.useFakeTimers()
    this.form = new MyForm()
    $('#fixtures').append(this.form.el)
  },

  teardown() {
    this.form.$el.remove()
    $('.errorBox').remove()
    this.server.restore()
    this.clock.tick(250) // tick past errorBox animations
    this.clock.restore()
    $('#fixtures').empty()
  }
})

function sendFail(server, response) {
  if (response == null) {
    response = ''
  }
  return server.respond('POST', '/fail', [
    400,
    {'Content-Type': 'application/json'},
    JSON.stringify(response)
  ])
}

function sendSuccess(server, response) {
  if (response == null) {
    response = ''
  }
  return server.respond('POST', '/success', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(response)
  ])
}

// #
// Dummy form view for testing
class MyForm extends ValidatedFormView {
  fieldSelectors = {last_name: '[name="user[last_name]"]'}

  initialize() {
    super.initialize(...arguments)
    this.model = new Model()
    this.model.url = '/fail'
    return this.render()
  }
  template() {
    return `
      <input type="text" name="first_name" value="123">
      <input type="text" name="user[last_name]" value="123">
      <button type="submit">submit</button>
      `
  }
}

/*
* sinon eats some errors, manual sanity debugging follows
json =
  first_name: [{
    "message": "first name required"
    "type": "required"
  }]
  last_name: [{
    message: "last name required"
    type: "required"
  }]
form = new MyForm().render()
form.$el.appendTo $('#fixtures')
form.showErrors json
*/

test('displays errors when validation fails and remove them on click', 4, function() {
  this.form.on('fail', function(errors) {
    ok(errors.first_name.$errorBox.is(':visible'))
    ok(errors.last_name.$errorBox.is(':visible'))

    equal(errors.first_name.$errorBox.text(), errors.first_name[0].message)
    equal(errors.last_name.$errorBox.text(), errors.last_name[0].message)
  })

  this.form.submit()

  sendFail(this.server, {
    errors: {
      first_name: [
        {
          message: 'first name required',
          type: 'required'
        }
      ],
      last_name: [
        {
          message: 'last name required',
          type: 'required'
        }
      ]
    }
  })
})

test('triggers success, submit events', 3, function() {
  this.form.model.url = '/success'
  this.form.on('submit', () => ok(true, 'submit handler called'))

  this.form.on('success', function(resp) {
    ok(true, 'success handler called')
    equal('ok', resp, 'passes response in')
  })
  this.form.submit()
  sendSuccess(this.server, 'ok')
})

test('triggers fail, submit events', 6, function() {
  this.form.model.url = '/fail'
  this.form.on('submit', () => ok(true, 'submit handler called'))
  this.form.on('fail', function(errors, xhr, status, statusText) {
    ok(true, 'fail handler called')
    equal(errors.first_name[0].type, 'required', 'passes errors in')
    ok(xhr, 'passes xhr in')
    equal(status, 'error', 'passes status in')
    equal(statusText, 'Bad Request', 'passes statusText in')
  })
  this.form.submit()
  sendFail(this.server, {
    errors: {
      first_name: [
        {
          message: 'first name required',
          type: 'required'
        }
      ]
    }
  })
})

test('calls submit on DOM form submit', 1, function() {
  this.form.on('submit', () => ok(true, 'submitted'))
  this.form.$el.submit()
})

test('disables inputs while loading', 2, function() {
  equal(this.form.$(':disabled').length, 0)
  this.form.on('submit', () => {
    this.clock.tick(20) // disableWhileLoading does its thing in a setTimeout
    equal(this.form.$(':disabled').length, 3)
  })
  this.form.submit()
  sendSuccess(this.server)
})

test('submit delegates to saveFormData', 1, function() {
  sandbox.spy(this.form, 'saveFormData')

  this.form.submit()
  ok(this.form.saveFormData.called, 'saveFormData called')
})

test('submit calls validateBeforeSave', 1, function() {
  sandbox.spy(this.form, 'validateBeforeSave')

  this.form.submit()
  ok(this.form.validateBeforeSave.called, 'validateBeforeSave called')
})

test('submit always calls hideErrors', 1, function() {
  sandbox.spy(this.form, 'hideErrors')

  this.form.submit()
  ok(this.form.hideErrors.called, 'hideErrors called')
})

test('validateBeforeSave delegates to validateFormData, by default', 1, function() {
  sandbox.spy(this.form, 'validateFormData')

  this.form.validateBeforeSave({})
  ok(this.form.validateFormData.called, 'validateFormData called')
})

test('validate delegates to validateFormData', 1, function() {
  sandbox.spy(this.form, 'validateFormData')

  this.form.validate()
  ok(this.form.validateFormData.called, 'validateFormData called')
})

test('validate always calls hideErrors', 2, function() {
  sandbox.stub(this.form, 'validateFormData')
  sandbox.spy(this.form, 'hideErrors')

  this.form.validateFormData.returns({})
  this.form.validate()
  ok(this.form.hideErrors.called, 'hideErrors called with no errors')

  this.form.hideErrors.reset()
  this.form.validateFormData.returns({
    errors: [
      {
        type: 'required',
        message: 'REQUIRED!'
      }
    ]
  })
  this.form.validate()
  ok(this.form.hideErrors.called, 'hideErrors called with errors')
})

test('validate always calls showErrors', 2, function() {
  sandbox.stub(this.form, 'validateFormData')
  sandbox.spy(this.form, 'showErrors')

  this.form.validateFormData.returns({})
  this.form.validate()
  ok(this.form.showErrors.called, 'showErrors called with no errors')

  this.form.showErrors.reset()
  this.form.validateFormData.returns({
    errors: [
      {
        type: 'required',
        message: 'REQUIRED!'
      }
    ]
  })
  this.form.validate()
  ok(this.form.showErrors.called, 'showErrors called with errors')
})
