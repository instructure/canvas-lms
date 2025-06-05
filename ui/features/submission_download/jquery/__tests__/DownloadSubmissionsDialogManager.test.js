/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import DownloadSubmissionsDialogManager from '@canvas/grading/DownloadSubmissionsDialogManager'
import '../index'

if (!('INST' in window)) window.INST = {}

describe('DownloadSubmissionsDialogManager#constructor', () => {
  it('constructs download url from given assignment data and url template', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        id: 'the_id',
      },
      'the_{{ assignment_id }}_url',
    )

    expect(manager.downloadUrl).toBe('the_the_id_url')
  })
})

describe('DownloadSubmissionsDialogManager#isDialogEnabled', () => {
  it('returns true when submission type includes online_upload and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_upload'],
        has_submitted_submissions: true,
      },
      'the_url',
    )
    expect(manager.isDialogEnabled()).toBe(true)
  })

  it('returns true when submission type includes online_text_entry and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_text_entry'],
        has_submitted_submissions: true,
      },
      'the_url',
    )
    expect(manager.isDialogEnabled()).toBe(true)
  })

  it('returns true when submission type includes online_url and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_url'],
        has_submitted_submissions: true,
      },
      'the_url',
    )
    expect(manager.isDialogEnabled()).toBe(true)
  })

  it('returns false when submission type does not include a valid submission type and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['foo'],
        has_submitted_submissions: true,
      },
      'the_url',
    )
    expect(manager.isDialogEnabled()).toBe(false)
  })

  it('returns false when submission type includes a valid submission type and there is not a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_url'],
        has_submitted_submissions: false,
      },
      '/foo/bar',
    )
    expect(manager.isDialogEnabled()).toBe(false)
  })
})

describe('DownloadSubmissionsDialogManager#showDialog', () => {
  beforeEach(() => {
    INST.downloadSubmissions = jest.fn()
  })

  afterEach(() => {
    delete INST.downloadSubmissions
  })

  it('calls submissions downloading callback and opens downloadSubmissions dialog', () => {
    const submissionsDownloading = jest.fn()
    const manager = new DownloadSubmissionsDialogManager(
      {
        id: 'the_id',
        submission_types: ['online_upload'],
        has_submitted_submissions: true,
      },
      'the_{{ assignment_id }}_url',
      submissionsDownloading,
    )
    manager.showDialog()

    expect(submissionsDownloading).toHaveBeenCalledWith('the_id')
    expect(INST.downloadSubmissions).toHaveBeenCalledWith('the_the_id_url', undefined)
  })
})
