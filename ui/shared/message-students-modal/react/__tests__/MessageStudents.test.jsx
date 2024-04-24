/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import moxios from 'moxios'
import {render, cleanup} from '@testing-library/react'
import {userEvent} from '@testing-library/user-event'
import MessageStudents from '../index'

const getButtonFromDocument = (index = 0) => {
  const buttons = document.querySelectorAll('button')

  return buttons[buttons.length + index]
}

const getDefaultProps = () => ({
  contextCode: 'course_1',
  title: 'Send a message',
  recipients: [{id: 1, email: 'some@one.com'}],
  onRequestClose: () => {},
})

const renderMessageStudents = (props = {}) => {
  const activeProps = {...getDefaultProps(), ...props}
  const ref = React.createRef()
  const wrapper = render(<MessageStudents {...activeProps} ref={ref} />)

  return {
    wrapper,
    ref,
  }
}

describe('MessageStudents', () => {
  beforeEach(() => {
    moxios.install()
  })

  afterEach(() => {
    cleanup()
    moxios.uninstall()
  })

  it('should render', () => {
    const {wrapper} = renderMessageStudents()

    expect(wrapper.container).toBeInTheDocument()
  })

  describe('composeRequestData()', () => {
    it('simplifies recipients to an array of ids', () => {
      const props = getDefaultProps()
      const {ref} = renderMessageStudents()

      const result = ref.current.composeRequestData()

      expect(result.recipients[0]).toBe(props.recipients[0].id)
    })
  })

  describe('errorMessagesFor()', () => {
    it('fetches error for a given field from state', () => {
      const {ref} = renderMessageStudents()

      ref.current.setState({
        errors: {
          subject: 'Please provide a subject.',
        },
      })

      const errors = ref.current.errorMessagesFor('subject')

      expect(errors[0].text).toBe('Please provide a subject.')
    })
  })

  describe('sendMessage()', () => {
    let ref
    let data

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference
      data = ref.current.composeRequestData()

      jest.spyOn(ref.current, 'handleResponseSuccess')
      jest.spyOn(ref.current, 'handleResponseError')
    })

    it('sets state.sending', () => {
      expect(ref.current.state.sending).toBeFalsy()

      ref.current.sendMessage(data)

      expect(ref.current.state.sending).toBeTruthy()
    })

    it('sets hideAlert to false', () => {
      ref.current.setState({hideAlert: true})

      expect(ref.current.state.hideAlert).toBeTruthy()

      ref.current.sendMessage(data)

      expect(ref.current.state.hideAlert).toBeFalsy()
    })

    describe('on success', () => {
      beforeEach(() => {
        moxios.stubRequest('/api/v1/conversations', {
          status: 200,
        })
      })

      it('calls handleResponseSuccess', done => {
        ref.current.sendMessage(data)

        moxios.wait(() => {
          expect(ref.current.handleResponseSuccess).toHaveBeenCalledTimes(1)
          done()
        })
      })
    })

    describe('on error', () => {
      beforeEach(() => {
        moxios.stubRequest('/api/v1/conversations', {
          status: 500,
          response: [{attribute: 'fake', message: 'error'}],
        })
      })

      it('calls handleResponseError', done => {
        ref.current.sendMessage(data)

        moxios.wait(() => {
          expect(ref.current.handleResponseError).toHaveBeenCalledTimes(1)
          done()
        })
      })
    })
  })

  describe('validationErrors()', () => {
    let ref
    const fields = ['subject', 'body']

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference
    })

    fields.forEach(field => {
      it(`validates length of ${field} and sets error`, () => {
        const data = {
          body: '',
          subject: '',
        }
        let errors = ref.current.validationErrors(data)

        expect(errors).toHaveProperty(field)

        data[field] = 'a value'
        errors = ref.current.validationErrors(data)

        expect(errors).not.toHaveProperty(field)
      })
    })

    it('validates max length for subject', () => {
      const data = {
        body: '',
        subject: 'x'.repeat(256),
      }

      const errors = ref.current.validationErrors(data)

      expect(errors).toHaveProperty('subject')
    })
  })

  describe('handleAlertClose()', () => {
    let ref
    let closeButton

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference

      ref.current.setState({
        errors: {
          subject: 'provide a subject',
        },
      })

      closeButton = document.querySelector('div.MessageStudents__Alert button')
    })

    it('sets state.hideAlert to true', async () => {
      expect(ref.current.state.hideAlert).toBeFalsy()

      await userEvent.click(closeButton)

      expect(ref.current.state.hideAlert).toBeTruthy()
    })
  })

  describe('handleChange()', () => {
    let ref

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference
    })

    it('sets provided field / value pair in state.data', () => {
      const messageSubject = 'This is a message subject'
      expect(ref.current.state.data.subject.length).toBe(0)

      ref.current.handleChange('subject', messageSubject)

      expect(ref.current.state.data.subject).toBe(messageSubject)
    })

    it('removes error for provided field if present', () => {
      ref.current.setState({
        errors: {
          subject: 'There was an error',
        },
      })

      expect(ref.current.state.errors).toHaveProperty('subject')

      ref.current.handleChange('subject', 'Fine here is a subject')

      expect(ref.current.state.errors).not.toHaveProperty('subject')
    })
  })

  describe('handleClose()', () => {
    let ref

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference
    })

    it('sets state.open to false', async () => {
      expect(ref.current.state.open).toBeTruthy()

      const closeButton = getButtonFromDocument(-2)

      await userEvent.click(closeButton)

      expect(ref.current.state.open).toBeFalsy()
    })
  })

  describe('handleSubmit()', () => {
    let ref
    let sendMessageMock

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference

      sendMessageMock = jest.spyOn(ref.current, 'sendMessage')
    })

    it('does not call sendMessage if errors are present', async () => {
      const submitButton = getButtonFromDocument(-1)

      await userEvent.click(submitButton)

      expect(sendMessageMock).not.toHaveBeenCalled()
    })

    it('sets state errors based on validationErrors', async () => {
      const submitButton = getButtonFromDocument(-1)

      expect(ref.current.state.data.subject.length).toBe(0)
      expect(Object.keys(ref.current.state.errors).includes('subject')).toBeFalsy()

      await userEvent.click(submitButton)

      expect(Object.keys(ref.current.state.errors).includes('subject')).toBeTruthy()
    })

    describe('with valid data', () => {
      beforeEach(() => {
        ref.current.handleChange('subject', 'here is a subject')
        ref.current.handleChange('body', 'here is a body')
      })

      it('does not set any errors', async () => {
        const submitButton = getButtonFromDocument(-1)

        expect(Object.keys(ref.current.state.errors).includes('subject')).toBeFalsy()

        await userEvent.click(submitButton)

        expect(Object.keys(ref.current.state.errors).includes('subject')).toBeFalsy()
      })

      it('calls sendMessage', async () => {
        const submitButton = getButtonFromDocument(-1)

        await userEvent.click(submitButton)

        expect(sendMessageMock).toHaveBeenCalled()
      })
    })
  })

  describe('handleResponseSuccess()', () => {
    let ref

    beforeEach(() => {
      jest.useFakeTimers()

      const {ref: reference} = renderMessageStudents({
        subject: 'Here is a subject',
        body: 'Here is a body',
      })

      ref = reference

      ref.current.setState({
        hideAlert: true,
        sending: true,
      })
    })

    afterEach(() => {
      jest.clearAllTimers()
    })

    it('updates state accordingly', () => {
      expect(ref.current.state.hideAlert).toBeTruthy()
      expect(ref.current.state.sending).toBeTruthy()
      expect(ref.current.state.success).toBeFalsy()

      ref.current.handleResponseSuccess()

      expect(ref.current.state.hideAlert).toBeFalsy()
      expect(ref.current.state.sending).toBeFalsy()
      expect(ref.current.state.success).toBeTruthy()
    })

    it('sets timeout to close modal', () => {
      expect(ref.current.state.open).toBeTruthy()

      ref.current.handleResponseSuccess()
      jest.advanceTimersByTime(2700)

      expect(ref.current.state.open).toBeFalsy()
    })
  })

  describe('handleResponseError()', () => {
    let ref
    let errorResponse

    beforeEach(() => {
      errorResponse = {
        response: {
          data: [
            {
              attribute: 'subject',
              message: 'blank',
            },
          ],
        },
      }

      const {ref: reference} = renderMessageStudents()

      ref = reference

      ref.current.setState({sending: true})
    })

    it('sets field errors based on errorResponse', () => {
      expect(Object.keys(ref.current.state.errors).length).toBe(0)

      ref.current.handleResponseError(errorResponse)

      expect(Object.keys(ref.current.state.errors)).toContain('subject')
    })

    it('marks sending as false', () => {
      expect(ref.current.state.sending).toBeTruthy()

      ref.current.handleResponseError(errorResponse)

      expect(ref.current.state.sending).toBeFalsy()
    })
  })

  describe('renderAlert()', () => {
    let ref

    beforeEach(() => {
      const {ref: reference} = renderMessageStudents()

      ref = reference
    })

    it('is null if provided callback is not truthy', () => {
      const callback = jest.fn().mockReturnValue(false)

      const result = ref.current.renderAlert('Alert Message', 'info', callback)

      expect(callback).toHaveBeenCalled()
      expect(result).toBeFalsy()
    })

    it('renders alert component if callback returns true', () => {
      const callback = jest.fn().mockReturnValue(true)

      const result = ref.current.renderAlert('Alert Message', 'info', callback)

      expect(callback).toHaveBeenCalled()
      expect(result).toBeTruthy()
    })

    it('is null if state.hideAlert is true', () => {
      const callback = jest.fn().mockReturnValue(true)

      ref.current.renderAlert('Alert Message', 'info', callback)
      ref.current.setState({hideAlert: true})

      const result = ref.current.renderAlert('Alert Message', 'info', callback)

      expect(callback).toHaveBeenCalledTimes(2)
      expect(result).toBeNull()
    })
  })
})
