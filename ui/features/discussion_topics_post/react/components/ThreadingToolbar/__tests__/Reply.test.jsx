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
import {Reply} from '../Reply'
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
    <Reply onClick={Function.prototype} delimiterKey="reply" authorName="Nikita" {...props} />
  )
}

describe('Reply', () => {
  it('uses authorName for screenreaders', () => {
    const {getByText} = setup()
    expect(getByText('Reply to post from Nikita')).toBeTruthy()
  })

  it('renders quote when in split screen view', () => {
    const {getByText} = setup({isSplitView: true})
    expect(getByText('Quote')).toBeTruthy()
  })

  it('calls provided callback when clicked', () => {
    const onClickMock = jest.fn()
    const {getByText} = setup({onClick: onClickMock})
    expect(onClickMock.mock.calls.length).toBe(0)
    fireEvent.click(getByText('Reply'))
    expect(onClickMock.mock.calls.length).toBe(1)
  })

  describe('Mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1024px'},
      }))
    })

    it('uses mobile prop values', () => {
      const container = setup()

      expect(container.getByTestId('threading-toolbar-reply').parentNode).toHaveStyle(
        'margin: 0px 0.75rem 0px 0px'
      )
    })
  })
})
