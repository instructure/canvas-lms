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
import {fireEvent, render} from '@testing-library/react'
import {ImageSection} from '../ImageSection'

jest.mock('../../../../../shared/StoreContext', () => {
  return {
    useStoreProps: () => ({
      images: {
        Course: {
          files: [],
          bookmark: 'bookmark',
          isLoading: false,
          hasMore: false
        }
      },
      contextType: 'Course',
      fetchInitialImages: jest.fn(),
      fetchNextImages: jest.fn()
    })
  }
})

describe('ImageSection', () => {
  const defaultProps = {editor: {}}
  const subject = overrides => render(<ImageSection {...{...defaultProps, ...overrides}} />)

  it.todo('renders an image preview')

  it('renders the image mode selector', () => {
    const {getByText} = subject()
    expect(getByText('Add Image')).toBeInTheDocument()
  })

  it('renders the image preview', () => {
    const {getByTestId} = subject()
    expect(getByTestId('selected-image-preview')).toBeInTheDocument()
  })

  describe('when no image is selected', () => {
    it('renders a "None Selected" message', () => {
      const {getByText} = subject()
      expect(getByText('None Selected')).toBeInTheDocument()
    })
  })

  describe('when the "course images" mode is selected', () => {
    let getByTestId, getByText

    beforeEach(() => {
      const rendered = subject()
      getByTestId = rendered.getByTestId
      getByText = rendered.getByText

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Course Images'))
    })

    it('renders the course images component', () => {
      expect(getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
    })
  })
})
