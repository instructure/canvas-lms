/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import GradebookHistoryApp from '../GradebookHistoryApp'

vi.mock('../SearchForm', () => ({
  default: function MockSearchForm() {
    return <div data-testid="search-form">SearchForm</div>
  },
}))

vi.mock('../SearchResults', () => ({
  default: function MockSearchResults() {
    return <div data-testid="search-results">SearchResults</div>
  },
}))

vi.mock('@canvas/gradebook-menu', () => ({
  default: function MockGradebookMenu(props) {
    return (
      <div
        data-testid="gradebook-menu"
        data-course-url={props.courseUrl}
        data-learning-mastery-enabled={props.learningMasteryEnabled}
      >
        GradebookMenu
      </div>
    )
  },
}))

describe('GradebookHistoryApp', () => {
  it('renders the heading', () => {
    const {getByRole} = render(<GradebookHistoryApp courseUrl="/courseUrl" />)
    const heading = getByRole('heading', {name: 'Gradebook History'})
    expect(heading).toBeInTheDocument()
  })

  it.skip('renders SearchForm component', () => {
    const {getByTestId} = render(<GradebookHistoryApp courseUrl="/courseUrl" />)
    expect(getByTestId('search-form')).toBeInTheDocument()
  })

  it.skip('renders SearchResults component', () => {
    const {getByTestId} = render(<GradebookHistoryApp courseUrl="/courseUrl" />)
    expect(getByTestId('search-results')).toBeInTheDocument()
  })

  describe('GradebookMenu', () => {
    it.skip('is passed the provided courseUrl prop', () => {
      const {getByTestId} = render(
        <GradebookHistoryApp courseUrl="/courseUrl" learningMasteryEnabled={true} />,
      )
      const menu = getByTestId('gradebook-menu')
      expect(menu).toHaveAttribute('data-course-url', '/courseUrl')
    })

    it.skip('is passed the provided learningMasteryEnabled prop', () => {
      const {getByTestId} = render(
        <GradebookHistoryApp courseUrl="/courseUrl" learningMasteryEnabled={false} />,
      )
      const menu = getByTestId('gradebook-menu')
      expect(menu).toHaveAttribute('data-learning-mastery-enabled', 'false')
    })
  })
})
