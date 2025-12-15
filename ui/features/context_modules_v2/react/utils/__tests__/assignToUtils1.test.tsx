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

import {type Root} from 'react-dom/client'
import {screen, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, graphql, HttpResponse} from 'msw'
import {renderItemAssignToManager} from '../assignToUtils'

interface HTMLElementWithRoot extends HTMLElement {
  reactRoot?: Root
}

const server = setupServer()

describe('assignToUtils', () => {
  describe('renderItemAssignToManager', () => {
    beforeAll(() => server.listen())
    afterAll(() => server.close())

    beforeEach(() => {
      document.body.innerHTML = `
      <div>
        <button id="return-focus-to-me">Return Focus To Me</button>
      </div>
      `

      const handlers = [
        http.get('/api/v1/courses/:courseId/assignments/:assignmentId/date_details', () => {
          return HttpResponse.json({
            id: '1',
            due_at: null,
            unlock_at: null,
            lock_at: null,
            only_visible_to_overrides: false,
            visible_to_everyone: true,
            group_category_id: null,
            graded: true,
            blueprint_date_locks: ['due_dates', 'availability_dates'],
            overrides: [],
          })
        }),
        http.get('/api/v1/courses/:courseId/settings', () => {
          return HttpResponse.json({})
        }),
        http.get('/api/v1/courses/:courseId/sections', () => {
          return HttpResponse.json([])
        }),
        graphql.query('Selective_Release_GetStudentsQuery', () => {
          return HttpResponse.json({
            data: {
              __typename: 'Query',
              legacyNode: {
                id: 'Q291cnNlLTQ=',
                name: 'course-1',
                enrollmentsConnection: {
                  edges: [],
                },
              },
            },
          })
        }),
      ]
      server.use(...handlers)
    })

    afterEach(() => {
      const container = document.getElementById(
        'module-item-assign-to-mount-point',
      ) as HTMLElementWithRoot
      if (container && container.reactRoot) {
        container.reactRoot.unmount()
      }
      document.body.innerHTML = ''
      server.resetHandlers()
    })

    it('should render the assign to tray', async () => {
      renderItemAssignToManager(
        true,
        document.getElementById('return-focus-to-me') as HTMLElement,
        {
          courseId: '1',
          moduleItemName: 'Test Item',
          moduleItemType: 'assignment',
          moduleItemContentId: '1',
          pointsPossible: 10,
          moduleId: '1',
          isCheckpointed: false,
          isGraded: true,
          cursor: null,
        },
      )
      await waitFor(() => {
        expect(screen.getByTestId('module-item-edit-tray')).toBeInTheDocument()
      })
      expect(screen.queryByTestId('due_at_input')).toBeInTheDocument()
    })
  })
})
