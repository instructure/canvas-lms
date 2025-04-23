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
import ResultCard from '../ResultCard'

const props = {
  searchTerm: 'writing outlines',
  result: {
    content_id: '3',
    content_type: 'Page',
    readable_type: 'page',
    title: 'Course Syllabus',
    body: 'You will submit outlines for your assignments before writing the final paper.',
    html_url: '/courses/1/pages/syllabus',
    distance: 0.9,
    relevance: 0.8,
  },
}

describe('ResultCard', () => {
  it('should render title and content', () => {
    const {getByText, getByTestId} = render(<ResultCard {...props} />)

    expect(getByText('Course Syllabus')).toBeInTheDocument()
    expect(getByText(/outlines/)).toBeInTheDocument()
    expect(getByText(/writing/)).toBeInTheDocument()
    expect(getByTestId('document_icon')).toBeInTheDocument()
  })
})
