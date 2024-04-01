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

import {render} from '@testing-library/react'
import React from 'react'
import {SearchSpan} from '../SearchSpan'

const setup = props => {
  return render(<SearchSpan searchTerm="" text="" {...props} />)
}

describe('SearchSpan', () => {
  it('should perform no highlights if no searchTerm is present', () => {
    const {queryAllByTestId} = setup()
    expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
  })

  it('should highlight search term if found in message', () => {
    const {queryAllByTestId} = setup({searchTerm: 'Posts', text: 'Posts'})
    expect(queryAllByTestId('highlighted-search-item').length).toBe(1)
  })

  it('should not create highlight spans if no term is found', () => {
    const {queryAllByTestId} = setup({searchTerm: 'Posts', text: 'A message'})
    expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
  })

  it('should highlight multiple terms in message', () => {
    const {queryAllByTestId} = setup({
      searchTerm: 'here',
      text: 'a longer message with multiple highlights here and here',
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
  })

  it('highlighting should be case-insensitive', () => {
    const {queryAllByTestId} = setup({
      searchTerm: 'here',
      text: 'here and HeRe',
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
  })

  it('should not highlight when in split screen view', () => {
    const {queryAllByTestId} = setup({
      searchTerm: 'here',
      text: 'here and HeRe',
      isSplitView: true,
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(0)
  })

  it('should remove inner html tags', () => {
    const container = setup({
      searchTerm: 'strong',
      text: "Around here, however, we don't look backwards for very long. <strong>We keep moving forward</strong>, opening up new doors and doing new things, because we're curious... and curiosity keeps leading us down new paths.",
    })
    expect(container.queryAllByTestId('highlighted-search-item').length).toBe(0)
    expect(container.queryByText('strong')).toBeNull()
  })

  it('should ignore iframe html tags', () => {
    const iframe = `<iframe style="width: 400px; height: 225px; display: inline-block;" title="Video player for 2023-05-23 13-24-01.mp4" data-media-type="video" src="https://mediacenter.com" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-4ws5T"></iframe>`
    const content = `<p>Testing whether only the iframe html tag is ignored: ${iframe}<br /> will the i-f-r-a-m-e html ta get highlighted?</p>`

    const container = setup({
      searchTerm: 'iframe',
      text: content,
    })

    // iframe is in the content 3 times
    expect(content.split('iframe').length - 1).toBe(3)
    // only the 'iframe' text that is not in an html tag should be highlighted.
    expect(container.queryAllByTestId('highlighted-search-item').length).toBe(1)
    // The iframe html tag wasn't removed
    expect(container.container.innerHTML).toContain('<iframe')
  })

  it('should handle special characters in searchTerm', () => {
    const {queryAllByTestId} = setup({
      searchTerm: '(',
      text: 'This is a (here) test with (here) special characters',
    })
    expect(queryAllByTestId('highlighted-search-item').length).toBe(2)
  })
})
