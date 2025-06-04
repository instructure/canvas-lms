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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import type {ModuleItemContent, CompletionRequirement} from '../../utils/types'
import DueDateLabel from '../DueDateLabel'

const currentDate = new Date().toISOString()
const defaultContent: ModuleItemContent = {
  id: '19',
  title: 'Test Module Item',
  dueAt: currentDate,
  pointsPossible: 100,
}

const contentWithManyDueDates: ModuleItemContent = {
  ...defaultContent,
  assignmentOverrides: {
    edges: [
      {
        cursor: 'cursor',
        node: {
          set: {
            students: [
              {
                id: 'student_id_1',
              },
            ],
          },
          dueAt: new Date().addDays(-1).toISOString(), // # yesterday
        },
      },
      {
        cursor: 'cursor_2',
        node: {
          set: {
            sectionId: 'section_id',
          },
          dueAt: new Date().addDays(1).toISOString(), // # tomorrow
        },
      },
    ],
  },
}

const setUp = (content: ModuleItemContent = defaultContent) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <DueDateLabel content={content} contentTagId="19" />
    </ContextModuleProvider>,
  )
}

describe('DueDateLabel', () => {
  describe('with single due date', () => {
    it('renders', () => {
      const container = setUp()
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
    })
  })
  describe('with multiple due dates', () => {
    it('renders', () => {
      const container = setUp(contentWithManyDueDates)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows tooltip with details upon hover', async () => {
      const container = setUp(contentWithManyDueDates)

      fireEvent.mouseOver(container.getByText('Multiple Due Dates'))

      await waitFor(() => container.getByTestId('override-details'))

      expect(container.getByTestId('override-details')).toHaveTextContent('1 student')
      expect(container.getByTestId('override-details')).toHaveTextContent('1 section')
    })
  })
})
