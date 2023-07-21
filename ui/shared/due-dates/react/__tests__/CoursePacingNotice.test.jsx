/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, getByRole, getByText} from '@testing-library/react'
import CoursePacingNotice, {renderCoursePacingNotice} from '../CoursePacingNotice'

describe('CoursePacingNotice', () => {
  it('renders', () => {
    // eslint-disable-next-line @typescript-eslint/no-shadow
    const {getByRole, getByText} = render(<CoursePacingNotice courseId="17" />)
    expect(
      getByText('This course is using Course Pacing. Go to Course Pacing to manage due dates.')
    ).toBeInTheDocument()
    const link = getByRole('link', {name: 'Course Pacing'})
    expect(link).toBeInTheDocument()
    expect(link.getAttribute('href')).toEqual('/courses/17/course_pacing')
  })

  describe('renderCoursePacingNoticee', () => {
    it('renders', () => {
      const div = document.createElement('div')
      renderCoursePacingNotice(div, '17')
      expect(
        getByText(
          div,
          'This course is using Course Pacing. Go to Course Pacing to manage due dates.'
        )
      ).toBeDefined()
      const link = getByRole(div, 'link', {name: 'Course Pacing'})
      expect(link).toBeDefined()
      expect(link.getAttribute('href')).toEqual('/courses/17/course_pacing')
    })
  })
})
