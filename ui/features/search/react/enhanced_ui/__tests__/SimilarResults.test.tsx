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
import SimilarResults from '../SimilarResults'

const props = {
  searchTerm: 'writing outlines',
  results: [
    {
      content_id: '3',
      content_type: 'Announcement',
      readable_type: 'announcement',
      title: 'The Writings of John Doe due tomorow',
      body: 'Submit your reports tomorrow by 5pm',
      html_url: '/courses/1/pages/syllabus',
      distance: 0.7,
      relevance: 0.3,
    },
    {
      content_id: '7',
      content_type: 'DiscussionTopic',
      readable_type: 'Disucssion',
      title: 'Group Discussion #12',
      body: `Explain why John Doe is your favorite writer.`,
      html_url: '/courses/1/discussions/7',
      distance: 0.2,
      relevance: 0.4,
    },
  ],
}

describe('SimilarResults', () => {
  it('should render multiple results', () => {
    const {getByText} = render(<SimilarResults {...props} />)

    expect(getByText('Similar Results')).toBeInTheDocument()
    expect(getByText(/While not a direct match/)).toBeInTheDocument()
    expect(getByText(/Writings of John Doe/)).toBeInTheDocument()
    expect(getByText(/Group Discussion/)).toBeInTheDocument()
  })
})
