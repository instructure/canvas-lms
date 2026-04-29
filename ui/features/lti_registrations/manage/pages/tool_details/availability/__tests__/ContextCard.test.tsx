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
import {render, screen} from '@testing-library/react'
import {ContextCard} from '../ContextCard'
import {ZAccountId} from '../../../../model/AccountId'
import {ZCourseId} from '../../../../model/CourseId'

describe('ContextCard', () => {
  describe('context name linking', () => {
    it('creates a link to the account when account_id is provided', () => {
      const accountId = ZAccountId.parse('123')

      render(
        <ContextCard context_name="Test Account" account_id={accountId} inherit_note={false} />,
      )

      const link = screen.getByText('Test Account')
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/accounts/123')
    })

    it('creates a link to the course when course_id is provided', () => {
      const courseId = ZCourseId.parse('456')

      render(<ContextCard context_name="Test Course" course_id={courseId} inherit_note={false} />)

      const link = screen.getByText('Test Course')
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/courses/456')
    })
  })
})
