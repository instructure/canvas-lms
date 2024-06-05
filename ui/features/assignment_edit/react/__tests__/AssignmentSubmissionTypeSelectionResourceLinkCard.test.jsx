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
import {render, screen, fireEvent} from '@testing-library/react'
import {AssignmentSubmissionTypeSelectionResourceLinkCard} from '../AssignmentSubmissionTypeSelectionResourceLinkCard'

const onCloseFn = jest.fn()
const tool = {
  id: '1',
  title: 'Tool Title',
  description: 'The tool description.',
  icon_url: 'https://www.example.com/icon.png',
}
const resource = {
  title: 'Resource Title',
}

const renderComponent = () => {
  return render(
    <AssignmentSubmissionTypeSelectionResourceLinkCard
      tool={tool}
      resourceTitle={resource.title}
      onCloseButton={onCloseFn}
    />
  )
}

describe('AssignmentSubmissionTypeSelectionResourceLinkCard', () => {
  it('renders a card with a icon, tool title, and resource title, and a reset button', () => {
    renderComponent()
    expect(screen.getByTestId('lti-tool-icon')).toBeTruthy()
    expect(screen.getByText(tool.title)).toBeTruthy()
    expect(screen.getByText(resource.title)).toBeTruthy()
    expect(screen.getByTestId('close-button')).toBeTruthy()
  })

  it('calls the onClose action when clicked', () => {
    renderComponent()
    fireEvent.click(screen.getByRole('button'))
    expect(onCloseFn).toHaveBeenCalled()
  })
})
