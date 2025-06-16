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

import {IssueCell} from '../IssueCell'
import {ContentItem} from '../../../types'

describe('IssueCell', () => {
  describe('renders pill', () => {
    it('with correct number', () => {
      render(<IssueCell item={{count: 5} as ContentItem} />)
      expect(screen.getByTestId('issue-count-tag')).toHaveTextContent('5')
    })

    it('with correct number if exceeds limit', () => {
      render(<IssueCell item={{count: 2000} as ContentItem} />)
      expect(screen.getByTestId('issue-count-tag')).toHaveTextContent('999+')
    })

    describe('and button', () => {
      it('renders', () => {
        const handleClick = jest.fn()
        render(<IssueCell item={{count: 5} as ContentItem} onClick={handleClick} />)
        expect(screen.getByTestId('issue-remediation-button')).toBeInTheDocument()
      })

      it('does not render', () => {
        render(<IssueCell item={{count: 5} as ContentItem} />)
        expect(screen.queryByTestId('issue-remediation-button')).not.toBeInTheDocument()
      })

      it('calls onClick', () => {
        const handleClick = jest.fn()
        const item = {count: 5} as ContentItem
        render(<IssueCell item={item} onClick={handleClick} />)
        screen.getByTestId('issue-remediation-button').click()
        expect(handleClick).toHaveBeenCalledWith(expect.objectContaining(item))
      })
    })
  })

  it('renders no issues text', () => {
    render(<IssueCell item={{count: 0} as ContentItem} />)
    expect(screen.getByText(/No issues/i)).toBeInTheDocument()
  })

  it('renders unknown text', () => {
    render(<IssueCell item={{count: -1, issues: undefined} as ContentItem} />)
    expect(screen.getByText(/Unknown/i)).toBeInTheDocument()
  })

  it('renders spinner and loading text', () => {
    render(<IssueCell item={{count: -1, issues: []} as any} />)
    expect(screen.getByText(/Checking/i)).toBeInTheDocument()
  })
})
