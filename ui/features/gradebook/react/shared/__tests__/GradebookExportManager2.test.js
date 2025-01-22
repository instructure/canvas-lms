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

import moxios from 'moxios'
import GradebookExportManager from '../GradebookExportManager'

const currentUserId = 42
const exportingUrl = 'http://exportingUrl'
const monitoringBase = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
const attachmentBase = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
const workingExport = {
  progressId: 'progressId',
  attachmentId: 'attachmentId',
  workflowState: 'queued',
}

describe('GradebookExportManager - constructor', () => {
  beforeEach(() => {
    moxios.install()
  })

  afterEach(() => {
    moxios.uninstall()
  })

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
    moxios.install()
    subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
    subject.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    subject.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
  })

  afterEach(() => {
    moxios.uninstall()
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
    moxios.install()
    subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
    subject.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    subject.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
  })

  afterEach(() => {
    moxios.uninstall()
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
    moxios.install()
    subject = new GradebookExportManager(exportingUrl, currentUserId)

    // Initial request to start the export
    moxios.stubRequest(new RegExp(exportingUrl), {
      status: 200,
      responseText: {
        progress_id: 'newProgressId',
        attachment_id: 'newAttachmentId',
        filename: 'newfile',
      },
    })
  })

  afterEach(() => {
    moxios.uninstall()
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
    const expectedMonitoringUrl = `${monitoringBase}/newProgressId`
    subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

    // First stub the export request
    moxios.stubRequest(exportingUrl, {
      status: 200,
      response: {
        progress_id: 'newProgressId',
        attachment_id: 'attachmentId',
        filename: 'filename.csv',
      },
    })

    // Then stub the monitoring request
    moxios.stubRequest(expectedMonitoringUrl, {
      status: 200,
      response: {
        workflow_state: 'failed',
        message: 'Arbitrary failure',
      },
    })

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
    const expectedMonitoringUrl = `${monitoringBase}/newProgressId`
    subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

    moxios.stubRequest(exportingUrl, {
      status: 200,
      response: {
        attachmentId: 'attachmentId',
        progressId: 'newProgressId',
      },
    })

    moxios.stubRequest(expectedMonitoringUrl, {
      status: 200,
      response: {
        workflow_state: 'unknown',
        message: 'Unknown workflow state',
      },
    })

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
    const expectedMonitoringUrl = `${monitoringBase}/newProgressId`
    const expectedAttachmentUrl = `${attachmentBase}/newAttachmentId`

    subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

    moxios.stubRequest(expectedMonitoringUrl, {
      status: 200,
      responseText: {
        workflow_state: 'completed',
      },
    })

    moxios.stubRequest(expectedAttachmentUrl, {
      status: 200,
      responseText: {
        url: 'http://completedAttachmentUrl',
        updated_at: '2009-01-20T17:00:00Z',
      },
    })

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
