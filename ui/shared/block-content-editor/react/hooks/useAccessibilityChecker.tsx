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

import type {AccessibilityIssue, AccessibilityIssuesMap} from '../accessibilityChecker/types'
import {useAppSetStore} from '../store'

const sumIssues = (issues: AccessibilityIssuesMap) => {
  // Only explicit iteration is supported by immer's Draft type
  let sum = 0
  for (const issueList of issues.values()) {
    sum += issueList.length
  }
  return sum
}

export const useAccessibilityChecker = () => {
  const set = useAppSetStore()

  const addA11yIssues = (editorId: string, issues: AccessibilityIssue[]) => {
    set(state => {
      state.accessibility.a11yIssues.set(editorId, issues)
      state.accessibility.a11yIssueCount = sumIssues(state.accessibility.a11yIssues)
    })
  }

  const removeA11yIssues = (editorId: string) => {
    set(state => {
      state.accessibility.a11yIssues.delete(editorId)
      state.accessibility.a11yIssueCount = sumIssues(state.accessibility.a11yIssues)
    })
  }

  return {
    addA11yIssues,
    removeA11yIssues,
  }
}
