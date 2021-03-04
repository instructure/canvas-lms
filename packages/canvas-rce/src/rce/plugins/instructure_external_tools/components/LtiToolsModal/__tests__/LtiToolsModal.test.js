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
import {within, render, fireEvent} from '@testing-library/react'

import {LtiToolsModal} from '../index'

describe('RCE Plugins > LtiToolModal', () => {
  function getProps(override = {}) {
    const props = {
      onDismiss: () => {},
      ltiButtons: [
        {
          title: 'Tool 1',
          id: 1,
          description: 'This is tool 1.',
          image: 'tool1/icon.png',
          onAction: () => {}
        },
        {
          title: 'Tool 2',
          id: 2,
          description: 'This is tool 2',
          image: '/tool2/image.png',
          onAction: () => {}
        },
        {
          title: 'Tool 3',
          id: 3,
          image: 'https://www.edu-apps.org/assets/lti_public_resources/tool3.png',
          onAction: () => {}
        },
        {
          title: 'Diffrient Tool',
          id: 4,
          image: 'https://www.edu-apps.org/assets/lti_public_resources/tool3.png',
          onAction: () => {}
        }
      ],
      ...override
    }
    return props
  }

  function renderComponent(modalprops) {
    return render(<LtiToolsModal {...getProps(modalprops)} />)
  }

  it('is labeled "All Apps"', () => {
    const {getByLabelText} = renderComponent()
    expect(getByLabelText('Apps')).toBeInTheDocument()
  })

  it('has heading "All Apps"', () => {
    const {getByText} = renderComponent()
    expect(getByText('All Apps')).toBeInTheDocument()
  })

  it('shows the 3 tools', () => {
    const {baseElement, getByText} = renderComponent()
    const tool1 = getByText('Tool 1')
    const tool1Row = within(tool1.closest('div'))
    const tool2 = getByText('Tool 2')
    const tool2Row = within(tool2.closest('div'))
    const tool3 = getByText('Tool 3')
    const tool3Row = within(tool3.closest('div'))

    expect(tool1).toBeInTheDocument()
    expect(tool1Row.getByText('View description')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="tool1/icon.png"]')).toBeInTheDocument()
    expect(tool2).toBeInTheDocument()
    expect(tool2Row.getByText('View description')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="/tool2/image.png"]')).toBeInTheDocument()
    expect(tool3).toBeInTheDocument()
    expect(tool3Row.queryByText('View description')).toBeNull()
    expect(
      baseElement.querySelector(
        'img[src="https://www.edu-apps.org/assets/lti_public_resources/tool3.png"]'
      )
    ).toBeInTheDocument()
  })

  it('calls onDismiss when clicking Done', () => {
    const handleDismiss = jest.fn()
    const {getByText} = renderComponent({onDismiss: handleDismiss})
    const cancelButton = getByText('Done')
    cancelButton.click()
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('calls onDismiss when clicking the close button', () => {
    const handleDismiss = jest.fn()
    const {getByText} = renderComponent({onDismiss: handleDismiss})
    const closeButton = getByText('Close')
    closeButton.click()
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('calls onAction when clicking a tool', () => {
    const doAction = jest.fn()
    const onDismiss = jest.fn()
    const {getByText} = renderComponent({
      onDismiss,
      ltiButtons: [
        {
          title: 'Tool 1',
          id: 1,
          description: 'This is tool 1.',
          image: 'tool1/icon.png',
          onAction: doAction
        }
      ]
    })
    const tool1 = getByText('Tool 1')
    tool1.click()
    expect(doAction).toHaveBeenCalled()
    expect(onDismiss).toHaveBeenCalled()
  })

  describe('filtering', () => {
    it('shows only results that match the filter value', () => {
      const {getByText, queryByText, getByPlaceholderText} = renderComponent()
      const searchBox = getByPlaceholderText('Search')
      fireEvent.change(searchBox, {target: {value: 'diff'}})
      expect(queryByText('Tool 1')).not.toBeInTheDocument()
      expect(getByText('Diffrient Tool')).toBeInTheDocument()
    })

    it('shows a no results alert when there are no results', () => {
      const {getByText, getByPlaceholderText} = renderComponent()
      const searchBox = getByPlaceholderText('Search')
      fireEvent.change(searchBox, {target: {value: 'instructure'}})
      expect(getByText('No results found for instructure')).toBeInTheDocument()
    })
  })
})
