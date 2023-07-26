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
import {fireEvent, render} from '@testing-library/react'
import AlignmentOutcomeItemList from '../AlignmentOutcomeItemList'
import {generateRootGroup} from './testData'

describe('AlignmentOutcomeItemList', () => {
  let loadMore
  const defaultProps = (props = {}) => ({
    rootGroup: generateRootGroup(5),
    loading: false,
    loadMore,
    ...props,
  })

  beforeEach(() => {
    loadMore = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const mockContainer = (container, prop, value) => {
    jest.spyOn(container, prop, 'get').mockImplementation(() => value)
  }

  it('renders loader when loading prop is true', () => {
    const {queryByTestId} = render(<AlignmentOutcomeItemList {...defaultProps({loading: true})} />)
    expect(queryByTestId('outcome-item-list-loader')).toBeInTheDocument()
  })

  it('renders list of outcome alignments', () => {
    const {getByText} = render(<AlignmentOutcomeItemList {...defaultProps()} />)
    expect(getByText('Outcome 1')).toBeInTheDocument()
    expect(getByText('Outcome 2')).toBeInTheDocument()
    expect(getByText('Outcome 3')).toBeInTheDocument()
    expect(getByText('Outcome 4')).toBeInTheDocument()
    expect(getByText('Outcome 5')).toBeInTheDocument()
  })

  it('render icon and message when no outcome alignments', () => {
    const {getByText, getByTestId} = render(
      <AlignmentOutcomeItemList {...defaultProps({rootGroup: generateRootGroup(0)})} />
    )
    expect(getByTestId('no-outcomes-icon')).toBeInTheDocument()
    expect(getByText('Your search returned no results.')).toBeInTheDocument()
  })

  it('calls load more when hasMore is true and scroll reaches the infinite scroll threshold', () => {
    const scrollContainer = document.createElement('div')
    mockContainer(scrollContainer, 'scrollHeight', 1000)
    mockContainer(scrollContainer, 'clientHeight', 400)
    mockContainer(scrollContainer, 'scrollTop', 0)

    render(
      <AlignmentOutcomeItemList
        {...defaultProps({rootGroup: generateRootGroup(5, true), scrollContainer})}
      />
    )

    mockContainer(scrollContainer, 'scrollTop', 600)
    fireEvent.scroll(scrollContainer)
    expect(loadMore).toHaveBeenCalled()
  })

  it('doesnt calls load more when hasMore is false and scroll reaches the infinite scroll threshold', () => {
    const scrollContainer = document.createElement('div')
    mockContainer(scrollContainer, 'scrollHeight', 1000)
    mockContainer(scrollContainer, 'clientHeight', 400)
    mockContainer(scrollContainer, 'scrollTop', 0)

    render(<AlignmentOutcomeItemList {...defaultProps({scrollContainer})} />)

    mockContainer(scrollContainer, 'scrollTop', 600)
    fireEvent.scroll(scrollContainer)
    expect(loadMore).not.toHaveBeenCalled()
  })
})
