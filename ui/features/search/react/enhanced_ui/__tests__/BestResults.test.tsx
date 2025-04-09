/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import BestResults from '../BestResults'

const props = {
  courseId: '1',
  searchTerm: 'writing outlines',
  results: [
    {
      content_id: '3',
      content_type: 'Page',
      readable_type: 'page',
      title: 'Course Syllabus',
      body: 'You will submit outlines for your assignments before writing the final paper.',
      html_url: '/courses/1/pages/syllabus',
      distance: 0.9,
      relevance: 0.8,
    },
    {
      content_id: '7',
      content_type: 'Assignment',
      readable_type: 'assignment',
      title: 'Favorite Artist - Outline',
      body: `For your favorite artist essay, you will submit an outline covering the main points you will discuss in your paper.
       This should be a bulleted list containing your introduction, body, and conclusion.`,
      html_url: '/courses/1/assignments/7',
      distance: 0.9,
      relevance: 0.8,
    },
  ],
}

describe('BestResults', () => {
  it('should render multiple results', () => {
    const {getByText} = render(<BestResults {...props} />)

    expect(getByText('Best Matches')).toBeInTheDocument()
    expect(getByText('2 results for "writing outlines"')).toBeInTheDocument()
    expect(getByText('Course Syllabus')).toBeInTheDocument()
    expect(getByText('Favorite Artist - Outline')).toBeInTheDocument()
  })

  it('should show no result message when no results are found', () => {
    const {getByText} = render(<BestResults {...props} results={[]} />)

    expect(getByText('No best matches for "writing outlines"')).toBeInTheDocument()
    expect(getByText('Try a similar result below or start over.')).toBeInTheDocument()
  })

  it('renders Feedback component', () => {
    const {getByText} = render(<BestResults {...props} />)

    expect(getByText('Feedback')).toBeInTheDocument()
  })
})
