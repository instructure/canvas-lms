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

  const actualMaxConcurrentTranslations = useMemo(() => {
    return ENV.ai_translation_improvements ? MAX_CONCURRENT_TRANSLATIONS : Number.POSITIVE_INFINITY
  }, [])

  const processTranslationQueue = useCallback(() => {
    while (
      activeTranslationCount.current < actualMaxConcurrentTranslations &&
      translationQueue.current.length > 0
    ) {
      const job = translationQueue.current.shift()
      activeTranslationCount.current++
      job().finally(() => {
        activeTranslationCount.current--
        processTranslationQueue()
      })
    }
  }, [actualMaxConcurrentTranslations])

  const enqueueTranslation = useCallback(
    jobFn => {
      translationQueue.current.push(jobFn)
      processTranslationQueue()
    },
    [processTranslationQueue],
  )

  return {
    enqueueTranslation,
    getActiveCount: () => activeTranslationCount.current,
    getQueueLength: () => translationQueue.current.length,
  }
}
