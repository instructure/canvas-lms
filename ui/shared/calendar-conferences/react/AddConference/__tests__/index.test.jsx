// @vitest-environment jsdom
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
import {render, fireEvent, act, within} from '@testing-library/react'
import AddConference from '../index'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const pluginConference = {
  conference_type: 'SecretConference',
  title: 'Secret Conference Conference',
  description: '',
}

function getProps(props = {}) {
  return {
    context: 'course_1',
    currentConferenceType: null,
    conferenceTypes: [],
    setConference: Function.prototype,
    ...props,
  }
}

describe('AddConference', () => {
  afterEach(() => {
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
      const badType = [{type: 'BadConference', name: 'Conferencing'}]
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
        it('creates a plugin style conference when pressed', async () => {
          const setConference = jest.fn()
          await launchPlugin({setConference})
          expect(setConference).toHaveBeenCalledWith(pluginConference)
        })
      })

      it('sets inputRef', async () => {
        const inputRef = jest.fn()
        await launchPlugin({inputRef})
        expect(inputRef).toHaveBeenCalled()
      })
    })

    describe('LTI conferences', () => {
      const ltiConferenceTypes = [
        {name: 'LTI Tool', type: 'LtiConference', lti_settings: {tool_id: '1'}},
      ]

      function postMessage(content_items) {
        act(() => {
          fireEvent(
            document.defaultView,
            new MessageEvent('message', {
              origin: 'invalid://test',
              data: {
                subject: 'LtiDeepLinkingResponse',
                content_items,
              },
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
          lti_settings: {type: 'link', tool_id: '1'},
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
          lti_settings: {type: 'link', tool_id: '1'},
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

      it('receives launch settings via Deep Linking response', () => {
        const setConference = jest.fn()
        launchLTI({setConference})

        const content_item = {
          type: 'link',
          iframe: {
            src: 'https://foo.bar',
            width: '111',
            length: '222',
          },
        }
        postMessage([content_item])

        const conference = {
          title: 'LTI Tool Conference',
          description: '',
          conference_type: 'LtiConference',
          lti_settings: {
            type: 'link',
            tool_id: '1',
            url: 'https://foo.bar',
          },
        }
        expect(setConference).toHaveBeenCalledWith(conference)
      })
    })
  })

  describe('with muliple conference types', () => {
    const conferenceTypes = [
      {type: 'SecretConference', name: 'Secret Conference'},
      {type: 'FooConference', name: 'Foo Conference'},
    ]

    it('renders a select if multiple conference types are available', () => {
      const {getByRole} = render(<AddConference {...getProps({conferenceTypes})} />)
      const select = getByRole('combobox')
      expect(select.value).toEqual('Add Conferencing')
    })

    it('renders the current conference type as selected if it exists', () => {
      const currentConferenceType = conferenceTypes[1]
      const {getByRole} = render(
        <AddConference {...getProps({conferenceTypes, currentConferenceType})} />
      )
      const select = getByRole('combobox')
      expect(select.value).toEqual('Foo Conference')
    })

    it('creates a new conference if another conference type is selected', async () => {
      const currentConferenceType = conferenceTypes[1]
      const setConference = jest.fn()
      const {getByRole, findByText} = render(
        <AddConference {...getProps({conferenceTypes, currentConferenceType, setConference})} />
      )
      const select = getByRole('combobox')
      act(() => {
        fireEvent.click(select)
      })
      const option = await findByText('Secret Conference')
      act(() => {
        fireEvent.click(option)
      })
      expect(setConference).toHaveBeenCalled()
    })

    it('does no clear the current conference if the same type is selected', async () => {
      const currentConferenceType = conferenceTypes[1]
      const setConference = jest.fn()
      const {getByRole, findByText} = render(
        <AddConference {...getProps({conferenceTypes, currentConferenceType, setConference})} />
      )
      const select = getByRole('combobox')
      act(() => {
        fireEvent.click(select)
      })
      const option = await findByText('Foo Conference')
      act(() => {
        fireEvent.click(option)
      })
      expect(setConference).not.toHaveBeenCalled()
    })

    it('sets inputRef', async () => {
      const inputRef = jest.fn()
      render(<AddConference {...getProps({conferenceTypes, inputRef})} />)
      expect(inputRef).toHaveBeenCalled()
    })
  })
})
