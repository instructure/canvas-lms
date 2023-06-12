// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import GradebookApi from '../../default_gradebook/apis/GradebookApi'
import ScoreToUngradedManager from '../ScoreToUngradedManager'
import '@testing-library/jest-dom/extend-expect'
import axios from '@canvas/axios'

const monitoringBase = ScoreToUngradedManager.DEFAULT_MONITORING_BASE_URL
const workingProcess = {
  progressId: '1',
  workflowState: 'running',
}

describe('ScoreToUngradedManager', () => {
  describe('constructor', () => {
    it('sets the polling interval with a sensible default', () => {
      const manager = new ScoreToUngradedManager(undefined, 5000)
      expect(manager.pollingInterval).toStrictEqual(5000)

      const anotherManager = new ScoreToUngradedManager(workingProcess)
      expect(anotherManager.pollingInterval).toStrictEqual(
        ScoreToUngradedManager.DEFAULT_POLLING_INTERVAL
      )
    })

    it('sets the existing process if it is not already completed or failed', () => {
      ;['completed', 'failed'].forEach(workflowState => {
        const existingProcess = {
          progressId: workingProcess.progressId,
          workflowState,
        }

        const manager = new ScoreToUngradedManager(existingProcess)
        expect(manager.process).toEqual(undefined)
      })
      ;['discombobulated', undefined].forEach(workflowState => {
        const existingProcess = {
          progressId: workingProcess.progressId,
          workflowState,
        }

        const manager = new ScoreToUngradedManager(existingProcess)
        expect(manager.process).toEqual(existingProcess)
      })
    })
  })

  describe('monitoringUrl', () => {
    let manager
    beforeEach(() => {
      manager = new ScoreToUngradedManager(workingProcess)
    })

    afterEach(() => {
      manager.clearMonitor()
      manager = undefined
    })

    it('returns an appropriate url if all relevant pieces are present', () => {
      expect(manager.monitoringUrl()).toStrictEqual(`${monitoringBase}/1`)
    })

    it('returns undefined if process is missing', () => {
      manager.process = undefined
      expect(manager.monitoringUrl()).toEqual(undefined)
    })

    it('returns undefined if progressId is missing', () => {
      manager.process.progressId = undefined
      expect(manager.monitoringUrl()).toEqual(undefined)
    })
  })

  describe('startProcess', () => {
    let spy
    beforeEach(() => {
      spy = jest
        .spyOn(GradebookApi, 'applyScoreToUngradedSubmissions')
        // @ts-expect-error
        .mockResolvedValue({data: {id: 1, workflow_state: 'running'}})
    })

    afterEach(() => {
      spy.mockRestore()
    })

    it('returns a rejected promise if the manager already has a process going', async () => {
      const manager = new ScoreToUngradedManager(workingProcess)
      try {
        await manager.startProcess(undefined, () => [])
      } catch (reason) {
        expect(reason).toStrictEqual('A process is already in progress.')
      }
    })

    it('sets a new existing progress and returns a fulfilled promise', async () => {
      const expectedProgress = {
        progressId: 1,
        workflowState: 'running',
      }

      const manager = new ScoreToUngradedManager()
      manager.monitorProcess = (resolve, _reject) => {
        resolve('success')
      }

      await manager.startProcess(undefined, () => [])
      expect(manager.process).toStrictEqual(expectedProgress)
    })

    it('clears any new process and returns a rejected promise if no monitoring is possible', async () => {
      jest
        .spyOn(ScoreToUngradedManager.prototype as any, 'monitoringUrl')
        .mockReturnValue(undefined)
      const manager = new ScoreToUngradedManager()

      try {
        await manager.startProcess(undefined, () => [])
      } catch (reason) {
        expect(reason).toStrictEqual(
          'Score to ungraded process failed: No way to monitor score to ungraded provided!'
        )
      }
    })

    it('starts polling for progress and returns a rejected promise on progress failure', async () => {
      const manager = new ScoreToUngradedManager(undefined, 1)

      jest.spyOn(axios, 'get').mockResolvedValue({
        data: {
          workflow_state: 'failed',
          message: 'Arbitrary failure',
        },
      })

      try {
        await manager.startProcess(undefined, () => [])
      } catch (reason) {
        expect(reason).toStrictEqual('Score to ungraded process failed: Arbitrary failure')
      }
    })

    it('starts polling for progress and returns a rejected promise on unknown progress status', async () => {
      const manager = new ScoreToUngradedManager(undefined, 1)

      jest.spyOn(axios, 'get').mockResolvedValue({
        data: {
          workflow_state: 'discombobulated',
          message: 'Pattern buffer degradation',
        },
      })

      try {
        await manager.startProcess(undefined, () => [])
      } catch (reason) {
        expect(reason).toStrictEqual('Score to ungraded process failed: Pattern buffer degradation')
      }
    })

    it('starts polling for progress and returns a fulfilled promise on progress completion', async () => {
      const manager = new ScoreToUngradedManager(undefined, 1)

      jest.spyOn(axios, 'get').mockResolvedValue({
        data: {
          workflow_state: 'completed',
        },
      })

      await manager.startProcess(undefined, () => [])
      expect(manager.process).toStrictEqual(undefined)
    })
  })
})
