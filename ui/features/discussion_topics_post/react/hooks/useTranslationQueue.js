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

import {useRef, useCallback, useMemo} from 'react'

export const MAX_CONCURRENT_TRANSLATIONS = 10

export function useTranslationQueue() {
  const activeTranslationCount = useRef(0)
  const translationQueue = useRef([])
  const activeAbortControllers = useRef(new Set())

  const actualMaxConcurrentTranslations = useMemo(() => {
    return ENV.ai_translation_improvements ? MAX_CONCURRENT_TRANSLATIONS : Number.POSITIVE_INFINITY
  }, [])

  const processTranslationQueue = useCallback(() => {
    while (
      activeTranslationCount.current < actualMaxConcurrentTranslations &&
      translationQueue.current.length > 0
    ) {
      const {jobFn, abortController} = translationQueue.current.shift()
      activeTranslationCount.current++
      activeAbortControllers.current.add(abortController)

      jobFn(abortController.signal)
        .catch(() => {
          // Ignore errors from aborted requests
        })
        .finally(() => {
          activeTranslationCount.current--
          activeAbortControllers.current.delete(abortController)
          processTranslationQueue()
        })
    }
  }, [actualMaxConcurrentTranslations])

  const enqueueTranslation = useCallback(
    jobFn => {
      const abortController = new AbortController()
      translationQueue.current.push({jobFn, abortController})
      processTranslationQueue()
    },
    [processTranslationQueue],
  )

  const clearQueue = useCallback(() => {
    // Clear the queue
    translationQueue.current.forEach(({abortController}) => {
      abortController.abort()
    })
    translationQueue.current = []

    // Abort all active requests
    activeAbortControllers.current.forEach(abortController => {
      abortController.abort()
    })
    activeAbortControllers.current.clear()

    // Reset active count
    activeTranslationCount.current = 0
  }, [])

  return {
    enqueueTranslation,
    clearQueue,
    getActiveCount: () => activeTranslationCount.current,
    getQueueLength: () => translationQueue.current.length,
  }
}
