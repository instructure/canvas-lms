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
import {render, fireEvent} from '@testing-library/react'
import OutcomeDescription from '../OutcomeDescription'

describe('OutcomeDescription', () => {
  let onClickHandlerMock
  const empty = ''
  const truncatedTestId = 'description-truncated'
  const expandedTestId = 'description-expanded'
  const defaultProps = (props = {}) => ({
    withExternalControl: true,
    truncate: true,
    description: 'Description',
    onClickHandler: onClickHandlerMock,
    ...props
  })

  beforeEach(() => {
    onClickHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('with External Control', () => {
    it('renders truncated Description when description prop provided and truncate prop true', () => {
      const {queryByTestId} = render(<OutcomeDescription {...defaultProps()} />)
      expect(queryByTestId(truncatedTestId)).toBeInTheDocument()
    })

    it('renders expanded Description when description prop provided and truncate prop false', () => {
      const {queryByTestId} = render(<OutcomeDescription {...defaultProps({truncate: false})} />)
      expect(queryByTestId(expandedTestId)).toBeInTheDocument()
    })

    it('does not render Description when description prop not provided/null', () => {
      const {queryByTestId} = render(<OutcomeDescription {...defaultProps({description: null})} />)
      expect(queryByTestId(truncatedTestId)).not.toBeInTheDocument()
    })

    it('does not render Description when description prop is empty', () => {
      const {queryByTestId} = render(<OutcomeDescription {...defaultProps({description: empty})} />)
      expect(queryByTestId(truncatedTestId)).not.toBeInTheDocument()
    })

    it('calls click handler when user clicks on truncated description', () => {
      const {getByTestId} = render(<OutcomeDescription {...defaultProps()} />)
      const descTruncated = getByTestId(truncatedTestId)
      fireEvent.click(descTruncated)
      expect(onClickHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('calls click handler when user clicks on expanded description', () => {
      const {getByTestId} = render(<OutcomeDescription {...defaultProps({truncate: false})} />)
      const descExpanded = getByTestId(expandedTestId)
      fireEvent.click(descExpanded)
      expect(onClickHandlerMock).toHaveBeenCalledTimes(1)
    })
  })

  describe('with Internal Control', () => {
    it('renders truncated Description when description prop provided', () => {
      const {queryByTestId} = render(
        <OutcomeDescription {...defaultProps({withExternalControl: false})} />
      )
      expect(queryByTestId(truncatedTestId)).toBeInTheDocument()
    })

    it('does not render Description when description prop not provided/null', () => {
      const {queryByTestId} = render(
        <OutcomeDescription {...defaultProps({withExternalControl: false, description: null})} />
      )
      expect(queryByTestId(truncatedTestId)).not.toBeInTheDocument()
    })

    it('does not render Description when description prop is empty', () => {
      const {queryByTestId} = render(
        <OutcomeDescription {...defaultProps({withExternalControl: false, description: empty})} />
      )
      expect(queryByTestId(truncatedTestId)).not.toBeInTheDocument()
    })

    it('expands description when when user clicks on truncated description', () => {
      const {getByTestId, queryByTestId} = render(
        <OutcomeDescription {...defaultProps({withExternalControl: false})} />
      )
      const descTruncated = getByTestId(truncatedTestId)
      fireEvent.click(descTruncated)
      expect(queryByTestId(expandedTestId)).toBeInTheDocument()
    })

    it('truncates description when when user clicks on expanded description', () => {
      const {getByTestId, queryByTestId} = render(
        <OutcomeDescription {...defaultProps({withExternalControl: false})} />
      )
      const descTruncated = getByTestId(truncatedTestId)
      fireEvent.click(descTruncated)
      const descExpanded = getByTestId(expandedTestId)
      fireEvent.click(descExpanded)
      expect(queryByTestId(truncatedTestId)).toBeInTheDocument()
    })
  })
})
