/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import axios from 'axios'
import MessageStudents from 'jsx/shared/MessageStudents'
import Transition from '@instructure/ui-core/lib/components/Transition'

let $domNode, subject, fixtures

const renderComponent = props => {
  $domNode = document.createElement('div')
  fixtures.appendChild($domNode)
  return ReactDOM.render(<MessageStudents {...props} />, $domNode)
}

QUnit.module('MessageStudents', hooks => {
  hooks.beforeEach(() => {
    fixtures = document.getElementById('fixtures')
    const appElement = document.createElement('div')
    appElement.id = 'application'
    fixtures.appendChild(appElement)
  })
  hooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($domNode)
    $domNode = null
    subject = null
    fixtures.innerHTML = ''
  })

  test('it renders', () => {
    subject = renderComponent({
      contextCode: 'course_1',
      title: 'Send a message'
    })
    ok(subject)
  })

  QUnit.module('composeRequestData()', () => {
    test('simplifies recipients to an array of ids', () => {
      subject = renderComponent({
        title: 'Send a message',
        contextCode: 'course_1',
        recipients: [{
          id: 1, email: 'some@one.com'
        }]
      })

      const requestData = subject.composeRequestData()
      const recipient = requestData.recipients[0]
      notEqual(typeof recipient, 'object')
      equal(recipient, 1)
    })
  })

  QUnit.module('errorMessagesFor()', () => {
    test('fetches error for a given field from state', () => {
      subject = renderComponent({
        contextCode: 'course_1',
        title: 'Send a message'
      })
      const errorMessage = 'Please provide a subject.'
      subject.setState({
        errors: {
          subject: errorMessage
        }
      })
      const errors = subject.errorMessagesFor('subject')
      equal(errors[0].text, errorMessage)
    })
  })

  QUnit.module('sendMessage()', hooks => {
    let data, successPromise, errorPromise

    hooks.beforeEach(() => {
      successPromise = Promise.resolve()
      const errorResponse = {
        data: {
          attribute: 'subject',
          message: 'blank'
        }
      }
      errorPromise = Promise.reject(errorResponse)

      subject = renderComponent({
        title: 'Send a message',
        contextCode: 'course_1',
        subject: 'Here is a subject',
        body: 'Here is a body',
        recipients: [{
          id: 1, email: 'some@one.com'
        }]
      })
      data = subject.composeRequestData()
      sinon.spy(subject, 'handleResponseSuccess')
      sinon.spy(subject, 'handleResponseError')
    })

    hooks.afterEach(() => {
      subject.handleResponseSuccess.restore()
      subject.handleResponseError.restore()
    })

    test('sets state.sending', () => {
      notOk(subject.state.sending, 'precondition, should not be sending')
      subject.sendMessage(data)
      ok(subject.state.sending)
    })

    test('sets hideAlert to false', () => {
      subject.setState({hideAlert: true})
      ok(subject.state.hideAlert, 'precondition, should not be hideAlert')
      subject.sendMessage(data)
      notOk(subject.state.hideAlert)
    })

    QUnit.module('on success', hooks => {
      hooks.beforeEach(() => {
        sinon.stub(axios, 'post').returns(successPromise)
      })

      hooks.afterEach(() => {
        axios.post.restore()
      })

      test('calls handleResponseSuccess', assert => {
        const done = assert.async()
        subject.sendMessage(data)
        successPromise.then(() => {
          ok(subject.handleResponseSuccess.calledOnce)
          done()
        })
      })
    })

    QUnit.module('on error', hooks => {
      hooks.beforeEach(() => {
        sinon.stub(axios, 'post').returns(errorPromise)
      })

      hooks.afterEach(() => {
        axios.post.restore()
      })

      test('calls handleResponseSuccess', assert => {
        const done = assert.async()
        subject.sendMessage(data)
        Promise.all([errorPromise]).catch(() => {
          ok(subject.handleResponseError.calledOnce)
          done()
        })
      })
    })
  })

  QUnit.module('validationErrors()', hooks => {
    const fields = ['subject', 'body']

    hooks.beforeEach(() => {
      subject = renderComponent({
        contextCode: 'course_1',
        title: 'Send a message'
      })
    })

    fields.forEach(field => {
      test(`validates length of ${field} and sets error`, () => {
        const data = {
          body: '',
          subject: ''
        }
        let errors = subject.validationErrors(data)
        ok(errors.hasOwnProperty(field))
        data[field] = 'a value'
        errors = subject.validationErrors(data)
        ok(!errors.hasOwnProperty(field))
      })
    })

    test('validates max length for subject', () => {
      const data = {
        body: '',
        subject: 'x'.repeat(256)
      }
      const errors = subject.validationErrors(data)
      ok(errors.hasOwnProperty('subject'))
    })
  })

  QUnit.module('handleAlertClose()', hooks => {
    let closeButton
    let clocks

    hooks.beforeEach(() => {
      subject = renderComponent({
        contextCode: 'course_1',
        title: 'Send a message'
      })
      subject.setState({
        errors: {
          subject: 'provide a subject'
        }
      })
      closeButton = document.querySelector('div.MessageStudents__Alert button')
      clocks = sinon.useFakeTimers()
    })

    hooks.afterEach(() => {
      clocks.restore()
    })

    test('sets state.hideAlert to true', () => {
      notOk(subject.state.hideAlert, 'precondition')
      TestUtils.Simulate.click(closeButton)
      // can remove these ticks once this ticket is resolved
      // https://instructure.atlassian.net/browse/INSTUI-607
      clocks.tick(Transition.duration)
      clocks.tick(Transition.duration)
      ok(subject.state.hideAlert)
    })
  })

  QUnit.module('handleChange()', hooks => {
    hooks.beforeEach(() => {
      subject = renderComponent({
        contextCode: 'course_1',
        title: 'Send a message'
      })
    })

    test('sets provided field / value pair in state.data', () => {
      const messageSubject = 'This is a message subject'
      strictEqual(subject.state.data.subject.length, 0)

      subject.handleChange('subject', messageSubject)
      equal(subject.state.data.subject, messageSubject)
    })

    test('removes error for provided field if present', () => {
      subject.setState({
        errors: {
          subject: 'There was an error'
        }
      })
      ok(subject.state.errors.hasOwnProperty('subject'))

      subject.handleChange('subject', 'Fine here is a subject')
      ok(!subject.state.errors.hasOwnProperty('subject'))
    })
  })

  QUnit.module('handleClose()', hooks => {
    let closeButton

    hooks.beforeEach(() => {
      subject = renderComponent({
        contextCode: 'course_1',
        title: 'Send a message'
      })
      const buttons = document.querySelectorAll('button')
      closeButton = buttons[buttons.length - 2]
    })

    test('sets state.open to false', () => {
      ok(subject.state.open, 'precondition, should be open')
      TestUtils.Simulate.click(closeButton)
      notOk(subject.state.open)
    })
  })

  QUnit.module('handleSubmit()', hooks => {
    let submitButton

    hooks.beforeEach(() => {
      subject = renderComponent({
        title: 'Send a message',
        contextCode: 'course_1',
        recipients: [{
          id: 1, email: 'some@one.com'
        }]
      })
      sinon.spy(subject, 'sendMessage')

      const buttons = document.querySelectorAll('button')
      submitButton = buttons[buttons.length - 1]
    })

    hooks.afterEach(() => {
      subject.sendMessage.restore()
    })

    test('does not call sendMessage if errors are present', () => {
      TestUtils.Simulate.click(submitButton)
      ok(subject.sendMessage.notCalled)
    })

    test('sets state errors based on validationErrors', () => {
      strictEqual(
        subject.state.data.subject.length,
        0,
        'precondition, subject is blank'
      )
      notOk(
        Object.keys(subject.state.errors).includes('subject'),
        'precondition, no errors on subject'
      )
      TestUtils.Simulate.click(submitButton)
      ok(Object.keys(subject.state.errors).includes('subject'))
    })

    test('sets state.hideAlert to false if errors are present', () => {
      subject.setState({hideAlert: true})
      ok(subject.state.hideAlert, 'precondition')
      TestUtils.Simulate.click(submitButton)
      notOk(subject.state.hideAlert)
    })

    QUnit.module('with valid data', hooks => {
      hooks.beforeEach(() => {
        subject.handleChange('subject', 'here is a subject')
        subject.handleChange('body', 'here is a body')
      })

      test('does not set any errors', () => {
        notOk(
          Object.keys(subject.state.errors).includes('subject'),
          'precondition, no errors on subject'
        )
        TestUtils.Simulate.click(submitButton)
        notOk(Object.keys(subject.state.errors).includes('subject'))
      })

      test('calls sendMessage', () => {
        TestUtils.Simulate.click(submitButton)
        ok(subject.sendMessage.calledOnce)
      })
    })
  })

  QUnit.module('handleResponseSuccess()', hooks => {
    let clocks

    hooks.beforeEach(() => {
      clocks = sinon.useFakeTimers()
      subject = renderComponent({
        title: 'Send a message',
        contextCode: 'course_1',
        subject: 'Here is a subject',
        body: 'Here is a body',
        recipients: [{
          id: 1, email: 'some@one.com'
        }]
      })
      subject.setState({
        hideAlert: true,
        sending: true
      })
    })

    hooks.afterEach(() => {
      clocks.restore()
    })

    test('updates state accordingly', () => {
      ok(subject.state.hideAlert, 'precondition, hideAlert should be true')
      ok(subject.state.sending, 'precondition, sending should be true')
      notOk(subject.state.success, 'precondition, success should be false')

      subject.handleResponseSuccess()

      notOk(subject.state.hideAlert)
      notOk(subject.state.sending)
      ok(subject.state.success)
    })

    test('sets timeout to close modal', () => {
      ok(subject.state.open, 'precondition, should be open')

      subject.handleResponseSuccess()

      clocks.tick(2700)
      ok(!subject.state.open)
    })
  })

  QUnit.module('handleResponseError()', hooks => {
    let errorResponse

    hooks.beforeEach(() => {
      errorResponse = {
        response: {
          data: [{
            attribute: 'subject', message: 'blank'
          }]
        }
      }

      subject = renderComponent({
        title: 'Send a message',
        contextCode: 'course_1',
        recipients: [{
          id: 1,
          email: 'some@one.com'
        }]
      })
      subject.setState({sending: true})
    })

    test('sets field errors based on errorResponse', () => {
      strictEqual(
        Object.keys(subject.state.errors).length,
        0,
        'precondition, no error present on subject'
      )

      subject.handleResponseError(errorResponse)

      ok(Object.keys(subject.state.errors).includes('subject'))
    })

    test('marks sending as false', () => {
      ok(subject.state.sending, 'precondition, is sending')

      subject.handleResponseError(errorResponse)
      notOk(subject.state.sending)
    })
  })

  QUnit.module('renderAlert()', hooks => {
    hooks.beforeEach(() => {
      subject = renderComponent({
        title: 'Send a message',
        contextCode: 'course_1',
        recipients: [{
          id: 1, email: 'some@one.com'
        }]
      })
    })

    test('is null if provided callback is not truthy', () => {
      const callback = () => false
      notOk(subject.renderAlert('Alert Message', 'info', callback))
    })

    test('renders alert component if callback returns true', () => {
      const callback = () => true
      ok(subject.renderAlert('Alert Message', 'info', callback))
    })

    test('is null if state.hideAlert is true', () => {
      const callback = () => true
      ok(subject.renderAlert('Alert Message', 'info', callback), 'precondition')

      subject.setState({hideAlert: true})
      notOk(subject.renderAlert('Alert Message', 'info', callback))
    })
  })
})
