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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import ContentTypeExternalToolDrawer from '../ContentTypeExternalToolDrawer'
import MutexManager from '@canvas/mutex-manager/MutexManager'

describe('ContentTypeExternalToolDrawer', () => {
  const tool = {
    id: '1',
    base_url: 'https://lti1.example.com/',
    title: 'First LTI',
    pinned: true,
    placement: 'top_navigation',
  }
  const onDismiss = jest.fn()
  const onExternalContentReady = jest.fn()
  const pageContent = (() => {
    const el = document.createElement('div')
    el.setAttribute('id', 'page-content-id')
    el.textContent = 'page-content-text'
    return el
  })()
  const pageContentTitle = 'page-content-title'

  function renderTray(props) {
    return render(
      <ContentTypeExternalToolDrawer
        tool={tool}
        pageContent={pageContent}
        pageContentTitle={pageContentTitle}
        pageContentMinWidth="40rem"
        trayPlacement="end"
        onDismiss={onDismiss}
        onExternalContentReady={onExternalContentReady}
        open={true}
        {...props}
      />
    )
  }

  it('renders', () => {
    const wrapper = renderTray()
    expect(wrapper).toMatchSnapshot()
  })

  it('labels page content with LTI title', () => {
    const {getByLabelText} = renderTray()
    expect(getByLabelText(pageContentTitle)).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const {getByText} = renderTray()
    fireEvent.click(getByText('Close'))
    expect(onDismiss.mock.calls.length).toBe(1)
  })

  it('includes page content', () => {
    const {getByText} = renderTray()
    expect(getByText('page-content-text')).toBeInTheDocument()
  })

  describe('when a tool icon is provided', () => {
    let icon_url

    beforeAll(() => {
      icon_url = 'https://lti1.example.com/icon.png'
      tool.icon_url = icon_url
    })

    afterAll(() => {
      delete tool.icon_url
    })

    it('renders an icon', () => {
      const {getByAltText} = renderTray()
      expect(getByAltText('First LTI Icon')).toHaveAttribute('src', icon_url)
    })
  })

  describe('external content message handling', () => {
    const origEnv = {...window.ENV}
    const origin = 'http://example.com'
    beforeAll(() => (window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin))
    afterAll(() => (window.ENV = origEnv))
    const sendPostMessage = data => fireEvent(window, new MessageEvent('message', {data, origin}))

    it('calls onExternalContentReady when it receives an externalContentReady postMessage', () => {
      renderTray()
      sendPostMessage({subject: 'externalContentReady'})
      expect(onExternalContentReady).toHaveBeenCalledTimes(1)
    })
  })

  it('constructs iframe src url', () => {
    expect(tool.base_url).not.toContain('?')
    const {getByTestId} = renderTray()
    const src = getByTestId('ltiIframe').src
    expect(src).toContain(`${tool.base_url}?`)
    expect(getByTestId('ltiIframe')).toBeInTheDocument()
  })

  it('does not render ToolLaunchIframe when there is no tool', () => {
    const {queryByTestId} = render(
      <ContentTypeExternalToolDrawer
        tool={null}
        pageContent={pageContent}
        pageContentTitle={pageContentTitle}
        pageContentMinWidth="40rem"
        trayPlacement="end"
        onDismiss={onDismiss}
        onExternalContentReady={onExternalContentReady}
        open={true}
      />
    )
    expect(queryByTestId('ltiIframe')).toBeNull()
  })

  describe('when ENV.INIT_DRAWER_LAYOUT_MUTEX is set', () => {
    const origEnv = {...window.ENV}
    const mutex = 'init-drawer-layout'

    beforeAll(() => {
      window.ENV.INIT_DRAWER_LAYOUT_MUTEX = mutex
      MutexManager.createMutex(mutex)
    })

    afterAll(() => (window.ENV = origEnv))

    it('releases the mutex after reparenting content', () => {
      expect(MutexManager.mutexes[mutex]).toBeDefined()

      renderTray()

      expect(MutexManager.mutexes[mutex]).toBeUndefined()
    })
  })
})
