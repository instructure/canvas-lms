/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import type {LtiMessageHandler} from '../lti_message_handler'
const ENV = window.ENV as GlobalEnv

const getPageContent: LtiMessageHandler = ({responseMessages}) => {
  /* Get all included elements with data-lti-page-content="true"
   * and then remove all children with data-lti-page-content="false".
   * Finally, return the concatenated outerHTML of all elements with
   * empty newlines removed.
   */
  const content = Array.from(document.querySelectorAll('[data-lti-page-content="true"]')).reduce(
    (accumulator, element) => {
      if (!(element instanceof HTMLElement)) return accumulator

      const clonedElement = element.cloneNode(true) as HTMLElement
      clonedElement.querySelectorAll('[data-lti-page-content="false"]').forEach(excludedChild => {
        excludedChild.parentElement?.removeChild(excludedChild)
      })
      return accumulator + (clonedElement.outerHTML || '').replace(/\n\s*\n/gm, '\n')
    },
    '',
  )

  // ENV.ASSIGNMENT_ID may not always be there for assignments of type external_tool
  const contentId =
    ENV.ASSIGNMENT_ID ||
    assignmentIdFromUrl() ||
    // @ts-expect-error
    ENV.WIKI_PAGE?.page_id
  responseMessages.sendResponse({content, content_id: contentId ? parseInt(contentId) : -1})
  return true
}

function assignmentIdFromUrl(): string {
  const match = window.location?.pathname?.match(/\/assignments\/(\d+)/)
  return match && match[1] !== null ? match[1] : ''
}

export default getPageContent
