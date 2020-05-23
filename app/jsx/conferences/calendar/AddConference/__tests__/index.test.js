/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {render, fireEvent, act, within} from '@testing-library/react'
import {wait} from '@testing-library/dom'
import AddConference from '../index'
import {destroyContainer} from 'jsx/shared/FlashAlert'

const pluginConference = {
  id: 1,
  conference_type: 'SecretConference'
}

function getProps(props = {}) {
  return {
    context: 'course_1',
    currentConferenceType: null,
    conferenceTypes: [],
    setConference: Function.prototype,
    ...props
  }
}

function mockPost() {
  let innerResponse
  fetchMock.post(
    '/api/v1/courses/1/conferences',
    new Promise(resolve => {
      innerResponse = resolve
    })
  )
  const sendResponse = async value => {
    await act(async () => {
      innerResponse(value)
      await fetchMock.flush(true)
    })
  }
  return sendResponse
}

describe('AddConference', () => {
  afterEach(() => {
    fetchMock.reset()
    destroyContainer()
  })

  it('renders error text if no conference types available', () => {
    const {getByText, queryByRole} = render(<AddConference {...getProps()} />)
    expect(getByText('No conferencing options enabled')).not.toBeNull()
    expect(queryByRole('button')).toBeNull()
    expect(queryByRole('combobox')).toBeNull()
  })

  describe('with one conference type', () => {
    const conferenceTypes = [{type: 'SecretConference', name: 'Secret Conference'}]

    it('renders a button', () => {
      const {getByRole} = render(<AddConference {...getProps({conferenceTypes})} />)
      const button = getByRole('button')
      expect(button.textContent).toEqual('Add Secret Conference')
    })

    it('has default text', () => {
      const badType = [{type: 'BadConference'}]
      const {getByRole} = render(<AddConference {...getProps({conferenceTypes: badType})} />)
      const button = getByRole('button')
      expect(button.textContent).toEqual('Add Conferencing')
    })

    describe('plugin conferences', () => {
      async function launchPlugin(overrides = {}) {
        const props = getProps({conferenceTypes, ...overrides})
        const rendered = render(<AddConference {...props} />)
        const button = rendered.getByText('Add Secret Conference')
        await act(async () => {
          fireEvent.click(button)
        })
        return rendered
      }

      describe('success', () => {
        const conf = JSON.stringify(pluginConference)

        it('creates a plugin style conference when pressed', async () => {
          const sendResponse = mockPost()
          const setConference = jest.fn()
          await launchPlugin({setConference})
          await sendResponse(conf)
          expect(setConference).toHaveBeenCalledWith(pluginConference)
        })

        it('shows a spinner while conference is creating', async () => {
          const sendResponse = mockPost()
          const {getByTitle, queryByTitle} = await launchPlugin()
          expect(getByTitle('Creating conference')).not.toBeNull()
          await sendResponse(conf)
          expect(queryByTitle('Creating conference')).toBeNull()
        })
      })

      describe('failure', () => {
        it('resets if conference creation fails', async () => {
          const sendResponse = mockPost()
          const setConference = jest.fn()
          const {queryByTitle} = await launchPlugin({setConference})
          await sendResponse(400)
          expect(queryByTitle('Creating conference')).toBeNull()
          expect(setConference).not.toHaveBeenCalled()
        })

        it('renders an error if conference creation fails', async () => {
          const sendResponse = mockPost()
          await launchPlugin()
          await sendResponse(400)
          const alert = within(document.body).getByRole('alert')
          expect(alert.textContent).toMatch(/An error occurred/)
        })
      })
    })

    describe('LTI conferences', () => {
      const ltiConferenceTypes = [
        {name: 'LTI Tool', type: 'LtiConference', lti_settings: {tool_id: '1'}}
      ]

      function postMessage(content_items) {
        act(() => {
          fireEvent(
            document.defaultView,
            new MessageEvent('message', {
              origin: 'invalid://test',
              data: {
                messageType: 'LtiDeepLinkingResponse',
                content_items
              }
            })
          )
        })
      }

      beforeEach(() => {
        ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'invalid://test'
      })

      function launchLTI(overrides = {}) {
        const props = getProps({conferenceTypes: ltiConferenceTypes, ...overrides})
        const rendered = render(<AddConference {...props} />)
        const button = rendered.getByText('Add LTI Tool')
        act(() => {
          fireEvent.click(button)
        })
        return rendered
      }

      it('launches an LTI dialog when pressed', () => {
        launchLTI()
        const dialog = within(document.body).getByRole('dialog')
        const heading = within(dialog).getByText('Add LTI Tool')
        expect(heading).not.toBeNull()
      })

      it('shows a spinner while conference is creating', () => {
        const {getByTitle} = launchLTI()
        expect(getByTitle('Creating conference')).not.toBeNull()
      })

      it('calls set conference callback when complete', () => {
        const setConference = jest.fn()
        const {queryByTitle} = launchLTI({setConference})

        postMessage([{title: 'MyLink', text: 'My description', type: 'link'}])
        const conference = {
          title: 'MyLink',
          description: 'My description',
          conference_type: 'LtiConference',
          lti_settings: {type: 'link', tool_id: '1'}
        }
        expect(queryByTitle('Creating conference')).toBeNull()
        expect(setConference).toHaveBeenCalledWith(conference)
      })

      it('provides a default title if none available', () => {
        const setConference = jest.fn()
        launchLTI({setConference})

        postMessage([{type: 'link'}])
        const conference = {
          title: 'LTI Tool Conference',
          description: '',
          conference_type: 'LtiConference',
          lti_settings: {type: 'link', tool_id: '1'}
        }
        expect(setConference).toHaveBeenCalledWith(conference)
      })

      it('renders an error if conference creation fails', async () => {
        launchLTI()
        postMessage([])
        const alert = within(document.body).getByRole('alert')
        expect(alert.textContent).toMatch(/No valid LTI resource/)
      })

      it('resets button if conference creation is canceled', async () => {
        const {findByText} = launchLTI()
        act(() => {
          fireEvent.click(within(document.body).getByText('Close'))
        })
        expect(await findByText('Add LTI Tool')).not.toBeNull()
      })

      it('accepts HTML responses', () => {
        const setConference = jest.fn()
        launchLTI({setConference})
        postMessage([{type: 'html'}])
        expect(setConference).toHaveBeenCalled()
      })

      it('does not accept LtiLink responses', () => {
        const setConference = jest.fn()
        launchLTI({setConference})
        postMessage([{type: 'ltiLink'}])
        expect(setConference).not.toHaveBeenCalled()
      })
    })
  })

  describe('with muliple conference types', () => {
    const conferenceTypes = [
      {type: 'SecretConference', name: 'Secret Conference'},
      {type: 'FooConference', name: 'Foo Conference'}
    ]

    it('renders a select if multiple conference types are available', () => {
      const {getByRole} = render(<AddConference {...getProps({conferenceTypes})} />)
      const select = getByRole('button')
      expect(select.value).toEqual('Add Conferencing')
    })

    it('creates a conference when an option is selected', async () => {
      const sendResponse = mockPost()
      const setConference = jest.fn()
      const {getByRole, findByText} = render(
        <AddConference {...getProps({conferenceTypes, setConference})} />
      )
      const select = getByRole('button')
      act(() => {
        fireEvent.click(select)
      })
      const option = await findByText('Secret Conference')
      act(() => {
        fireEvent.click(option)
      })
      await sendResponse({id: 1})
      await wait(() => expect(setConference).toHaveBeenCalledWith({id: 1}))
    })

    it('renders the current conference type as selected if it exists', () => {
      const currentConferenceType = conferenceTypes[1]
      const {getByRole} = render(
        <AddConference {...getProps({conferenceTypes, currentConferenceType})} />
      )
      const select = getByRole('button')
      expect(select.value).toEqual('Foo Conference')
    })

    it('creates a new conference if another conference type is selected', async () => {
      const currentConferenceType = conferenceTypes[1]
      const sendResponse = mockPost()
      const setConference = jest.fn()
      const {getByRole, findByText} = render(
        <AddConference {...getProps({conferenceTypes, currentConferenceType, setConference})} />
      )
      const select = getByRole('button')
      act(() => {
        fireEvent.click(select)
      })
      const option = await findByText('Secret Conference')
      act(() => {
        fireEvent.click(option)
      })
      await sendResponse({id: 1})
      await wait(() => expect(setConference).toHaveBeenCalledWith({id: 1}))
    })

    it('does no clear the current conference if the same type is selected', async () => {
      const currentConferenceType = conferenceTypes[1]
      mockPost()
      const setConference = jest.fn()
      const {getByRole, findByText} = render(
        <AddConference {...getProps({conferenceTypes, currentConferenceType, setConference})} />
      )
      const select = getByRole('button')
      act(() => {
        fireEvent.click(select)
      })
      const option = await findByText('Foo Conference')
      act(() => {
        fireEvent.click(option)
      })
      expect(fetchMock.calls().length).toEqual(0)
    })
  })
})
