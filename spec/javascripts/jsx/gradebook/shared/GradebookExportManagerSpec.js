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

import GradebookExportManager from 'ui/features/gradebook/react/shared/GradebookExportManager'

const currentUserId = 42
const exportingUrl = 'http://exportingUrl'
const monitoringBase = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
const attachmentBase = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
const workingExport = {
  progressId: 'progressId',
  attachmentId: 'attachmentId',
}

QUnit.module('GradebookExportManager - constructor', {
  setup() {
    moxios.install()
  },

  teardown() {
    moxios.uninstall()
  },
})

test('sets the polling interval with a sensible default', () => {
  const manager = new GradebookExportManager(exportingUrl, currentUserId, undefined, 5000)

  equal(manager.pollingInterval, 5000)

  const anotherManager = new GradebookExportManager(exportingUrl, currentUserId, workingExport)

  equal(anotherManager.pollingInterval, GradebookExportManager.DEFAULT_POLLING_INTERVAL)
})

test('sets the existing export if it is not already completed or failed', () => {
  ;['completed', 'failed'].forEach(workflowState => {
    const existingExport = {
      progressId: workingExport.progressId,
      attachmentId: workingExport.attachmentId,
      workflowState,
    }

    const manager = new GradebookExportManager(exportingUrl, currentUserId, existingExport)

    deepEqual(manager.export, undefined)
  })
  ;['discombobulated', undefined].forEach(workflowState => {
    const existingExport = {
      progressId: workingExport.progressId,
      attachmentId: workingExport.attachmentId,
      workflowState,
    }

    const manager = new GradebookExportManager(exportingUrl, currentUserId, existingExport)

    deepEqual(manager.export, existingExport)
  })
})

QUnit.module('GradebookExportManager - monitoringUrl', {
  setup() {
    moxios.install()

    this.subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
  },

  teardown() {
    moxios.uninstall()

    this.subject = undefined
  },
})

test('returns an appropriate url if all relevant pieces are present', function () {
  equal(this.subject.monitoringUrl(), `${monitoringBase}/progressId`)
})

test('returns undefined if export is missing', function () {
  this.subject.export = undefined

  equal(this.subject.monitoringUrl(), undefined)
})

test('returns undefined if progressId is missing', function () {
  this.subject.export.progressId = undefined

  equal(this.subject.monitoringUrl(), undefined)
})

QUnit.module('GradebookExportManager - attachmentUrl', {
  setup() {
    moxios.install()

    this.subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)
  },

  teardown() {
    moxios.uninstall()

    this.subject = undefined
  },
})

test('returns an appropriate url if all relevant pieces are present', function () {
  equal(this.subject.attachmentUrl(), `${attachmentBase}/attachmentId`)
})

test('returns undefined if export is missing', function () {
  this.subject.export = undefined

  equal(this.subject.attachmentUrl(), undefined)
})

test('returns undefined if attachmentId is missing', function () {
  this.subject.export.attachmentId = undefined

  equal(this.subject.attachmentUrl(), undefined)
})

QUnit.module('GradebookExportManager - startExport', {
  setup() {
    moxios.install()

    const expectedExportFromServer = {
      progress_id: 'newProgressId',
      attachment_id: 'newAttachmentId',
      filename: 'newfile',
    }

    // Initial request to start the export
    moxios.stubRequest(new RegExp(exportingUrl), {
      status: 200,
      responseText: expectedExportFromServer,
    })
  },

  teardown() {
    moxios.uninstall()

    this.subject.clearMonitor()
    this.subject = undefined
  },
})

test('sets show_student_first_last_name setting if requested', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.monitorExport = (resolve, _reject) => {
    resolve('success')
  }

  const getAssignmentOrder = () => []
  const getStudentOrder = () => []
  return this.subject.startExport(undefined, getAssignmentOrder, true, getStudentOrder).then(() => {
    const postData = JSON.parse(moxios.requests.mostRecent().config.data)
    propEqual(postData.show_student_first_last_name, true)
  })
})

test('does not set show_student_first_last_name setting by default', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.monitorExport = (resolve, _reject) => {
    resolve('success')
  }

  const getAssignmentOrder = () => []
  const getStudentOrder = () => []
  return this.subject
    .startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    .then(() => {
      const postData = JSON.parse(moxios.requests.mostRecent().config.data)
      propEqual(postData.show_student_first_last_name, false)
    })
})

