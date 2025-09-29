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

import {useRef, useCallback} from 'react'
import {useTranslationStore} from './useTranslationStore'
import {useTranslationQueue} from './useTranslationQueue'
import {useTranslation} from './useTranslation'

export const useObservedTranslations = () => {
  const setTranslationStart = useTranslationStore(state => state.setTranslationStart)

  const {enqueueTranslation} = useTranslationQueue()
  const {translateEntry} = useTranslation()

  const observerRef = useRef<IntersectionObserver>()
  const nodesRef = useRef(new Map<string, Element>())
  const timeoutRef = useRef(new Map<string, NodeJS.Timeout>())

  const startObserving = useCallback(
    (language: string) => {
      observerRef.current = new IntersectionObserver(
        observedEntries => {
          observedEntries.forEach(observedEntry => {
            if (observedEntry.isIntersecting) {
              const entryId = (observedEntry.target as HTMLElement).dataset.id

              if (entryId) {
                const entry = useTranslationStore.getState().entries[entryId]
                const activeLanguage = useTranslationStore.getState().activeLanguage
                if (entry && entry.language !== activeLanguage && !entry.loading) {
                  const timeoutId = setTimeout(() => {
                    setTranslationStart(entryId)
                    const translateJob = async () => {
                      await translateEntry({
                        language,
                        entryId,
                        message: entry.message,
                        title: entry.title,
                      })
                    }
                    enqueueTranslation(translateJob)
                  }, 200)

                  timeoutRef.current.set(entryId, timeoutId)
                }
              }
            } else {
              const entryId = (observedEntry.target as HTMLElement).dataset.id

              if (!entryId) {
                return
              }

              const timeoutId = timeoutRef.current.get(entryId)

              if (timeoutId) {
                clearTimeout(timeoutId)
                timeoutRef.current.delete(entryId)
              }
            }
          })
        },
        {threshold: 0.1},
      )

      nodesRef.current.forEach(node => {
        observerRef.current?.observe(node)
      })
    },
    [enqueueTranslation, setTranslationStart, translateEntry],
  )

  const stopObserving = useCallback(() => {
    if (observerRef.current) {
      observerRef.current.disconnect()
      observerRef.current = undefined
    }
  }, [observerRef])

  return {startObserving, stopObserving, observerRef, nodesRef}
}
