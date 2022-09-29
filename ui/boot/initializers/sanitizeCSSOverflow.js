/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ready from '@instructure/ready'

// Dynamically disallow fixed position element in user generated content.
// Based on the comments made in the comments of this Jira ticket
// https://instructure.atlassian.net/browse/SEC-2876
function sanitizeOverflow() {
  document.querySelectorAll('.user_content').forEach(element =>
    element.querySelectorAll('*').forEach(innerElement => {
      const style = getComputedStyle(innerElement)
      if (style.position === 'fixed') {
        innerElement.style.position = 'relative'
      }
    })
  )
}
const observer = new MutationObserver(function (e) {
  // If there are any added nodes, sanitize them.
  if (e.find(mutationRecord => mutationRecord.addedNodes.length > 0)) {
    sanitizeOverflow()
  }
})

const contentEl = document.getElementById('content')
if (contentEl) {
  // We need childList so we can get addedNodes, and we need
  // subtree so we can get mutations on all of the children
  observer.observe(contentEl, {childList: true, subtree: true})
}
const asideEl = document.getElementById('right-side')
if (asideEl) {
  observer.observe(asideEl, {childList: true, subtree: true})
}

ready(() => {
  sanitizeOverflow()
})
