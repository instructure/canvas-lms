/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {render, within} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'
import VisibilityHelpIcon from '../VisibilityHelpIcon'

const renderWithSelect = () => {
  return render(
    <>
      <select id="course_course_visibility">
        <option value="public">Public</option>
        <option value="institution">Institution</option>
        <option value="course">Course</option>
        <option value="cursed">Cursed</option>
      </select>
      <VisibilityHelpIcon />
    </>,
  )
}

describe('VisibilityHelpIcon', () => {
  beforeEach(() => {
    fakeENV.setup({
      COURSE_VISIBILITY_OPTION_DESCRIPTIONS: {
        public: 'Anyone with the URL',
        institution: 'All users associated with this institution',
        course: 'All users associated with this course',
        cursed: 'Anyone, but at what cost?',
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('opens the modal and displays information from ENV and the form select options', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderWithSelect()
    await user.click(getByTestId('visibility_help_link'))

    const modalBody = getByTestId('course_visibility_descriptions')

    const dtElements = modalBody.querySelectorAll('dt')
    expect(Array.from(dtElements).map(dt => dt.textContent)).toEqual([
      'Public',
      'Institution',
      'Course',
      'Cursed',
    ])

    const ddElements = modalBody.querySelectorAll('dd')
    expect(Array.from(ddElements).map(dd => dd.textContent)).toEqual([
      'Anyone with the URL',
      'All users associated with this institution',
      'All users associated with this course',
      'Anyone, but at what cost?',
    ])
  })
})
