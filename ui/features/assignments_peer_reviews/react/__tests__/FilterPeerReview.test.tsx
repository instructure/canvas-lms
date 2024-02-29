/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import FilterPeerReview from '../FilterPeerReview'
import userEvent from '@testing-library/user-event'

describe('Filter Peer Review Tests', () => {
  beforeEach(() => {
    // @ts-expect-error
    delete window.location
    // @ts-expect-error
    window.location = {
      search: '',
    }
  })
  describe('peer review search bar', () => {
    it('search bar contains the name of user in the search term parameter', () => {
      window.location.search = '?selected_option=all&search_term=bob'
      const {getByTestId} = render(<FilterPeerReview />)
      const searchBar = getByTestId('peer-review-search') as HTMLInputElement
      expect(searchBar.value).toBe('bob')
    })
    it('search bar does not have any text if search_term parameter does not exist', () => {
      window.location.search = '?selected_option=all'
      const {getByTestId} = render(<FilterPeerReview />)
      const searchBar = getByTestId('peer-review-search') as HTMLInputElement
      expect(searchBar.value).toBe('')
    })
  })
  describe('peer review selected options', () => {
    it('selected option dropdown displays All if the selected_option parameter contains all', () => {
      window.location.search = '?selected_option=all&search_term=bob'
      const {getByTestId} = render(<FilterPeerReview />)
      const selectOption = getByTestId('peer-review-select') as HTMLInputElement
      expect(selectOption.value).toBe('All')
    })
    it('selected option dropdown displays Search by Reviewer if the selected_option parameter contains reviewer', () => {
      window.location.search = '?selected_option=reviewer&search_term=bob'
      const {getByTestId} = render(<FilterPeerReview />)
      const selectOption = getByTestId('peer-review-select') as HTMLInputElement
      expect(selectOption.value).toBe('Search by Reviewer')
    })
    it('selected option dropdown displays Search by Peer Review if the selected_option parameter contains student', () => {
      window.location.search = '?selected_option=student&search_term=bob'
      const {getByTestId} = render(<FilterPeerReview />)
      const selectOption = getByTestId('peer-review-select') as HTMLInputElement
      expect(selectOption.value).toBe('Search by Peer Review')
    })
    it('selected option dropdown defaults to All if no search term is present', () => {
      window.location.search = '?selected_option=student'
      const {getByTestId} = render(<FilterPeerReview />)
      const selectOption = getByTestId('peer-review-select') as HTMLInputElement
      expect(selectOption.value).toBe('All')
    })
  })
  describe('peer review submit button', () => {
    it('reloads the page that contains a url with the search term and the selected option as the parameters', async () => {
      ENV.ASSIGNMENT_ID = 1
      ENV.COURSE_ID = '1'
      // @ts-expect-error
      window.location = {origin: 'http://localhost'}
      const {getByTestId} = render(<FilterPeerReview />)
      const searchBar = getByTestId('peer-review-search') as HTMLInputElement
      const submitButton = getByTestId('peer-review-submit') as HTMLInputElement
      await userEvent.type(searchBar, 'Jonathan')
      await userEvent.click(submitButton)
      expect(window.location.href).toBe(
        'http://localhost/courses/1/assignments/1/peer_reviews?selected_option=all&search_term=Jonathan'
      )
    })
  })
})
