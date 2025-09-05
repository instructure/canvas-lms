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

import {useState} from 'react'
import type {AccessibilityIssue, AccessibilityIssuesMap} from '../accessibilityChecker/types'

export const useAccessibilityChecker = () => {
  const [a11yIssues, setA11yIssues] = useState<AccessibilityIssuesMap>(new Map())

  const addA11yIssues = (editorId: string, issues: AccessibilityIssue[]) => {
    setA11yIssues(prev => {
      const newMap = new Map(prev)
      newMap.set(editorId, issues)
      return newMap
    })
  }

  const removeA11yIssues = (editorId: string) => {
    setA11yIssues(prev => {
      const newMap = new Map(prev)
      newMap.delete(editorId)
      return newMap
    })
  }

  const a11yIssueCount = Array.from(a11yIssues.values()).reduce(
    (total, issues) => total + issues.length,
    0,
  )

  return {
    a11yIssueCount,
    a11yIssues,
    addA11yIssues,
    removeA11yIssues,
  }
}
