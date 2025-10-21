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

import {getTranslation} from '../utils'
import {useTranslationStore} from './useTranslationStore'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_topics_post')

type TranslationJobCb = (signal: AbortSignal) => Promise<void>

const useTranslationAll = (enqueueJobCallback: (jobCb: TranslationJobCb) => Promise<void>) => {
  const entries = useTranslationStore(state => state.entries)
  const setTranslationStart = useTranslationStore(state => state.setTranslationStart)
  const setTranslationEnd = useTranslationStore(state => state.setTranslationEnd)
  const setTranslateAll = useTranslationStore(state => state.setTranslateAll)
  const setTranslationError = useTranslationStore(state => state.setTranslationError)

  const translateAll = (language: string) => {
    setTranslateAll(true)

    Object.entries(entries).forEach(([id, entry]) => {
      const translationJob = async (signal: AbortSignal) => {
        try {
          // Check if already aborted before starting
          if (signal.aborted) {
            return
          }

          setTranslationStart(id)

          const [translatedTitle, translatedMessage] = await Promise.all([
            getTranslation(entry.title, language, signal),
            getTranslation(entry.message, language, signal),
          ])

          // Check multiple conditions before updating state
          // 1. Check if signal was aborted
          // 2. Check if translateAll is still active in the store
          // 3. Check if the language is still the same
          const currentState = useTranslationStore.getState()

          if (
            signal.aborted ||
            !currentState.translateAll ||
            currentState.activeLanguage !== language
          ) {
            return
          }

          setTranslationEnd(id, language, translatedMessage, translatedTitle)
        } catch (error: any) {
          // Don't update state if the request was aborted
          if (error.name === 'AbortError' || error.message?.includes('aborted')) {
            return
          }

          setTranslationEnd(id)
          if (error.translationError) {
            setTranslationError(id, error.translationError, language)
          } else {
            setTranslationError(
              id,
              {
                type: 'newError',
                message: I18n.t('There was an unexpected error during translation.'),
              },
              language,
            )
          }
        }
      }

      enqueueJobCallback(translationJob)
    })
  }

  return {translateAll}
}

export {useTranslationAll}
