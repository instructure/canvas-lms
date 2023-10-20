/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'

import SingleColor from '../index'
import {actions} from '../../../../../reducers/imageSection'
import svg from '../svg'

describe('SingleColor', () => {
  let dispatch, data, onLoaded

  beforeEach(() => {
    dispatch = jest.fn()
    data = {iconColor: '#FF00FF'}
    onLoaded = jest.fn()
  })

  afterEach(() => jest.clearAllMocks())

  const subject = () => render(<SingleColor dispatch={dispatch} data={data} onLoaded={onLoaded} />)

  it('renders the single-color SVG list', () => {
    const {getByTestId} = subject()
    expect(getByTestId('singlecolor-svg-list')).toBeInTheDocument()
  })

  describe('when an entry is clicked', () => {
    it('sets the selected image with loading states', async () => {
      const {getByTestId} = subject()

      fireEvent.click(getByTestId('icon-maker-art'))

      expect(dispatch).toHaveBeenNthCalledWith(1, {
        ...actions.SET_IMAGE_NAME,
        payload: 'Art Icon',
      })

      expect(dispatch).toHaveBeenNthCalledWith(2, {
        ...actions.SET_ICON,
        payload: 'art',
      })

      expect(dispatch).toHaveBeenNthCalledWith(3, {
        ...actions.SET_IMAGE_COLLECTION_OPEN,
        payload: false,
      })
    })
  })

  it('calls "onLoaded" when mounting', () => {
    subject()
    expect(onLoaded).toHaveBeenCalled()
  })
})
