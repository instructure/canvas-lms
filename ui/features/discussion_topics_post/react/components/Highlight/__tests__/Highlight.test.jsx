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

import {render, act} from '@testing-library/react'
import React from 'react'
import {Highlight} from '../Highlight'
import {DiscussionManagerUtilityContext} from '../../../utils/constants'

jest.useFakeTimers()

const setup = props => {
  return render(
    <DiscussionManagerUtilityContext.Provider
      value={{focusSelector: '', setFocusSelector: jest.fn()}}
    >
      <Highlight {...props}>
        <button>Test Button</button>
      </Highlight>
    </DiscussionManagerUtilityContext.Provider>,
  )
}

describe('Highlight', () => {
  let originalWindowLocation

  beforeEach(() => {
    originalWindowLocation = window.location
    // Create a new URL without params
    const newUrl = new URL(window.location.href)
    newUrl.search = ''
    window.history.pushState({}, '', newUrl.toString())

    // Mock scrollIntoView since it's not implemented in JSDOM
    Element.prototype.scrollIntoView = jest.fn()
  })

  afterEach(() => {
    // Restore original URL
    window.history.pushState({}, '', originalWindowLocation.href)
    jest.clearAllMocks()
  })

  it('displays the highlight', async () => {
    const {getByTestId} = setup({isHighlighted: true})

    await act(async () => {
      // Allow layout effects to complete
      await Promise.resolve()
      // Allow setTimeout to complete
      jest.runAllTimers()
    })

    expect(getByTestId('isHighlighted')).toBeInTheDocument()
    expect(getByTestId('isHighlighted')).toHaveClass('highlight-fadeout')
  })

  it('displays the highlight with persist', async () => {
    await act(async () => {
      window.history.pushState({}, '', '?persist=1')
    })

    const {getByTestId} = setup({isHighlighted: true})

    await act(async () => {
      // Allow layout effects to complete
      await Promise.resolve()
      // Allow setTimeout to complete
      jest.runAllTimers()
    })

    expect(getByTestId('isHighlighted')).toHaveClass('highlight-discussion')
  })

  it('does not display the highlight', () => {
    const {queryByTestId} = setup({isHighlighted: false})
    expect(queryByTestId('isHighlighted')).not.toBeInTheDocument()
  })
})
