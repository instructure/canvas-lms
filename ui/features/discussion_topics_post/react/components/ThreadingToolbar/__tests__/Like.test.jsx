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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {Like} from '../Like'
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
    <Like
      isLiked={true}
      onClick={Function.prototype}
      delimiterKey="like"
      likeCount={0}
      authorName="Xerxes"
      {...props}
    />,
  )
}

describe('Like', () => {
  it('calls provided callback when clicked', () => {
    const onClickMock = jest.fn()
    const {getByTestId} = setup({onClick: onClickMock})
    expect(onClickMock.mock.calls).toHaveLength(0)
    fireEvent.click(getByTestId('like-button'))
    expect(onClickMock.mock.calls).toHaveLength(1)
  })

  it('displays like count', () => {
    const {getByText, getByTestId} = setup({likeCount: 2})
    expect(getByText('Like count: 2')).toBeTruthy()
    expect(getByTestId('like-count').textContent).toContain('2 Likes')
  })

  it('displays 1 like', () => {
    const {getByText, getByTestId} = setup({likeCount: 1})
    expect(getByText('Like count: 1')).toBeTruthy()
    expect(getByTestId('like-count').textContent).toContain('1 Like')
  })

  it('indicates like status', () => {
    const {queryByTestId, queryByText, rerender} = setup({
      isLiked: false,
    })
    expect(queryByTestId('not-liked-icon')).toBeTruthy()
    expect(queryByTestId('liked-icon')).toBeFalsy()
    expect(queryByText('Like post from Xerxes')).toBeTruthy()
    expect(queryByText('Unlike post from Xerxes')).toBeFalsy()
    expect(queryByTestId('like-button')).toHaveAttribute('data-action-state', 'likeButton')

    rerender(
      <Like
        onClick={Function.prototype}
        isLiked={true}
        authorName="Xerxes"
        delimiterKey="like"
        likeCount={0}
      />,
    )

    expect(queryByTestId('not-liked-icon')).toBeFalsy()
    expect(queryByTestId('liked-icon')).toBeTruthy()
    expect(queryByText('Like post from Xerxes')).toBeFalsy()
    expect(queryByText('Unlike post from Xerxes')).toBeTruthy()
    expect(queryByTestId('like-button')).toHaveAttribute('data-action-state', 'unlikeButton')
  })
})
