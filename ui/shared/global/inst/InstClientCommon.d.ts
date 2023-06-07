/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/**
 * Client-defined properties on INST.
 */
export type InstClientCommon = Partial<{
  /**
   * From addBrowserClasses.js
   */
  browser: {
    webkit: boolean
    chrome: boolean
    safari: boolean
    ff: boolean
    msie: boolean
    touch: boolean
    'no-touch': boolean
  }

  /**
   * From ajax_errors.js
   */
  errorCount: number

  /**
   * From ajax_errors.js
   */
  ajaxErrorURL: string

  /**
   * From ui/features/submission_download/jquery/index.js
   */
  downloadSubmissions(url: string, onClose: (e: unknown) => void)

  /**
   * From ui/features/submissions/jquery/index.js
   */
  refreshGrades()

  /**
   * A complex object that can be typed later
   *
   * From ui/features/user_lists/jquery/index.js
   */
  UserLists: unknown

  /**
   * From ui/shared/select-content-dialog/jquery/select_content_dialog.js
   */
  selectContentDialog(options: Record<string, unknown>)

  /**
   * From ui/shared/jquery/jquery.instructure_misc_helpers.js
   */
  youTubeRegEx: RegExp

  /**
   * From ui/shared/content-locks/jquery/lock_reason.js
   */
  lockExplanation(
    data: {
      lock_at?: string | null
      unlock_at?: string | null
      context_module?: {name?: string}
    },
    type: 'quiz' | 'assignment' | 'topic' | 'file' | 'page'
  ): string

  /**
   * From ui/shared/modules/jquery/prerequisites_lookup.js
   */
  lookupPrerequisites()

  /**
   * From ui/boot/initializers/trackPageViews.js
   */
  interaction_context: string
  /**
   * From ui/boot/initializers/trackPageViews.js
   */
  interaction_contexts: Record<string, number>

  /**
   * From packages/html-escape/index.ts
   */
  htmlEscape?(str: string): string
  /**
   * From packages/html-escape/index.ts
   */
  htmlEscape?(num: number): string
  /**
   * From packages/html-escape/index.ts
   *
   * Note that the return type isn't quite right, but it would require a recursive type to do right, and
   * doesn't feel worth it right now.
   */
  htmlEscape?<T extends Record<string, string | number>>(obj: T): T
}>
