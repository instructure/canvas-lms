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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {Expansion} from '../Expansion'
import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = props => {
  return render(
    <Expansion
      isExpanded={true}
      onClick={Function.prototype}
      delimiterKey="expansion"
      expandText=""
      {...props}
    />
  )
}

describe('Expansion', () => {
  it('calls provided callback when clicked', () => {
    const onClickMock = jest.fn()
    const {getByText} = setup({
      onClick: onClickMock,
      expandText: '4 replies',
    })
    expect(onClickMock.mock.calls.length).toBe(0)
    fireEvent.click(getByText('4 replies'))
    expect(onClickMock.mock.calls.length).toBe(1)
  })

  it('indicates expansion status', () => {
    const {queryByTestId, rerender} = setup({isExpanded: false})
    expect(queryByTestId('reply-expansion-btn-expand')).toBeTruthy()
    expect(queryByTestId('reply-expansion-btn-collapse')).toBeFalsy()

    rerender(
      <Expansion
        onClick={Function.prototype}
        isExpanded={true}
        delimiterKey="expansion"
        expandText=""
      />
    )

    expect(queryByTestId('reply-expansion-btn-expand')).toBeFalsy()
    expect(queryByTestId('reply-expansion-btn-collapse')).toBeTruthy()
  })

  it('displays as readonly if isReadOnly is true', () => {
    const {getByText} = setup({isExpanded: false, isReadOnly: true, expandText: '4 replies'})
    expect(getByText('4 replies').closest('button').hasAttribute('aria-disabled')).toBe(true)
  })

  describe('Mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1024px'},
      }))
    })

    it('uses mobile prop values', () => {
      const container = setup()
      const smallText = container.getByTestId('text-small')

      expect(smallText).toBeTruthy()
    })
  })
})