test('includes assignment_order if getAssignmentOrder returns some assignments', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.monitorExport = (resolve, _reject) => {
    resolve('success')
  }

  const getAssignmentOrder = () => ['1', '2', '3']
  const getStudentOrder = () => []
  return this.subject
    .startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    .then(() => {
      const postData = JSON.parse(moxios.requests.mostRecent().config.data)
      propEqual(postData.assignment_order, ['1', '2', '3'])
    })
})

test('does not include assignment_order if getAssignmentOrder returns no assignments', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.monitorExport = (resolve, _reject) => {
    resolve('success')
  }

  const getAssignmentOrder = () => []
  const getStudentOrder = () => []
  return this.subject
    .startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    .then(() => {
      const postData = JSON.parse(moxios.requests.mostRecent().config.data)
      equal(postData.assignment_order, undefined)
    })
})

test('includes stringified student IDs if getStudentOrder returns some students', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.monitorExport = (resolve, _reject) => {
    resolve('success')
  }

  const getAssignmentOrder = () => []
  const getStudentOrder = () => ['4', '10610000001840127', '12']
  return this.subject
    .startExport(undefined, getAssignmentOrder, false, getStudentOrder)
    .then(() => {
      const postData = JSON.parse(moxios.requests.mostRecent().config.data)
      propEqual(postData.student_order, ['4', '10610000001840127', '12'])
    })
})

test('returns a rejected promise if the manager has no exportingUrl set', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.exportingUrl = undefined

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => []
    )
    .catch(reason => {
      equal(reason, 'No way to export gradebooks provided!')
    })
})

test('returns a rejected promise if the manager already has an export going', function () {
  this.subject = new GradebookExportManager(exportingUrl, currentUserId, workingExport)

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => []
    )
    .catch(reason => {
      equal(reason, 'An export is already in progress.')
    })
})

test('sets a new existing export and returns a fulfilled promise', function () {
  const expectedExport = {
    progressId: 'newProgressId',
    attachmentId: 'newAttachmentId',
    filename: 'newfile',
  }

  this.subject = new GradebookExportManager(exportingUrl, currentUserId)
  this.subject.monitorExport = (resolve, _reject) => {
    resolve('success')
  }

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => []
    )
    .then(() => {
      deepEqual(this.subject.export, expectedExport)
    })
})

test('clears any new export and returns a rejected promise if no monitoring is possible', function () {
  sandbox.stub(GradebookExportManager.prototype, 'monitoringUrl').returns(undefined)
  this.subject = new GradebookExportManager(exportingUrl, currentUserId)

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => []
    )
    .catch(reason => {
      equal(reason, 'No way to monitor gradebook exports provided!')
      equal(this.subject.export, undefined)
    })
})

test('starts polling for progress and returns a rejected promise on progress failure', function () {
  const expectedMonitoringUrl = `${monitoringBase}/newProgressId`

  this.subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

  moxios.stubRequest(expectedMonitoringUrl, {
    status: 200,
    responseText: {
      workflow_state: 'failed',
      message: 'Arbitrary failure',
    },
  })

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => []
    )
    .catch(reason => {
      equal(reason, 'Error exporting gradebook: Arbitrary failure')
    })
})

test('starts polling for progress and returns a rejected promise on unknown progress status', function () {
  const expectedMonitoringUrl = `${monitoringBase}/newProgressId`

  this.subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

  moxios.stubRequest(expectedMonitoringUrl, {
    status: 200,
    responseText: {
      workflow_state: 'discombobulated',
      message: 'Pattern buffer degradation',
    },
  })

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => []
    )
    .catch(reason => {
      equal(reason, 'Error exporting gradebook: Pattern buffer degradation')
    })
})

test('starts polling for progress and returns a fulfilled promise on progress completion', function () {
  const expectedMonitoringUrl = `${monitoringBase}/newProgressId`
  const expectedAttachmentUrl = `${attachmentBase}/newAttachmentId`

  this.subject = new GradebookExportManager(exportingUrl, currentUserId, null, 1)

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

  return this.subject
    .startExport(
      undefined,
      () => [],
      false,
      () => {}
    )
    .then(resolution => {
      equal(this.subject.export, undefined)

      const expectedResolution = {
        attachmentUrl: 'http://completedAttachmentUrl',
        updatedAt: '2009-01-20T17:00:00Z',
      }
      deepEqual(resolution, expectedResolution)
    })
})
