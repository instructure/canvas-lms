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

import {render} from '@testing-library/react'
import React from 'react'
import {RolePillContainer} from '../RolePillContainer'

const discussionRoles = ['Author', 'TaEnrollment', 'TeacherEnrollment']

const setup = props => {
  return render(<RolePillContainer discussionRoles={discussionRoles} {...props} />)
}

describe('RolePillContainer', () => {
  describe('Container will not render if no roles are given to be displayed', () => {
    it('Role pill Container will not render when discussionRoles is null', () => {
      const {queryByTestId} = setup({discussionRoles: null})
      expect(queryByTestId('pill-container')).toBeFalsy()
    })

    it('Role pill Container will not render when discussionRoles is empty', () => {
      const {queryByTestId} = setup({discussionRoles: []})
      expect(queryByTestId('pill-container')).toBeFalsy()
    })
  })

  describe('Only the desired Role is displayed', () => {
    it('All Roles displayed when given', () => {
      const {queryByText} = setup()
      expect(queryByText('Teacher') && queryByText('Author') && queryByText('TA')).toBeTruthy()
    })

    it('Only Author Role is Displayed', () => {
      const {queryByText} = setup({discussionRoles: ['Author']})
      expect(queryByText('Author')).toBeTruthy()
      expect(queryByText('Teacher')).toBeFalsy()
      expect(queryByText('Ta')).toBeFalsy()
    })

    it('Only Ta Role is Displayed', () => {
      const {queryByText} = setup({discussionRoles: ['TaEnrollment']})
      expect(queryByText('TA')).toBeTruthy()
      expect(queryByText('Teacher')).toBeFalsy()
      expect(queryByText('Author')).toBeFalsy()
    })

    it('Only Teacher Role is Displayed', () => {
      const {queryByText} = setup({discussionRoles: ['TeacherEnrollment']})
      expect(queryByText('Teacher')).toBeTruthy()
      expect(queryByText('Author')).toBeFalsy()
      expect(queryByText('Ta')).toBeFalsy()
    })
  })

  describe('Will not break if given non-default values', () => {
    it('Pill will render with the text', () => {
      const {queryByText} = setup({discussionRoles: ['Custom Name']})
      expect(queryByText('Custom Name')).toBeTruthy()
    })
  })
})
