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
import {MockedProvider} from '@apollo/react-testing'
import {act, render as rtlRender} from '@testing-library/react'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {createCache} from '@canvas/apollo'
import {commentBankItemMocks} from './mocks'
import LibraryManager from '../LibraryManager'

jest.useFakeTimers()

describe('LibraryManager', () => {
  beforeEach(() => {
    window.ENV = {
      context_asset_string: 'course_1'
    }
  })

  afterEach(() => {
    window.ENV = {}
  })

  const defaultProps = (props = {}) => {
    return {
      setComment: () => {},
      ...props
    }
  }

  const render = ({
    props = defaultProps(),
    mocks = commentBankItemMocks({numberOfComments: 10})
  } = {}) =>
    rtlRender(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <LibraryManager {...props} />
      </MockedProvider>
    )

  describe('query', () => {
    it('renders a loading spinner while loading', () => {
      const {getByText} = render(defaultProps())
      expect(getByText('Loading comment library')).toBeInTheDocument()
    })

    it('displays an error if the comments couldnt be fetched', async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      render({mocks: []})
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error loading comment library',
        type: 'error'
      })
    })
  })
})
