/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, cleanup, fireEvent} from '@testing-library/react'
import DeepLinkingResponse, {RetrievingContent} from '../DeepLinkingResponse'

describe('RetrievingContent', () => {
  let component
  const windowMock = {}
  let content_items = []
  const env = () => ({
    DEEP_LINKING_POST_MESSAGE_ORIGIN: '*',
    deep_link_response: {
      content_items,
      msg: 'message',
      log: 'log',
      errormsg: 'error message',
      errorlog: 'error log',
      ltiEndpoint: 'https://www.test.com/retrieve',
      reloadpage: false,
    },
  })

  const renderComponent = () =>
    render(<RetrievingContent environment={env()} parentWindow={windowMock} />)

  beforeEach(() => {
    windowMock.postMessage = jest.fn()
  })

  afterEach(() => {
    cleanup()
  })

  describe('with no content item errors', () => {
    beforeEach(() => {
      content_items = [{type: 'link'}]
      component = renderComponent()
    })

    it('renders an informative message', () => {
      expect(component.getByTitle('Retrieving Content')).toBeInTheDocument()
    })

    it('immediately calls postMessage', () => {
      expect(windowMock.postMessage).toHaveBeenCalled()
    })
  })

  describe('with no content items', () => {
    beforeEach(() => {
      content_items = []
      component = renderComponent()
    })

    it('shows a message about no content items', () => {
      expect(component.getAllByText('The external app returned with no content.')).toHaveLength(1)
    })
  })

  describe('with errored content items', () => {
    beforeEach(() => {
      content_items = [
        {type: 'LtiResourceLink', title: 'all good'},
        {
          type: 'LtiResourceLink',
          title: 'not happy',
          errors: {fieldOne: 'error one', fieldTwo: 'error two'},
        },
      ]
      component = renderComponent()
    })

    it('shows succeeded content items just for info', () => {
      expect(component.getAllByText('Processed')).toHaveLength(1)
      expect(component.getByText(content_items[0].title)).toBeInTheDocument()
    })

    it('shows one row per errored field', () => {
      expect(component.getAllByText('Discarded')).toHaveLength(2)
      expect(component.getAllByText(content_items[1].title)).toHaveLength(2)
      expect(component.getByText(content_items[1].errors.fieldOne)).toBeInTheDocument()
      expect(component.getByText(content_items[1].errors.fieldTwo)).toBeInTheDocument()
    })

    describe('after user clicks Continue', () => {
      beforeEach(() => {
        fireEvent.click(component.getByRole('button'))
      })

      it('only sends postMessage after user clicks Continue', () => {
        expect(windowMock.postMessage).toHaveBeenCalled()
      })

      it('shows original informative message', () => {
        expect(component.getByTitle('Retrieving Content')).toBeInTheDocument()
      })
    })
  })

  describe('post message', () => {
    beforeEach(() => {
      content_items = [{type: 'link'}]
      component = renderComponent()
    })

    const messageData = () => windowMock.postMessage.mock.calls[0][0]
    ;['content_items', 'msg', 'log', 'errormsg', 'errorlog', 'ltiEndpoint', 'reloadpage'].forEach(
      attr => {
        it(`sends the correct ${attr}`, () => {
          expect(messageData()[attr]).toEqual(env().deep_link_response[attr])
        })
      },
    )

    it('sends the correct content items', () => {
      expect(messageData().content_items).toMatchObject(env().deep_link_response.content_items)
    })

    it('sends the correct subject', () => {
      expect(messageData().subject).toEqual('LtiDeepLinkingResponse')
    })
  })
})

describe('DeepLinkingResponse', () => {
  describe('targetWindow', () => {
    let windowMock

    beforeEach(() => {
      windowMock = {
        ENV: {},
        parent: 'parent',
        top: 'top',
      }
    })

    it('uses window.parent', () => {
      expect(DeepLinkingResponse.targetWindow(windowMock)).toBe(windowMock.parent)
    })

    describe('when tool is opened in new tab', () => {
      beforeEach(() => {
        windowMock.opener = 'opener'
      })

      it('uses window.opener', () => {
        expect(DeepLinkingResponse.targetWindow(windowMock)).toBe(windowMock.opener)
      })
    })
  })
})
