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
    subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
    subject.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    subject.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
  })

  afterEach(() => {
    subject = undefined
  })

  // fickle with --randomize
  test.skip('returns an appropriate url if all relevant pieces are present', () => {
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
    subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
    subject.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    subject.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
  })

  afterEach(() => {
    subject = undefined
  })

  // fickle with --randomize
  test.skip('returns an appropriate url if all relevant pieces are present', () => {
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

    // Initial request to start the export
    server.use(
      http.post('*', () =>
        HttpResponse.json({
          progress_id: 'newProgressId',
          attachment_id: 'newAttachmentId',
          filename: 'newfile',
        }),
      ),
      // Default progress monitoring handler
      http.get('*/api/v1/progress/*', () =>
        HttpResponse.json({
          workflow_state: 'completed',
          completion: 100,
          message: 'Done',
        }),
      ),
      // Default attachment handler
      http.get('*/api/v1/users/*/files/*', () =>
        HttpResponse.json({
          url: 'http://completedAttachmentUrl',
          updated_at: '2009-01-20T17:00:00Z',
        }),
      ),
    )
  })

  afterEach(() => {
    subject.clearMonitor()
    subject = undefined
  })

  test('sets a new existing export and returns a fulfilled promise', async () => {
    const expectedExport = {
      progressId: 'newProgressId',
      attachmentId: 'newAttachmentId',
      filename: 'newfile',
    }

    subject.monitorExport = (resolve, _reject) => resolve('success')

    await subject.startExport(
      undefined,
      () => [],
      false,
      () => [],
    )
    expect(subject.export).toEqual(expectedExport)
  })

  test('clears any new export and returns a rejected promise if no monitoring is possible', async () => {
    jest.spyOn(GradebookExportManager.prototype, 'monitoringUrl').mockReturnValue(undefined)

    await expect(
      subject.startExport(
        undefined,
        () => [],
        false,
        () => [],
      ),
    ).rejects.toEqual('No way to monitor gradebook exports provided!')

    expect(subject.export).toBeUndefined()
  })

  test('starts polling for progress and returns a rejected promise on progress failure', async () => {
    subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

    // Override the progress endpoint to return failed
    server.use(
      http.get('*/api/v1/progress/*', () =>
        HttpResponse.json({
          workflow_state: 'failed',
          message: 'Arbitrary failure',
        }),
      ),
    )

    try {
      await subject.startExport(
        undefined,
        () => [],
        false,
        () => [],
      )
      expect(false).toBe(true)
    } catch (error) {
      expect(error).toBe('Error exporting gradebook: Arbitrary failure')
    }
  })

  test('starts polling for progress and returns a rejected promise on unknown progress status', async () => {
    subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

    server.use(
      http.get('*/api/v1/progress/*', () =>
        HttpResponse.json({
          workflow_state: 'unknown',
          message: 'Unknown workflow state',
        }),
      ),
    )

    await expect(
      subject.startExport(
        undefined,
        () => [],
        false,
        () => [],
      ),
    ).rejects.toMatch(/Error exporting gradebook: Unknown workflow state/)
  })

  test('starts polling for progress and returns a fulfilled promise on progress completion', async () => {
    const expectedAttachmentUrl = `${attachmentBase}/newAttachmentId`

    subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

    // Default handler already returns completed status
    server.use(
      http.get(expectedAttachmentUrl, () =>
        HttpResponse.json({
          workflow_state: 'completed',
        }),
      ),
    )

    server.use(
      http.get(expectedAttachmentUrl, () =>
        HttpResponse.json({
          url: 'http://completedAttachmentUrl',
          updated_at: '2009-01-20T17:00:00Z',
        }),
      ),
    )

    const resolution = await subject.startExport(
      undefined,
      () => [],
      false,
      () => {},
    )

    expect(subject.export).toBeUndefined()

    const expectedResolution = {
      attachmentUrl: 'http://completedAttachmentUrl',
      updatedAt: '2009-01-20T17:00:00Z',
    }
    expect(resolution).toEqual(expectedResolution)
  })
})
