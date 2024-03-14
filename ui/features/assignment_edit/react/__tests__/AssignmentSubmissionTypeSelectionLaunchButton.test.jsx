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
import {mount} from 'enzyme'
import AssignmentSubmissionTypeSelectionLaunchButton from '../AssignmentSubmissionTypeSelectionLaunchButton'

const tool = {
  title: 'Tool Title',
  description: 'The tool description.',
  icon_url: 'https://www.example.com/icon.png'
}

describe('AssignmentSubmissionTypeSelectionLaunchButton', () => {
  let wrapper = 'empty wrapper'

  beforeEach(() => {
    window.ENV = {
      UPDATE_ASSIGNMENT_SUBMISSION_TYPE_LAUNCH_BUTTON_ENABLED: true
    }
  });

  afterEach(() => {
    wrapper.unmount()
  })

  it('renders a button to launch the tool', () => {
    wrapper = mount(<AssignmentSubmissionTypeSelectionLaunchButton tool={tool} />)
    expect(wrapper.find('#assignment_submission_type_selection_launch_button')).toBeTruthy()
  })

  it('renders an icon, a title, description', () => {
    wrapper = mount(<AssignmentSubmissionTypeSelectionLaunchButton tool={tool} />)
    expect(wrapper.find('img').prop('src')).toBe(tool.icon_url)
    expect(wrapper.find('#title_text')).toBeTruthy()
    expect(wrapper.find('#desc_text')).toBeTruthy()
  })
})
