/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {renderConnected} from '../../../__tests__/utils'
import {Header} from '../header'

const defaultProps = {
  context_type: 'Course',
  context_id: '17',
  newPace: false
}

beforeAll(() => {
  window.ENV.FEATURES ||= {}
  window.ENV.FEATURES.course_paces_for_sections = true
})

describe('Course paces header', () => {
  it('renders', () => {
    const {getByRole, getByText} = renderConnected(<Header {...defaultProps} />)
    expect(getByRole('button', {name: 'Course Pacing'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Modify Settings'})).toBeInTheDocument()
    expect(getByText('All changes published')).toBeInTheDocument()
  })

  describe('new paces alert', () => {
    it('renders an alert for new course paces', () => {
      const {getByText} = renderConnected(<Header {...defaultProps} newPace />)
      expect(
        getByText(
          'This is a new course pace and all changes are unpublished. Publish to save any changes and create the pace.'
        )
      ).toBeInTheDocument()
    })

    it('renders an alert for new section paces', () => {
      const {getByText} = renderConnected(
        <Header {...defaultProps} context_type="Section" newPace />
      )
      expect(
        getByText(
          'This is a new section pace and all changes are unpublished. Publish to save any changes and create the pace.'
        )
      ).toBeInTheDocument()
    })

    it('renders an alert for new student paces', () => {
      const {getByText} = renderConnected(
        <Header {...defaultProps} context_type="Enrollment" newPace />
      )
      expect(
        getByText(
          'This is a new student pace and all changes are unpublished. Publish to save any changes and create the pace.'
        )
      ).toBeInTheDocument()
    })
  })

  it('renders the unpublished changes message for a new pace', () => {
    const {getByText} = renderConnected(<Header {...defaultProps} newPace />)
    expect(getByText('Pace is new and unpublished')).toBeInTheDocument()
  })
  // the other messsages are tested with UnpublishedChangesIndicator
})
