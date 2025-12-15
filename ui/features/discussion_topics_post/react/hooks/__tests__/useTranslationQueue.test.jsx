/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {waitFor} from '@testing-library/react'
import {renderHook, act} from '@testing-library/react-hooks'
import {useTranslationQueue, MAX_CONCURRENT_TRANSLATIONS} from '../useTranslationQueue'

describe('useTranslationQueue', () => {
  const createMockJob = (label, doneList) => {
    let resolver
    const promise = new Promise(resolve => (resolver = resolve))
    const job = vi.fn(() => promise.finally(() => doneList.push(label)))
    job.resolve = resolver
    return job
  }

  it('runs only up to MAX_CONCURRENT_TRANSLATIONS', () => {
    window.ENV.ai_translation_improvements = true
    const {result} = renderHook(() => useTranslationQueue())

    const done = []
    const jobs = Array.from({length: MAX_CONCURRENT_TRANSLATIONS + 5}, (_, i) =>
      createMockJob(`job${i}`, done),
    )

    act(() => {
      jobs.forEach(job => result.current.enqueueTranslation(job))
    })

    for (let i = 0; i < MAX_CONCURRENT_TRANSLATIONS; i++) {
      expect(jobs[i]).toHaveBeenCalled()
    }

    for (let i = MAX_CONCURRENT_TRANSLATIONS; i < jobs.length; i++) {
      expect(jobs[i]).not.toHaveBeenCalled()
    }

    expect(result.current.getActiveCount()).toBe(MAX_CONCURRENT_TRANSLATIONS)
    expect(result.current.getQueueLength()).toBe(5)
  })

  it('starts next job from queue after one finishes', async () => {
    window.ENV.ai_translation_improvements = true
    const {result} = renderHook(() => useTranslationQueue())

    const done = []
    const jobs = Array.from({length: MAX_CONCURRENT_TRANSLATIONS + 2}, (_, i) =>
      createMockJob(`job${i}`, done),
    )

    act(() => {
      jobs.forEach(job => result.current.enqueueTranslation(job))
    })

    for (let i = 0; i < MAX_CONCURRENT_TRANSLATIONS; i++) {
      expect(jobs[i]).toHaveBeenCalled()
    }
    expect(jobs[MAX_CONCURRENT_TRANSLATIONS]).not.toHaveBeenCalled()
    expect(jobs[MAX_CONCURRENT_TRANSLATIONS + 1]).not.toHaveBeenCalled()

    act(() => {
      jobs[0].resolve()
    })

    await waitFor(() => {
      expect(jobs[MAX_CONCURRENT_TRANSLATIONS]).toHaveBeenCalled()
    })

    expect(result.current.getActiveCount()).toBe(MAX_CONCURRENT_TRANSLATIONS)
    expect(result.current.getQueueLength()).toBe(1)
  })

  it('runs all immediately when translation improvements flag is off', () => {
    window.ENV.ai_translation_improvements = false
    const {result} = renderHook(() => useTranslationQueue())

    const done = []
    const jobs = Array.from({length: 10}, (_, i) => createMockJob(`job${i}`, done))

    act(() => {
      jobs.forEach(job => result.current.enqueueTranslation(job))
    })

    for (const job of jobs) {
      expect(job).toHaveBeenCalled()
    }

    expect(result.current.getQueueLength()).toBe(0)
  })

  describe('clearQueue', () => {
    it('aborts all queued jobs', () => {
      window.ENV.ai_translation_improvements = true
      const {result} = renderHook(() => useTranslationQueue())

      const done = []
      const jobs = Array.from({length: MAX_CONCURRENT_TRANSLATIONS + 5}, (_, i) =>
        createMockJob(`job${i}`, done),
      )

      // Track abort signals
      const signals = []
      const jobsWithSignalTracking = jobs.map(job => signal => {
        signals.push(signal)
        return job(signal)
      })

      act(() => {
        jobsWithSignalTracking.forEach(job => result.current.enqueueTranslation(job))
      })

      // First MAX_CONCURRENT_TRANSLATIONS should be running
      expect(result.current.getActiveCount()).toBe(MAX_CONCURRENT_TRANSLATIONS)
      expect(result.current.getQueueLength()).toBe(5)

      // Clear the queue
      act(() => {
        result.current.clearQueue()
      })

      // All signals should be aborted
      signals.forEach(signal => {
        expect(signal.aborted).toBe(true)
      })

      expect(result.current.getActiveCount()).toBe(0)
      expect(result.current.getQueueLength()).toBe(0)
    })

    it('aborts active jobs', () => {
      window.ENV.ai_translation_improvements = true
      const {result} = renderHook(() => useTranslationQueue())

      const signals = []
      const job = signal => {
        signals.push(signal)
        return new Promise(() => {}) // Never resolves
      }

      act(() => {
        result.current.enqueueTranslation(job)
        result.current.enqueueTranslation(job)
      })

      expect(result.current.getActiveCount()).toBe(2)
      expect(signals).toHaveLength(2)
      expect(signals[0].aborted).toBe(false)
      expect(signals[1].aborted).toBe(false)

      // Clear the queue - should abort active jobs
      act(() => {
        result.current.clearQueue()
      })

      expect(signals[0].aborted).toBe(true)
      expect(signals[1].aborted).toBe(true)
      expect(result.current.getActiveCount()).toBe(0)
    })

    it('prevents aborted jobs from updating state', async () => {
      window.ENV.ai_translation_improvements = true
      const {result} = renderHook(() => useTranslationQueue())

      let capturedSignal = null
      const stateUpdates = []

      const job = async signal => {
        capturedSignal = signal
        // Simulate async work
        await new Promise(resolve => setTimeout(resolve, 10))

        // Check signal before updating state
        if (signal.aborted) {
          return
        }

        stateUpdates.push('updated')
      }

      act(() => {
        result.current.enqueueTranslation(job)
      })

      // Immediately clear before the job completes
      act(() => {
        result.current.clearQueue()
      })

      expect(capturedSignal.aborted).toBe(true)

      // Wait for the job's timeout to complete
      await waitFor(() => {
        // State should not be updated
        expect(stateUpdates).toHaveLength(0)
      })
    })

    it('clears both queued and active jobs together', () => {
      window.ENV.ai_translation_improvements = true
      const {result} = renderHook(() => useTranslationQueue())

      const signals = []
      const job = signal => {
        signals.push(signal)
        return new Promise(() => {}) // Never resolves
      }

      act(() => {
        // Enqueue more than MAX to have both active and queued
        for (let i = 0; i < MAX_CONCURRENT_TRANSLATIONS + 3; i++) {
          result.current.enqueueTranslation(job)
        }
      })

      expect(result.current.getActiveCount()).toBe(MAX_CONCURRENT_TRANSLATIONS)
      expect(result.current.getQueueLength()).toBe(3)
      expect(signals).toHaveLength(MAX_CONCURRENT_TRANSLATIONS) // Only active jobs get signals

      // Clear everything
      act(() => {
        result.current.clearQueue()
      })

      // All signals should be aborted
      signals.forEach(signal => {
        expect(signal.aborted).toBe(true)
      })

      expect(result.current.getActiveCount()).toBe(0)
      expect(result.current.getQueueLength()).toBe(0)
    })
  })
})
