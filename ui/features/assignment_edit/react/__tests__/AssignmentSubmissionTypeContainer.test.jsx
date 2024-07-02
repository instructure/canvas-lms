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
import {AssignmentSubmissionTypeContainer} from '../AssignmentSubmissionTypeContainer'

const onLaunchButtonFn = jest.fn()
const onRemoveResourceFn = jest.fn()
const tool = {
  id: '1',
  title: 'Tool Title',
  description: 'The tool description.',
  icon_url: 'https://www.example.com/icon.png',
}

const renderComponent = resource => {
  return render(
    <AssignmentSubmissionTypeContainer
      tool={tool}
      resource={resource}
      onLaunchButtonClick={onLaunchButtonFn}
      onRemoveResource={onRemoveResourceFn}
    />
  )
}

describe('AssignmentSubmissionTypeContainer', () => {
  beforeEach(() => {
    window.ENV = {
      ASSIGNMENT_SUBMISSION_TYPE_CARD_ENABLED: true,
      UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED: true,
    }
  })

  it('renders the launch button when there is no resource available', () => {
    renderComponent(undefined)
    expect(screen.getByTestId('assignment_submission_type_selection_launch_button')).toBeTruthy()
    expect(
      screen.queryByTestId('assignment-submission-type-selection-resource-link-card')
    ).toBeFalsy()
  })

  it('renders the resource link card when a resource is available and the user has not clicked the resource close button', () => {
    const resource = {title: 'Resource Title'}
    renderComponent(resource)
    const el = screen.getByTestId('assignment-submission-type-selection-resource-link-card')
    expect(el).toBeTruthy()
    // check text:
    expect(el).toHaveTextContent('Resource Title')
    expect(screen.queryByTestId('assignment_submission_type_selection_launch_button')).toBeFalsy()
  })

  it('renders the resource link card with "Unnamed Document" when a resource is available but it has no title', () => {
    const resource = {}
    renderComponent(resource)
    const el = screen.getByTestId('assignment-submission-type-selection-resource-link-card')
    expect(el).toBeTruthy()
    expect(el).toHaveTextContent('Unnamed Document')
    expect(screen.queryByTestId('assignment_submission_type_selection_launch_button')).toBeFalsy()
  })

  it('calls onRemoveResource when the user clicks the resource close button', () => {
    const resource = {title: 'Resource Title'}
    renderComponent(resource)
    expect(
      screen.getByTestId('assignment-submission-type-selection-resource-link-card')
    ).toBeTruthy()
    expect(screen.queryByTestId('assignment_submission_type_selection_launch_button')).toBeFalsy()

    fireEvent.click(screen.getByRole('button'))

    expect(onRemoveResourceFn).toHaveBeenCalled()
  })
})
