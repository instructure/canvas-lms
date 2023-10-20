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

import ModeSelect from '../ModeSelect'
import {actions} from '../../../../reducers/imageSection'

describe('ModeSelect', () => {
  const defaultProps = {dispatch: jest.fn()}
  const subject = overrides => render(<ModeSelect {...{...defaultProps, ...overrides}} />)

  afterEach(() => jest.resetAllMocks())

  it('renders the "Add Image" button', () => {
    const {getByText} = subject()
    expect(getByText('Add Image')).toBeInTheDocument()
  })

  describe('with the menu open', () => {
    let getByText

    beforeEach(() => {
      const rendered = subject()
      getByText = rendered.getByText
      fireEvent.click(getByText('Add Image'))
    })

    it('renders the upload images option', () => {
      expect(getByText('Upload Image')).toBeInTheDocument()
    })

    it('renders the singe color images option', () => {
      expect(getByText('Single Color Image')).toBeInTheDocument()
    })

    it('renders the multi color images option', () => {
      expect(getByText('Multi Color Image')).toBeInTheDocument()
    })

    it('renders the course images option', () => {
      expect(getByText('Course Images')).toBeInTheDocument()
    })

    const sharedExamplesForMenuItemClick = type => {
      it('dispatches the correct action', () => {
        expect(defaultProps.dispatch).toHaveBeenCalledWith({type})
        expect(defaultProps.dispatch).toHaveBeenCalledWith({
          ...actions.SET_IMAGE_COLLECTION_OPEN,
          payload: true,
        })
      })
    }

    describe('when the upload images option is clicked', () => {
      beforeEach(() => {
        fireEvent.click(getByText('Upload Image'))
      })

      sharedExamplesForMenuItemClick('Upload')
    })

    describe('when the singe color images option is clicked', () => {
      beforeEach(() => {
        fireEvent.click(getByText('Single Color Image'))
      })

      sharedExamplesForMenuItemClick('SingleColor')
    })

    describe('when the multi color images option is clicked', () => {
      beforeEach(() => {
        fireEvent.click(getByText('Multi Color Image'))
      })

      sharedExamplesForMenuItemClick('MultiColor')
    })

    describe('when the course images option is clicked', () => {
      beforeEach(() => {
        fireEvent.click(getByText('Course Images'))
      })

      sharedExamplesForMenuItemClick('Course')
    })
  })
})
