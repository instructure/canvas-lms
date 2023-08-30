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
import {mount} from 'enzyme'
import moxios from 'moxios'
import MessageStudents from '../index'

describe('MessageStudents', () => {
  beforeEach(() => {
    moxios.install()
  })

  afterEach(() => {
    moxios.uninstall()
  })

  it('should render', () => {
    const wrapper = mount(
      <MessageStudents contextCode="course_1" title="Send a message" onRequestClose={() => {}} />
    )
    expect(wrapper.exists()).toBe(true)
  })

  describe('composeRequestData()', () => {
    it('simplifies recipients to an array of ids', () => {
      const wrapper = mount(
        <MessageStudents
          contextCode="course_1"
          title="Send a message"
          recipients={[{id: 1, email: 'some@one.com'}]}
          onRequestClose={() => {}}
        />
      )

      const requestData = wrapper.instance().composeRequestData()
      expect(requestData.recipients[0]).toBe(1)
    })
  })

  describe('errorMessagesFor()', () => {
    it('fetches error for a given field from state', () => {
      const wrapper = mount(
        <MessageStudents
          contextCode="course_1"
          title="Send a message"
          recipients={[{id: 1, email: 'some@one.com'}]}
          onRequestClose={() => {}}
        />
      )

      wrapper.setState({
        errors: {
          subject: 'Please provide a subject.',
        },
      })

      const errors = wrapper.instance().errorMessagesFor('subject')
      expect(errors[0].text).toBe('Please provide a subject.')
    })
  })

  describe('sendMessage()', () => {
    let wrapper
    let data

    beforeEach(() => {
      moxios.install()
      wrapper = mount(
        <MessageStudents
          title="Send a message"
          contextCode="course_1"
          subject="Here is a subject"
          body="Here is a body"
          recipients={[
            {
              id: 1,
              email: 'some@one.com',
            },
          ]}
          onRequestClose={() => {}}
        />
      )

      data = wrapper.instance().composeRequestData()
      jest.spyOn(wrapper.instance(), 'handleResponseSuccess')
      jest.spyOn(wrapper.instance(), 'handleResponseError')
    })

    afterEach(() => {
      moxios.uninstall()
      wrapper.unmount()
      jest.clearAllMocks()
    })

    it('sets state.sending', () => {
      expect(wrapper.state('sending')).toBeFalsy()
      wrapper.instance().sendMessage(data)
      expect(wrapper.state('sending')).toBeTruthy()
    })

    it('sets hideAlert to false', () => {
      wrapper.setState({hideAlert: true})
      expect(wrapper.state('hideAlert')).toBeTruthy()
      wrapper.instance().sendMessage(data)
      expect(wrapper.state('hideAlert')).toBeFalsy()
    })

    describe('on success', () => {
      beforeEach(() => {
        moxios.stubRequest('/api/v1/conversations', {
          status: 200,
        })
      })

      it('calls handleResponseSuccess', async () => {
        wrapper.instance().sendMessage(data)
        await moxios.wait(() => {
          expect(wrapper.instance().handleResponseSuccess).toHaveBeenCalledTimes(1)
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

      it('calls handleResponseError', async () => {
        wrapper.instance().sendMessage(data)
        await moxios.wait(() => {
          expect(wrapper.instance().handleResponseError).toHaveBeenCalledTimes(1)
        })
      })
    })
  })

  describe('validationErrors()', () => {
    let wrapper
    const fields = ['subject', 'body']

    beforeEach(() => {
      wrapper = mount(
        <MessageStudents contextCode="course_1" title="Send a message" onRequestClose={() => {}} />
      )
    })

    afterEach(() => {
      wrapper.unmount()
    })

    fields.forEach(field => {
      it(`validates length of ${field} and sets error`, () => {
        const data = {
          body: '',
          subject: '',
        }

        let errors = wrapper.instance().validationErrors(data)

        expect(errors).toHaveProperty(field)

        data[field] = 'a value'
        errors = wrapper.instance().validationErrors(data)

        expect(errors).not.toHaveProperty(field)
      })
    })

    it('validates max length for subject', () => {
      const data = {
        body: '',
        subject: 'x'.repeat(256),
      }

      const errors = wrapper.instance().validationErrors(data)

      expect(errors).toHaveProperty('subject')
    })
  })

  describe('handleAlertClose()', () => {
    let wrapper
    let closeButton

    beforeEach(() => {
      jest.useFakeTimers()

      wrapper = mount(
        <MessageStudents contextCode="course_1" title="Send a message" onRequestClose={() => {}} />
      )

      wrapper.setState({
        errors: {
          subject: 'provide a subject',
        },
      })

      closeButton = wrapper.find('div.MessageStudents__Alert button').hostNodes()
    })

    afterEach(() => {
      jest.clearAllTimers()
      wrapper.unmount()
    })

    it('sets state.hideAlert to true', () => {
      expect(wrapper.state('hideAlert')).toBeFalsy()

      closeButton.simulate('click')
      expect(wrapper.state('hideAlert')).toBeTruthy()
    })
  })

  describe('handleChange()', () => {
    let wrapper

    beforeEach(() => {
      wrapper = mount(
        <MessageStudents contextCode="course_1" title="Send a message" onRequestClose={() => {}} />
      )
    })

    afterEach(() => {
      wrapper.unmount()
    })

    it('sets provided field / value pair in state.data', () => {
      const messageSubject = 'This is a message subject'
      expect(wrapper.state('data').subject.length).toBe(0)

      wrapper.instance().handleChange('subject', messageSubject)
      wrapper.update()

      expect(wrapper.state('data').subject).toBe(messageSubject)
    })

    it('removes error for provided field if present', () => {
      wrapper.setState({
        errors: {
          subject: 'There was an error',
        },
      })

      expect(wrapper.state('errors')).toHaveProperty('subject')

      wrapper.instance().handleChange('subject', 'Fine here is a subject')
      wrapper.update()

      expect(wrapper.state('errors')).not.toHaveProperty('subject')
    })
  })

  describe('handleClose()', () => {
    let wrapper

    beforeEach(() => {
      wrapper = mount(
        <MessageStudents contextCode="course_1" title="Send a message" onRequestClose={() => {}} />
      )
    })

    afterEach(() => {
      wrapper.unmount()
    })

    it('sets state.open to false', () => {
      // precondition
      expect(wrapper.state('open')).toBeTruthy()

      const buttons = wrapper.find('button')
      const closeButton = buttons.at(buttons.length - 2)
      closeButton.simulate('click')

      expect(wrapper.state('open')).toBeFalsy()
    })
  })

  describe('handleSubmit()', () => {
    let wrapper
    let sendMessageMock

    beforeEach(() => {
      wrapper = mount(
        <MessageStudents
          title="Send a message"
          contextCode="course_1"
          recipients={[
            {
              id: 1,
              email: 'some@one.com',
            },
          ]}
          onRequestClose={() => {}}
        />
      )
      sendMessageMock = jest.spyOn(wrapper.instance(), 'sendMessage')
    })

    afterEach(() => {
      wrapper.unmount()
    })

    it('does not call sendMessage if errors are present', () => {
      const buttons = wrapper.find('button')
      const submitButton = buttons.at(buttons.length - 1)
      submitButton.simulate('click')
      expect(sendMessageMock).not.toHaveBeenCalled()
    })

    it('sets state errors based on validationErrors', () => {
      expect(wrapper.state('data').subject.length).toBe(0)
      expect(Object.keys(wrapper.state('errors')).includes('subject')).toBeFalsy()

      const buttons = wrapper.find('button')
      const submitButton = buttons.at(buttons.length - 1)
      submitButton.simulate('click')
      expect(Object.keys(wrapper.state('errors')).includes('subject')).toBeTruthy()
    })

    describe('with valid data', () => {
      beforeEach(() => {
        wrapper.instance().handleChange('subject', 'here is a subject')
        wrapper.instance().handleChange('body', 'here is a body')
      })

      it('does not set any errors', () => {
        expect(Object.keys(wrapper.state('errors')).includes('subject')).toBeFalsy()

        const buttons = wrapper.find('button')
        const submitButton = buttons.at(buttons.length - 1)
        submitButton.simulate('click')
        expect(Object.keys(wrapper.state('errors')).includes('subject')).toBeFalsy()
      })

      it('calls sendMessage', () => {
        const buttons = wrapper.find('button')
        const submitButton = buttons.at(buttons.length - 1)
        submitButton.simulate('click')
        expect(sendMessageMock).toHaveBeenCalled()
      })
    })
  })

  describe('handleResponseSuccess()', () => {
    let wrapper

    beforeEach(() => {
      jest.useFakeTimers()
      wrapper = mount(
        <MessageStudents
          title="Send a message"
          contextCode="course_1"
          subject="Here is a subject"
          body="Here is a body"
          recipients={[
            {
              id: 1,
              email: 'some@one.com',
            },
          ]}
          onRequestClose={() => {}}
        />
      )

      wrapper.setState({
        hideAlert: true,
        sending: true,
      })
    })

    afterEach(() => {
      jest.clearAllTimers()
      wrapper.unmount()
    })

    it('updates state accordingly', () => {
      expect(wrapper.state('hideAlert')).toBeTruthy()
      expect(wrapper.state('sending')).toBeTruthy()
      expect(wrapper.state('success')).toBeFalsy()

      wrapper.instance().handleResponseSuccess()

      expect(wrapper.state('hideAlert')).toBeFalsy()
      expect(wrapper.state('sending')).toBeFalsy()
      expect(wrapper.state('success')).toBeTruthy()
    })

    it('sets timeout to close modal', () => {
      expect(wrapper.state('open')).toBeTruthy()

      wrapper.instance().handleResponseSuccess()

      jest.advanceTimersByTime(2700)
      expect(wrapper.state('open')).toBeFalsy()
    })
  })

  describe('handleResponseError()', () => {
    let wrapper
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

      wrapper = mount(
        <MessageStudents
          title="Send a message"
          contextCode="course_1"
          recipients={[
            {
              id: 1,
              email: 'some@one.com',
            },
          ]}
          onRequestClose={() => {}}
        />
      )

      wrapper.setState({sending: true})
    })

    afterEach(() => {
      wrapper.unmount()
    })

    it('sets field errors based on errorResponse', () => {
      expect(Object.keys(wrapper.state('errors')).length).toBe(0)

      wrapper.instance().handleResponseError(errorResponse)

      expect(Object.keys(wrapper.state('errors'))).toContain('subject')
    })

    it('marks sending as false', () => {
      expect(wrapper.state('sending')).toBeTruthy()

      wrapper.instance().handleResponseError(errorResponse)

      expect(wrapper.state('sending')).toBeFalsy()
    })
  })

  describe('renderAlert()', () => {
    let wrapper

    beforeEach(() => {
      wrapper = mount(
        <MessageStudents
          title="Send a message"
          contextCode="course_1"
          recipients={[
            {
              id: 1,
              email: 'some@one.com',
            },
          ]}
          onRequestClose={() => {}}
        />
      )
    })

    afterEach(() => {
      wrapper.unmount()
    })

    it('is null if provided callback is not truthy', () => {
      const callback = () => false
      expect(wrapper.instance().renderAlert('Alert Message', 'info', callback)).toBeNull()
    })

    it('renders alert component if callback returns true', () => {
      const callback = () => true
      expect(wrapper.instance().renderAlert('Alert Message', 'info', callback)).toBeTruthy()
    })

    it('is null if state.hideAlert is true', () => {
      const callback = () => true
      expect(wrapper.instance().renderAlert('Alert Message', 'info', callback)).toBeTruthy()

      wrapper.setState({hideAlert: true})
      expect(wrapper.instance().renderAlert('Alert Message', 'info', callback)).toBeNull()
    })
  })
})
