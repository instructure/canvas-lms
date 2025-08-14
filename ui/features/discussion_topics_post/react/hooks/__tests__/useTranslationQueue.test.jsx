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
    const job = jest.fn(() => promise.finally(() => doneList.push(label)))
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
})
