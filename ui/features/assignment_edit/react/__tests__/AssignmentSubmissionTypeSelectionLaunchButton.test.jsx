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
import {AssignmentSubmissionTypeSelectionLaunchButton} from '../AssignmentSubmissionTypeSelectionLaunchButton'

const onClickFn = jest.fn()
const tool = {
  id: '1',
  title: 'Tool Title',
  description: 'The tool description.',
  icon_url: 'https://www.example.com/icon.png',
}

const renderComponent = () => {
  return render(<AssignmentSubmissionTypeSelectionLaunchButton tool={tool} onClick={onClickFn} />)
}

describe('AssignmentSubmissionTypeSelectionLaunchButton', () => {
  it('renders a button to launch the tool', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('assignment_submission_type_selection_launch_button')).toBeTruthy()
  })

  it('renders an icon, a title, description', () => {
    const {container} = renderComponent()
    expect(container.querySelector('img').src).toBe(tool.icon_url)
    expect(container.querySelector('#title_text')).toBeTruthy()
    expect(container.querySelector('#desc_text')).toBeTruthy()
  })

  it('calls the onClick function when the button is clicked', () => {
    renderComponent()
    fireEvent.click(screen.getByTestId('assignment_submission_type_selection_launch_button'))
    expect(onClickFn).toHaveBeenCalledTimes(1)
  })
})
