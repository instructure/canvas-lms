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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import GradebookExportManager from '../GradebookExportManager'

const currentUserId = 42
const exportingUrl = '/api/v1/gradebook_exports'
const monitoringBase = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
const attachmentBase = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
const workingExport = {
  progressId: 'progressId',
  attachmentId: 'attachmentId',
  workflowState: 'queued',
}

const server = setupServer()

beforeAll(() => server.listen())

afterEach(() => server.resetHandlers())

afterAll(() => server.close())

describe('GradebookExportManager - constructor', () => {
  test('sets the polling interval with a sensible default', () => {
    const manager = new GradebookExportManager(exportingUrl, currentUserId, undefined, 5000)
    expect(manager.pollingInterval).toBe(5000)

    const anotherManager = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
    expect(anotherManager.pollingInterval).toBe(GradebookExportManager.DEFAULT_POLLING_INTERVAL)
  })

  test('sets the existing export if it is not already completed or failed', () => {
    ;['completed', 'failed'].forEach(workflowState => {
      const existingExport = {
        progressId: workingExport.progressId,
        attachmentId: workingExport.attachmentId,
        workflowState,
      }

      const manager = new GradebookExportManager(exportingUrl, currentUserId, existingExport)
      expect(manager.export).toBeUndefined()
    })
    ;['discombobulated', undefined, 'queued'].forEach(workflowState => {
      const existingExport = {
        progressId: workingExport.progressId,
        attachmentId: workingExport.attachmentId,
        workflowState,
      }

      const manager = new GradebookExportManager(exportingUrl, currentUserId, existingExport)
      expect(manager.export).toEqual(existingExport)
    })
  })
})

describe('GradebookExportManager - monitoringUrl', () => {
  let subject

  beforeEach(() => {
    subject = new GradebookExportManager(exportingUrl, currentUserId, {...workingExport})
    subject.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    subject.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
  })

  afterEach(() => {
    subject = undefined
  })

  test('returns an appropriate url if all relevant pieces are present', () => {
    expect(subject.monitoringUrl()).toBe(`${monitoringBase}/progressId`)
  })

  test('returns undefined if export is missing', () => {
    subject.export = undefined
    expect(subject.monitoringUrl()).toBeUndefined()
  })

  test('returns undefined if progressId is missing', () => {
    subject.export.progressId = undefined
    expect(subject.monitoringUrl()).toBeUndefined()
  })
})

describe('GradebookExportManager - attachmentUrl', () => {
  let subject

  beforeEach(() => {
    subject = new GradebookExportManager(exportingUrl, currentUserId, {...workingExport})
    subject.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    subject.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
  })

  afterEach(() => {
    subject = undefined
  })

  test('returns an appropriate url if all relevant pieces are present', () => {
    expect(subject.attachmentUrl()).toBe(`${attachmentBase}/attachmentId`)
  })

  test('returns undefined if export is missing', () => {
    subject.export = undefined
    expect(subject.attachmentUrl()).toBeUndefined()
  })

  test('returns undefined if attachmentId is missing', () => {
    subject.export.attachmentId = undefined
    expect(subject.attachmentUrl()).toBeUndefined()
  })
})

describe('GradebookExportManager - startExport', () => {
  let subject

  beforeEach(() => {
    subject = new GradebookExportManager(exportingUrl, currentUserId)
  })

  afterEach(() => {
    subject.clearMonitor()
    subject = undefined
  })

  test('sets show_student_first_last_name setting if requested', async () => {
    let capturedRequest
    server.use(
      http.post('*', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({
          progress_id: 'newProgressId',
          attachment_id: 'newAttachmentId',
          filename: 'newfile',
        })
      }),
    )

    subject.monitorExport = (resolve, _reject) => resolve('success')

    const getAssignmentOrder = () => []
    const getStudentOrder = () => []
    await subject.startExport(undefined, getAssignmentOrder, true, getStudentOrder)
    expect(capturedRequest.show_student_first_last_name).toBe(true)
  })

  test('does not set show_student_first_last_name setting by default', async () => {
    let capturedRequest
    server.use(
      http.post('*', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({
          progress_id: 'newProgressId',
          attachment_id: 'newAttachmentId',
          filename: 'newfile',
        })
      }),
    )

    subject.monitorExport = (resolve, _reject) => resolve('success')

    const getAssignmentOrder = () => []
    const getStudentOrder = () => []
    await subject.startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    expect(capturedRequest.show_student_first_last_name).toBe(false)
  })

  test('includes assignment_order if getAssignmentOrder returns some assignments', async () => {
    let capturedRequest
    server.use(
      http.post('*', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({
          progress_id: 'newProgressId',
          attachment_id: 'newAttachmentId',
          filename: 'newfile',
        })
      }),
    )

    subject.monitorExport = (resolve, _reject) => resolve('success')

    const getAssignmentOrder = () => ['1', '2', '3']
    const getStudentOrder = () => []
    await subject.startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    expect(capturedRequest.assignment_order).toEqual(['1', '2', '3'])
  })

  test('does not include assignment_order if getAssignmentOrder returns no assignments', async () => {
    let capturedRequest
    server.use(
      http.post('*', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({
          progress_id: 'newProgressId',
          attachment_id: 'newAttachmentId',
          filename: 'newfile',
        })
      }),
    )

    subject.monitorExport = (resolve, _reject) => resolve('success')

    const getAssignmentOrder = () => []
    const getStudentOrder = () => []
    await subject.startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    expect(capturedRequest.assignment_order).toBeUndefined()
  })

  test('includes stringified student IDs if getStudentOrder returns some students', async () => {
    let capturedRequest
    server.use(
      http.post('*', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({
          progress_id: 'newProgressId',
          attachment_id: 'newAttachmentId',
          filename: 'newfile',
        })
      }),
    )

    subject.monitorExport = (resolve, _reject) => resolve('success')

    const getAssignmentOrder = () => []
    const getStudentOrder = () => ['4', '10610000001840127', '12']
    await subject.startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    expect(capturedRequest.student_order).toEqual(['4', '10610000001840127', '12'])
  })

  test('returns a rejected promise if the manager has no exportingUrl set', async () => {
    subject.exportingUrl = undefined

    try {
      await subject.startExport(
        undefined,
        () => [],
        false,
        () => [],
      )
      expect(false).toBe(true) // Should not reach this line
    } catch (error) {
      expect(error).toBe('No way to export gradebooks provided!')
    }
  })

  test('returns a rejected promise if the manager already has an export going', async () => {
    subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)

    try {
      await subject.startExport(
        undefined,
        () => [],
        false,
        () => [],
      )
      expect(false).toBe(true) // Should not reach this line
    } catch (error) {
      expect(error).toBe('An export is already in progress.')
    }
  })
})
