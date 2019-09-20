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

import {LtiToolsModal} from '../index'

describe('RCE Plugins > LtiToolModal', () => {

  function getProps(override={}) {
    const props = {
      onDismiss: () => {},
      ltiButtons: [
        {
            title: "Tool 1",
            id: 1,
            description: "This is tool 1.",
            image: "tool1/icon.png",
            onAction: () => {}
        },
        {
            title: "Tool 2",
            id: 2,
            description: "This is tool 2",
            image: "/tool2/image.png",
            onAction: () => {}
        },
        {
            title: "Tool 3",
            id: 3,
            image: "https://www.edu-apps.org/assets/lti_public_resources/tool3.png",
            onAction: () => {}
        },
        {
            title: "Diffrient Tool",
            id: 4,
            image: "https://www.edu-apps.org/assets/lti_public_resources/tool3.png",
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

  it('is labeled "Select App"', () => {
    const {getByLabelText} = renderComponent()
    expect(getByLabelText("LTI Tools")).toBeInTheDocument()
  })

  it('has heading "Select App"', () => {
    const {getByText} = renderComponent()
    expect(getByText("Select App")).toBeInTheDocument()
  })

  it('shows the 3 tools', () => {
    const {baseElement, getByText} = renderComponent()
    expect(getByText('Tool 1')).toBeInTheDocument()
    expect(getByText('This is tool 1.')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="tool1/icon.png"]')).toBeInTheDocument()
    expect(getByText('Tool 2')).toBeInTheDocument()
    expect(getByText('This is tool 2')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="/tool2/image.png"]')).toBeInTheDocument()
    expect(getByText('Tool 3')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="https://www.edu-apps.org/assets/lti_public_resources/tool3.png"]')).toBeInTheDocument()
  })

  it('calls onDismiss when clicking Cancel', () => {
    const handleDismiss = jest.fn()
    const {getByText} = renderComponent({onDismiss: handleDismiss})
    const cancelButton = getByText('Cancel')
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
          title: "Tool 1",
          id: 1,
          description: "This is tool 1.",
          image: "tool1/icon.png",
          onAction: doAction
      }
    ]})
    const tool1 = getByText('Tool 1')
    tool1.click()
    expect(doAction).toHaveBeenCalled()
    expect(onDismiss).toHaveBeenCalled()
  })

  describe('filtering', () => {
    it('shows only results that match the filter value', () => {
      const {getByText, queryByText, getByLabelText} = renderComponent()
      const searchBox = getByLabelText('Search')
      fireEvent.change(searchBox, { target: { value: 'diff' } })
      expect(queryByText('Tool 1')).not.toBeInTheDocument()
      expect(getByText('Diffrient Tool')).toBeInTheDocument()
    })

    it('shows a no results alert when there are no results', () => {
      const {getByText, getByLabelText} = renderComponent()
      const searchBox = getByLabelText('Search')
      fireEvent.change(searchBox, { target: { value: 'instructure' } })
      expect(getByText('No results found for instructure')).toBeInTheDocument()
    })
  })
})
