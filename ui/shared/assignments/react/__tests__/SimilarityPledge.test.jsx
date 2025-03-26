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

import {act, fireEvent, render} from '@testing-library/react'
import React from 'react'
import SimilarityPledge from '../SimilarityPledge'

describe('SimilarityPledge', () => {
  const setup = (overrides = {}) => {
    const props = {
      eulaUrl: '',
      checked: true,
      comments: '',
      onChange: jest.fn(),
      pledgeText: 'a grave and solemn pledge',
      shouldShowPledgeError: false,
      getShouldShowPledgeError: jest.fn(),
      setShouldShowPledgeError: jest.fn(),
      checkboxRef: null,
      ...overrides
    }
    return render(<SimilarityPledge {...props} />)
  }

  it('calls the onChange property when the checkbox is toggled', () => {
    const onChange = jest.fn()
    const {getByTestId} = setup({eulaUrl: 'http://some.url', onChange: onChange})
    const checkbox = getByTestId('similarity-pledge-checkbox')
    act(() => {
      fireEvent.click(checkbox)
    })
    expect(onChange).toHaveBeenCalled()
  })

  it('renders any supplied comments as HTML', () => {
    const comments = '<p>Here are some comments</p><p>And some more</p>'
    const {getByTestId} = setup({comments: comments, eulaUrl: 'http://some.url'})
    const commentsContainer = getByTestId('similarity-pledge-comments')
    expect(commentsContainer.innerHTML).toEqual(
      expect.stringMatching(/<p>Here are some comments<\/p>\s*<p>And some more<\/p>/),
    )
  })

  it('includes a link to the supplied eulaUrl when one is provided', () => {
    const {getByText} = setup({eulaUrl: 'http://some.url'})
    const eulaLink = getByText('End-User License Agreement').closest('a')
    expect(eulaLink).not.toBeNull()
    expect(eulaLink?.href).toBe('http://some.url/')
  })

  it('renders the value of pledgeText as the checkbox label when no eulaUrl is given', () => {
    const {getByLabelText} = setup({})
    const checkbox = getByLabelText('a grave and solemn pledge *')
    expect(checkbox).toBeInTheDocument()
  })

  it('renders the eulaUrl when both eulaUrl and pledgeText are provided', () => {
    const {getByLabelText} = setup({eulaUrl: 'http://some.url'})
    expect(getByLabelText(/I agree to the tool's End-User License Agreement/)).toBeInTheDocument()
  })

  it('renders the pledgeText when both eulaUrl and pledgeText are provided', () => {
    const {getByLabelText} = setup({eulaUrl: 'http://some.url'})
    expect(getByLabelText(/a grave and solemn pledge */)).toBeInTheDocument()
  })

  it('checks the checkbox if "checked" is true', () => {
    const {getByLabelText} = setup({})
    const checkbox = getByLabelText('a grave and solemn pledge *')
    expect(checkbox).toBeChecked()
  })

  it('does not check the checkbox if "checked" is false', () => {
    const {getByLabelText} = setup({checked: false})
    const checkbox = getByLabelText('a grave and solemn pledge *')
    expect(checkbox).not.toBeChecked()
  })

  describe('validation', () => {
    it('displays an error message when shouldShowPledgeError is true', () => {
      const {getByText} = setup({checked: false, shouldShowPledgeError: true})
      expect(getByText('You must agree to the submission pledge before you can submit the assignment')).toBeInTheDocument()
    })

    it('removes the error message when the checkbox is checked', () => {
      const mockSetShouldShowPledgeError = jest.fn()
      const {getByTestId, queryByText} = setup({checked: false, setShouldShowPledgeError: mockSetShouldShowPledgeError, shouldShowPledgeError: true})

      const checkbox = getByTestId('similarity-pledge-checkbox')
      fireEvent.click(checkbox)

      expect(mockSetShouldShowPledgeError).toHaveBeenCalledWith(false, '')
      expect(queryByText('You must agree to the submission pledge before you can submit the assignment')).not.toBeInTheDocument()
    })
  })
})
