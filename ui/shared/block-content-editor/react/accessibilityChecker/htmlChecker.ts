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

import type {AccessibilityCheckResult, AccessibilityIssue, AccessibilityRule} from './types'
import {checkNode} from '@instructure/canvas-rce'
import {buttonBackgroundContrast} from './rules/buttonBackgroundContrast'
import {separatorLineContrast} from './rules/separatorLineContrast'

const customRules: AccessibilityRule[] = [buttonBackgroundContrast, separatorLineContrast]

export const checkHtmlContent = (htmlContent: Element): Promise<AccessibilityCheckResult> => {
  return new Promise(resolve => {
    if (!htmlContent) {
      resolve({
        issues: [],
      })
      return
    }

    checkNode(
      htmlContent,
      (errors: AccessibilityIssue[]) => {
        resolve({
          issues: errors || [],
        })
      },
      {},
      customRules,
    )
  })
}
