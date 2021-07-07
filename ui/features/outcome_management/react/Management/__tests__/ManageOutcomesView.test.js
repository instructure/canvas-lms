/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ManageOutcomesView from '../ManageOutcomesView'
import {outcomeGroup} from '@canvas/outcomes/mocks/Management'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'

describe('ManageOutcomesView', () => {
  let onSelectOutcomesHandler
  let onOutcomeGroupMenuHandler
  let onOutcomeMenuHandler
  let onSearchChangeHandler
  let onSearchClearHandler
  let loadMore
  const defaultProps = (props = {}) => ({
    outcomeGroup,
    selectedOutcomes: {1: true},
    searchString: 'abc',
    loading: false,
    onSelectOutcomesHandler,
    onOutcomeGroupMenuHandler,
    onOutcomeMenuHandler,
    onSearchChangeHandler,
    onSearchClearHandler,
    loadMore,
    isRootGroup: false,
    ...props
  })

  beforeEach(() => {
    onSelectOutcomesHandler = jest.fn()
    onOutcomeGroupMenuHandler = jest.fn()
    onOutcomeMenuHandler = jest.fn()
    onSearchChangeHandler = jest.fn()
    onSearchClearHandler = jest.fn()
    loadMore = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const mockContainer = (container, prop, value) => {
    jest.spyOn(container, prop, 'get').mockImplementation(() => value)
  }

  it('renders loading indicator', () => {
    const {queryByTestId} = render(
      <ManageOutcomesView {...defaultProps({outcomeGroup: null, loading: true})} />
    )
    expect(queryByTestId('loading')).toBeInTheDocument()
  })

  it('renders group title if outcomeGroup prop provided with id and title only', () => {
    const {queryByTestId} = render(
      <ManageOutcomesView
        {...defaultProps({
          outcomeGroup: {
            _id: '1',
            title: 'Group Title',
            outcomesCount: 0,
            outcomes: {edges: [], pageInfo: {hasNextPage: false}},
            canEdit: true
          }
        })}
      />
    )
    expect(queryByTestId('outcome-group-container')).toBeInTheDocument()
  })

  it('renders outcomes count', () => {
    const {getByText} = render(<ManageOutcomesView {...defaultProps()} />)
    expect(
      getByText(`15 "${addZeroWidthSpace('Grade.2.Math.3A.Elementary.CCSS.Calculus.1')}" Outcomes`)
    ).toBeInTheDocument()
  })

  it('renders list of outcomes', () => {
    const {getAllByText} = render(<ManageOutcomesView {...defaultProps()} />)
    expect(
      getAllByText(
        'Partition circles and rectangle into two, three, or four equal share. Partition circles and rectangle into two, three, or four equal share.'
      ).length
    ).not.toBe(0)
  })

  it('does not render component if outcomeGroup not provided', () => {
    const {queryByTestId} = render(<ManageOutcomesView {...defaultProps({outcomeGroup: null})} />)
    expect(queryByTestId('outcome-group-container')).not.toBeInTheDocument()
  })

  describe('kebab menu', () => {
    it('is not rendered if canEdit is false', () => {
      const {queryByText} = render(
        <ManageOutcomesView
          {...defaultProps({
            outcomeGroup: {
              _id: '1',
              title: 'Group Title',
              outcomesCount: 0,
              outcomes: {edges: [], pageInfo: {hasNextPage: false}},
              canEdit: false
            }
          })}
        />
      )
      expect(queryByText('Outcome Group Menu')).not.toBeInTheDocument()
    })

    it('is not rendered if isRootGroup is true', () => {
      const {queryByText} = render(<ManageOutcomesView {...defaultProps({isRootGroup: true})} />)
      expect(queryByText('Outcome Group Menu')).not.toBeInTheDocument()
    })

    it('rendered if canEdit is true', () => {
      const {getByText} = render(<ManageOutcomesView {...defaultProps()} />)
      expect(getByText('Outcome Group Menu')).toBeInTheDocument()
    })
  })

  it('shows small loader when searching for outcomes', () => {
    const {getByTestId} = render(
      <ManageOutcomesView {...defaultProps({loading: true, searchString: 'test'})} />
    )
    expect(getByTestId('search-loading')).toBeInTheDocument()
  })

  it('render a message when search does not return any result', () => {
    const {queryByText} = render(
      <ManageOutcomesView
        {...defaultProps({
          outcomeGroup: {
            _id: '1',
            title: 'Group Title',
            outcomesCount: 0,
            outcomes: {edges: [], pageInfo: {hasNextPage: false}},
            canEdit: false
          }
        })}
      />
    )
    expect(queryByText('The search returned no results')).toBeInTheDocument()
  })

  it('does not render a message when does not have search when group does not have outcome', () => {
    const {queryByText} = render(
      <ManageOutcomesView
        {...defaultProps({
          searchString: '',
          outcomeGroup: {
            _id: '1',
            title: 'Group Title',
            outcomesCount: 0,
            outcomes: {edges: [], pageInfo: {hasNextPage: false}},
            canEdit: false
          }
        })}
      />
    )
    expect(queryByText('The search returned no results')).not.toBeInTheDocument()
  })

  it('calls load more when hasNextPage is true and scroll reaches the infinite scroll threshold', () => {
    const scrollContainer = document.createElement('div')
    mockContainer(scrollContainer, 'scrollHeight', 1000)
    mockContainer(scrollContainer, 'clientHeight', 400)
    mockContainer(scrollContainer, 'scrollTop', 0)

    render(
      <ManageOutcomesView
        {...defaultProps({
          scrollContainer,
          outcomeGroup: {
            _id: '1',
            title: 'Group Title',
            outcomesCount: 0,
            outcomes: {edges: [], pageInfo: {hasNextPage: true}},
            canEdit: false
          }
        })}
      />
    )

    mockContainer(scrollContainer, 'scrollTop', 600)
    fireEvent.scroll(scrollContainer)
    expect(loadMore).toHaveBeenCalled()
  })

  it('doesnt calls load more when hasNextPage is false and scroll reaches the infinite scroll threshold', () => {
    const scrollContainer = document.createElement('div')
    mockContainer(scrollContainer, 'scrollHeight', 1000)
    mockContainer(scrollContainer, 'clientHeight', 400)
    mockContainer(scrollContainer, 'scrollTop', 0)

    render(
      <ManageOutcomesView
        {...defaultProps({
          scrollContainer
        })}
      />
    )

    mockContainer(scrollContainer, 'scrollTop', 600)
    fireEvent.scroll(scrollContainer)
    expect(loadMore).not.toHaveBeenCalled()
  })
})
