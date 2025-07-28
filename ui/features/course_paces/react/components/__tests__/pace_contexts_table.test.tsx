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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'

import PaceContextTable, {PaceContextsTableProps} from '../pace_contexts_table'
import {paceContextsActions} from '../../actions/pace_contexts'
import {Course} from '../../shared/types'
import {PaceContext} from '../../types'

const context1: PaceContext = {
  name: 'context1',
  type: 'section',
  item_id: '1',
  associated_section_count: 1,
  associated_student_count: 2,
  applied_pace: null,
  on_pace: null,
}

const context2: PaceContext = {
  name: 'context2',
  type: 'section',
  item_id: '2',
  associated_section_count: 1,
  associated_student_count: 1,
  applied_pace: null,
  on_pace: null,
}

const course: Course = {
  id: '1',
  name: 'CourseName',
  start_at: '01-01-2020',
  end_at: '10-10-2020',
  created_at: '01-01-2020',
}

const defaultProps: PaceContextsTableProps = {
  paceContexts: [context1, context2],
  contextType: 'section',
  pageCount: 1,
  currentPage: 1,
  currentSortBy: null,
  currentOrderType: 'asc',
  isLoading: false,
  responsiveSize: 'small',
  setPage: (page: number) => {},
  setOrderType: paceContextsActions.setOrderType,
  handleContextSelect: () => {},
  contextsPublishing: [],
  course: course,
  showCourseReport: jest.fn(),
  createCourseReport: jest.fn(),
}

beforeEach(() => {
  defaultProps.showCourseReport = jest.fn()
  defaultProps.createCourseReport = jest.fn()
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('PaceContextTable', () => {
  it('renders each pace context', async () => {
    const table = render(<PaceContextTable {...defaultProps} />)
    expect(table.getAllByText(/context/)).toHaveLength(defaultProps.paceContexts.length)
  })

  describe('when download document feature is enabled', () => {
    beforeEach(() => {
      ENV.FEATURES.course_pace_download_document = true
    })

    it('shows selectable contexts', () => {
      const table = render(<PaceContextTable {...defaultProps} />)

      const checkboxes = table.getAllByRole('checkbox')

      expect(checkboxes).toHaveLength(3)
    })

    it('shows selected context count', () => {
      const table = render(<PaceContextTable {...defaultProps} />)

      const checkbox = table.getAllByRole('checkbox')[1]
      fireEvent.click(checkbox)
      const selectionLabel = table.getByText('1 selected')

      expect(selectionLabel).toBeInTheDocument()
    })

    describe('download button', () => {
      it('invokes createCourseReport with selected contexts', () => {
        const table = render(<PaceContextTable {...defaultProps} />)

        const selectAllCheckbox = table.getAllByRole('checkbox')[0]
        fireEvent.click(selectAllCheckbox)

        const downloadButton = table.getByTestId('download-selected-button')
        fireEvent.click(downloadButton)

        expect(defaultProps.createCourseReport).toHaveBeenCalledWith({
          course_id: course.id,
          report_type: 'course_pace_docx',
          parameters: {
            enrollment_ids: [],
            section_ids: [context1.item_id, context2.item_id],
          },
          progress: 0,
        })
      })
    })
  })
})
