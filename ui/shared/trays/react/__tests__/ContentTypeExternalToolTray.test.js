/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ContentTypeExternalToolTray from '../ContentTypeExternalToolTray'

describe('ContentTypeExternalToolTray', () => {
  const tool = {id: 1, base_url: 'https://one.lti.com/', title: 'First LTI'}
  const onDismiss = jest.fn()

  function renderTray(props) {
    return render(
      <ContentTypeExternalToolTray
        tool={tool}
        placement="wiki_index_menu"
        onDismiss={onDismiss}
        acceptedResourceTypes={['page', 'module']}
        targetResourceType="page"
        allowItemSelection
        selectableItems={[{id: '1', name: 'module 1'}]}
        open
        {...props}
      />
    )
  }

  it('shows LTI title', () => {
    const {getByText} = renderTray()
    expect(getByText(/first lti/i)).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const {getByText} = renderTray()
    fireEvent.click(getByText('Close'))
    expect(onDismiss.mock.calls.length).toBe(1)
  })

  describe('constructs iframe src url', () => {
    it('adds ? before parameters if none are already present', () => {
      expect(tool.base_url).not.toContain('?')
      const {getByTestId} = renderTray()
      const src = getByTestId('ltiIframe').src
      expect(src).toContain(`${tool.base_url}?`)
    })

    it('appends parameters if some exist already', () => {
      tool.base_url = 'https://one.lti.com/?launch_type=wiki_index_menu'
      const {getByTestId} = renderTray()
      const src = getByTestId('ltiIframe').src
      expect(src).toContain(`${tool.base_url}&`)
    })

    it('includes expected parameters', () => {
      const {getByTestId} = renderTray()
      const src = getByTestId('ltiIframe').src
      expect(src).toContain('com_instructure_course_accept_canvas_resource_types')
      expect(src).toContain('com_instructure_course_canvas_resource_type')
      expect(src).toContain('com_instructure_course_allow_canvas_resource_selection')
      expect(src).toContain('com_instructure_course_available_canvas_resources')
      expect(src).toContain('display')
      expect(src).toContain('placement')
    })
  })
})
