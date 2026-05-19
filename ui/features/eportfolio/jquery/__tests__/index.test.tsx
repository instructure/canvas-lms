/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {renderPortal} from '../index'

describe('renderPortal', () => {
  let sectionMount: HTMLElement
  let pageMount: HTMLElement

  beforeEach(() => {
    sectionMount = document.createElement('div')
    sectionMount.id = 'section_list_mount'
    pageMount = document.createElement('div')
    pageMount.id = 'page_list_mount'
    document.body.appendChild(sectionMount)
    document.body.appendChild(pageMount)
  })

  afterEach(() => {
    sectionMount.remove()
    pageMount.remove()
    document.getElementById('recent_submission_mount')?.remove()
  })

  it('returns JSX when section and page mounts exist but submission mount is absent', () => {
    // recent_submission_mount is NOT in the DOM (simulates @owner_view = false)
    expect(document.getElementById('recent_submission_mount')).toBeNull()

    const result = renderPortal(1)

    expect(result).not.toBeUndefined()
  })

  it('returns JSX when all three mounts are present', () => {
    const submissionMount = document.createElement('div')
    submissionMount.id = 'recent_submission_mount'
    document.body.appendChild(submissionMount)

    const result = renderPortal(1)

    expect(result).not.toBeUndefined()
  })
})
