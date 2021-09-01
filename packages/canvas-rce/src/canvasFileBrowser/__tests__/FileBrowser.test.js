/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, waitFor, fireEvent} from '@testing-library/react'
import FileBrowser from '../FileBrowser'
import {apiSource} from './filesHelpers'

jest.mock('../natcompare', () => ({strings: a => a}))

const defaultProps = overrides => ({
  allowedUpload: true,
  selectFile: jest.fn(),
  contentTypes: [],
  useContextAssets: false,
  searchString: '',
  onLoading: jest.fn(),
  context: {
    type: 'course',
    id: 1
  },
  contentTypes: ['**'],
  source: apiSource(),
  ...overrides
})

const subject = props => render(<FileBrowser {...props} />)

describe('FileBrowser', () => {
  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('componentDidMount()', () => {
    let props

    beforeEach(() => (props = defaultProps()))

    it('does not fetch the context root folder', async () => {
      const {queryByText} = subject(props)
      const folder = await waitFor(() => queryByText('Course files'))
      expect(folder).not.toBeInTheDocument()
    })

    it('fetches and renders the user root folder', async () => {
      const {getByText} = subject(props)
      const folder = await waitFor(() => getByText('My files'))
      expect(folder).toBeInTheDocument()
    })

    it('fetches root user folder data', async () => {
      const {getByText} = subject(props)
      await waitFor(() => getByText('My files'))
      expect(props.source.fetchBookmarkedData).toHaveBeenCalled()
    })

    it('fetches root user folder files', async () => {
      const {getByText} = subject(props)
      const folder = await waitFor(() => getByText('My files'))

      fireEvent.click(folder)
      const file = await waitFor(() => getByText('its-working-its-working.jpg'))
      expect(file).toBeInTheDocument()
    })

    describe('when "useContextAssets" is true', () => {
      beforeEach(() => (props = defaultProps({useContextAssets: true})))

      it('fetches and renders the context root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('Course files'))
        expect(folder).toBeInTheDocument()
      })

      it('fetches and renders the user root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))
        expect(folder).toBeInTheDocument()
      })

      it('fetches and renders the context root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('Course files'))
        fireEvent.click(folder)
        const file = await waitFor(() => getByText('its-working-its-working.jpg'))
        expect(file).toBeInTheDocument()
      })

      it('fetches root user folder files', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))

        fireEvent.click(folder)
        const file = await waitFor(() => getByText('its-working-its-working.jpg'))
        expect(file).toBeInTheDocument()
      })
    })
  })
})
