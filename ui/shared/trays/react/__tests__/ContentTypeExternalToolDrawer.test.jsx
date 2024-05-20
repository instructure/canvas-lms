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
import { render, fireEvent } from '@testing-library/react'
import ContentTypeExternalToolDrawer from '../ContentTypeExternalToolDrawer'

describe('ContentTypeExternalToolDrawer', () => {
  const tool = { id: '1', base_url: 'https://one.lti.com/', title: 'First LTI' }
  const onDismiss = jest.fn()
  const onExternalContentReady = jest.fn()
  const extraQueryParams = { key1: 'value1', key2: 'value2' }
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
        pageContentMinWidth=''
        trayPlacement='end'
        acceptedResourceTypes={['page', 'module']}
        targetResourceType='page'
        allowItemSelection={true}
        selectableItems={[{ id: '1', name: 'module 1' }]}
        onDismiss={onDismiss}
        onExternalContentReady={onExternalContentReady}
        open={true}
        placement='wiki_index_menu'
        extraQueryParams={extraQueryParams}
        {...props}
      />
    )
  }

  it('labels page content with LTI title', () => {
    const { getByLabelText } = renderTray()
    expect(getByLabelText(pageContentTitle)).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const { getByText } = renderTray()
    fireEvent.click(getByText('Close'))
    expect(onDismiss.mock.calls.length).toBe(1)
  })

  it('includes page content', () => {
    const { getByText } = renderTray()
    expect(getByText('page-content-text')).toBeInTheDocument()
  })

  describe('when a tool icon is provided', () => {
    let icon_url

    beforeAll(() => {
      icon_url = 'https://one.lti.com/icon.png'
      tool.icon_url = icon_url
    })

    afterAll(() => {
      delete tool.icon_url
    })

    it('renders an icon', () => {
      const { getByAltText } = renderTray()
      expect(getByAltText('First LTI icon')).toHaveAttribute('src', icon_url)
    })

  })

  describe('external content message handling', () => {
    const origEnv = { ...window.ENV }
    const origin = 'http://example.com'
    beforeAll(() => window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin)
    afterAll(() => window.ENV = origEnv)
    const sendPostMessage = (data) =>
      fireEvent(window, new MessageEvent('message', { data, origin }))

    it('calls onExternalContentReady when it receives an externalContentReady postMessage', () => {
      renderTray()
      sendPostMessage({ subject: 'externalContentReady' })
      expect(onExternalContentReady).toHaveBeenCalledTimes(1)
    })
  })

  describe('constructs iframe src url', () => {
    it('adds ? before parameters if none are already present', () => {
      expect(tool.base_url).not.toContain('?')
      const { getByTestId } = renderTray()
      const src = getByTestId('ltiIframe').src
      expect(src).toContain(`${tool.base_url}?`)
    })

    it('appends parameters if some exist already', () => {
      tool.base_url = 'https://one.lti.com/?launch_type=wiki_index_menu'
      const { getByTestId } = renderTray()
      const src = getByTestId('ltiIframe').src
      expect(src).toContain(`${tool.base_url}&`)
    })

    it('includes expected parameters', () => {
      const { getByTestId } = renderTray()
      const src = getByTestId('ltiIframe').src
      expect(src).toContain('com_instructure_course_accept_canvas_resource_types')
      expect(src).toContain('com_instructure_course_canvas_resource_type')
      expect(src).toContain('com_instructure_course_allow_canvas_resource_selection')
      expect(src).toContain('com_instructure_course_available_canvas_resources')
      expect(src).toContain('display')
      expect(src).toContain('placement')
      // from extraQueryParams
      expect(src).toContain('key1=value1')
      expect(src).toContain('key2=value2')
    })
  })
})
