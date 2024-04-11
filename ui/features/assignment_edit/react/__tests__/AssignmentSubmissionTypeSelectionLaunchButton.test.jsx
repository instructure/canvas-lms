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
import {render} from '@testing-library/react'
import AssignmentSubmissionTypeSelectionLaunchButton from '../AssignmentSubmissionTypeSelectionLaunchButton'

const tool = {
  title: 'Tool Title',
  description: 'The tool description.',
  icon_url: 'https://www.example.com/icon.png'
}

describe('AssignmentSubmissionTypeSelectionLaunchButton', () => {
  beforeEach(() => {
    window.ENV = {
      UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED: true
    }
  });

  it('renders a button to launch the tool', () => {
    const wrapper = render(<AssignmentSubmissionTypeSelectionLaunchButton tool={tool} />)
    expect(wrapper.getByRole('button', { name: `${tool.title} ${tool.description}` })).toBeTruthy()
  })

  it('renders an icon, a title, description', () => {
    const wrapper = render(<AssignmentSubmissionTypeSelectionLaunchButton tool={tool} />)
    expect(wrapper.getByRole('img')).toHaveAttribute('src', tool.icon_url)
    expect(wrapper.getByText(tool.title)).toBeInTheDocument()
    expect(wrapper.getByText(tool.description)).toBeInTheDocument()
  })
})
