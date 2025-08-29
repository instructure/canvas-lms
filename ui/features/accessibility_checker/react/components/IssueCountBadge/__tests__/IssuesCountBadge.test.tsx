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

import {render, screen} from '@testing-library/react'

import {IssueCountBadge} from '../IssueCountBadge'

describe('IssueCountBadge', () => {
  describe(' - correct count - ', () => {
    it('renders count 1 correctly', () => {
      render(<IssueCountBadge issueCount={1} />)
      expect(screen.getByText('1 Issue')).toBeInTheDocument()
    })

    it('renders count 5 correctly', () => {
      render(<IssueCountBadge issueCount={5} />)
      expect(screen.getByText('5 Issues')).toBeInTheDocument()
    })
  })

  describe(' - handles count overflow -', () => {
    it('renders the badge with the default maximum count', () => {
      render(<IssueCountBadge issueCount={100} />)
      expect(screen.getByText('99+')).toBeInTheDocument()
    })

    it('renders the badge with a custom maximum count', () => {
      render(<IssueCountBadge issueCount={1000} maxCount={1000} />)
      expect(screen.getByText('999+')).toBeInTheDocument()
    })
  })
})
