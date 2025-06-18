/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import LoadingPastIndicator from '../index'

jest.mock('../../../utilities/scrollUtils')

describe('LoadingPastIndicator', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders an empty container when no props are provided', () => {
    const {container} = render(<LoadingPastIndicator />)

    // Should render an empty div without any content
    expect(container.firstChild).toBeEmptyDOMElement()
  })

  it('renders a spinner with loading text while loading past items', () => {
    const {getAllByText, getByRole} = render(<LoadingPastIndicator loadingPast={true} />)

    // Should show the loading spinner
    const spinner = getByRole('img')
    expect(spinner).toBeInTheDocument()

    // Should show the loading text (there are multiple elements with this text)
    const loadingTexts = getAllByText('Loading past items')
    expect(loadingTexts.length).toBeGreaterThan(0)
  })

  it('prioritizes showing completed state over loading state', () => {
    const {getByText, queryByTitle} = render(
      <LoadingPastIndicator loadingPast={true} allPastItemsLoaded={true} />,
    )

    // Should not show the loading spinner
    expect(queryByTitle('Loading past items')).not.toBeInTheDocument()

    // Should show the completion message
    expect(getByText('Beginning of Your To-Do History')).toBeInTheDocument()
    expect(getByText("You've scrolled back to your very first To-Do!")).toBeInTheDocument()
  })

  it('renders TV icon and completion message when all past items are loaded', () => {
    const {getByText, container} = render(<LoadingPastIndicator allPastItemsLoaded={true} />)

    // Should show the TV icon
    const tvIcon = container.querySelector('svg')
    expect(tvIcon).toBeInTheDocument()
    expect(tvIcon).toHaveAttribute('role', 'img')
    expect(tvIcon).toHaveAttribute('aria-hidden', 'true')

    // Should show the completion messages
    expect(getByText('Beginning of Your To-Do History')).toBeInTheDocument()
    expect(getByText("You've scrolled back to your very first To-Do!")).toBeInTheDocument()
  })

  it('shows an error alert when there is a loading error', () => {
    const {getByText} = render(<LoadingPastIndicator loadingError="uh oh" />)

    // Should show the error message
    expect(getByText('Error loading past items')).toBeInTheDocument()

    // Should include the actual error message in the DOM for debugging
    expect(getByText('uh oh')).toBeInTheDocument()
  })
})
