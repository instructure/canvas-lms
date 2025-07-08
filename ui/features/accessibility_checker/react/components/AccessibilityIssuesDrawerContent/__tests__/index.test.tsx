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

import {render, screen, fireEvent, waitFor} from '@testing-library/react'

import AccessibilityIssuesDrawerContent from '..'
import {ContentItem, ContentItemType, FormType} from '../../../types'

const mockClose = jest.fn()

const baseItem: ContentItem = {
  id: 1,
  title: 'Sample Page',
  type: ContentItemType.WikiPage,
  url: 'http://test.com/page',
  editUrl: 'http://test.com/page/edit',
  published: true,
  updatedAt: '2024-07-01T00:00:00Z',
  count: 2,
  issues: [
    {
      id: 'issue-1',
      path: '/html/body/div[1]',
      ruleId: 'adjacent-links',
      message: 'This is a test issue',
      form: {type: FormType.Checkbox, label: 'checkbox A'},
      why: '',
      element: '',
    },
    {
      id: 'issue-2',
      path: '/html/body/div[2]',
      ruleId: 'headings-sequence',
      message: 'Second issue',
      form: {
        type: FormType.RadioInputGroup,
        label: 'Choose one',
        options: ['One', 'Two'],
        value: 'One',
      },
      why: '',
      element: '',
    },
  ],
}

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(({path}) => {
    if (path.includes('/preview?')) {
      return Promise.resolve({json: {content: '<div>Preview content</div>'}})
    }
    if (path.includes('/preview')) {
      return Promise.resolve({json: {content: '<div>Updated content</div>'}})
    }
    return Promise.resolve({})
  }),
}))

describe('AccessibilityIssuesDrawerContent', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the title and issue counter', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)
    expect(await screen.findByText('Sample Page')).toBeInTheDocument()
    expect(screen.getByText(/Issue 1\/2:/)).toBeInTheDocument()
  })

  it('disables "Back" on first issue and enables "Next"', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)
    const back = screen.getByTestId('back-button')
    const next = screen.getByTestId('next-button')

    expect(back).toBeDisabled()
    expect(next).toBeEnabled()
  })

  it('disables "Next" on last issue', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    const next = screen.getByTestId('next-button')
    fireEvent.click(next)

    await waitFor(() => {
      expect(screen.getByText(/Issue 2\/2:/)).toBeInTheDocument()
      expect(next).toBeDisabled()
    })
  })

  it('removes issue on save and next', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    const saveAndNext = screen.getByTestId('save-and-next-button')
    expect(saveAndNext).toBeDisabled()

    const apply = screen.getByTestId('apply-button')
    fireEvent.click(apply)

    await waitFor(() => {
      expect(saveAndNext).toBeEnabled()
      fireEvent.click(saveAndNext)
    })

    await waitFor(() => {
      expect(screen.getByText(/Issue 1\/1:/)).toBeInTheDocument()
    })
  })

  it('renders Open Page and Edit Page links', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    expect(await screen.findByText('Open Page')).toHaveAttribute('href', baseItem.url)
    expect(screen.getByText('Edit Page')).toHaveAttribute('href', baseItem.editUrl)
  })

  it('calls onClose when close button is clicked', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    const closeButton = screen
      .getByTestId('close-button')
      .querySelector('button') as HTMLButtonElement
    fireEvent.click(closeButton)

    expect(mockClose).toHaveBeenCalledTimes(1)
  })
})
