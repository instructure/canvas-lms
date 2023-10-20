/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

// Helper function (by Martin Yosifov) to detect what
// type the description is (html, html-text, text)
const descriptionType = description => {
  if (!description) return 'null'
  const doc = new DOMParser().parseFromString(description, 'text/html')
  const pTags = doc.getElementsByTagName('p').length
  const divTags = doc.getElementsByTagName('div').length
  const diff = description.length - doc.body.textContent.length
  if (diff === 0) return 'text'
  if ((pTags === 1 && diff === 7) || (divTags === 1 && diff === 11)) return 'html_text'
  return 'html'
}

export default descriptionType
