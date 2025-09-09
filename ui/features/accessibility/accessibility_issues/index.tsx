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

import AccessibilityIssuesPage from './react/components/AccessibilityIssuesPage/AccessibilityIssuesPage'
import ready from '../../../../packages/ready'
import {createRoot} from 'react-dom/client'

ready(() => {
  const container = document.getElementById('accessibility-issues-page-container')

  if (!container) {
    return
  }
  const courseId: string = container.getAttribute('data-course-id') || ''
  const issueId: string = container.getAttribute('data-issue-id') || ''

  const root = createRoot(container)
  root.render(<AccessibilityIssuesPage courseId={courseId!} issueId={issueId!} />)
})
