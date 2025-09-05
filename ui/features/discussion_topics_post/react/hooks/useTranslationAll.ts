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

type TranslationJobCb = (
  entryId: string,
  title: string | null,
  message: string | null,
  language: string,
) => Promise<void>

const useTranslationAll = (enqueueJobCallback: (jobCb: TranslationJobCb) => Promise<void>) => {
  const entries = useTranslationStore(state => state.entries)
  const setTranslationStart = useTranslationStore(state => state.setTranslationStart)
  const setTranslationEnd = useTranslationStore(state => state.setTranslationEnd)
  const setTranslateAll = useTranslationStore(state => state.setTranslateAll)
  const setTranslationError = useTranslationStore(state => state.setTranslationError)

  const translateAll = (language: string) => {
    setTranslateAll(true)

    Object.entries(entries).forEach(([id, entry]) => {
      const translationJob = async () => {
        try {
          setTranslationStart(id)

          const [translatedTitle, translatedMessage] = await Promise.all([
            getTranslation(entry.title, language),
            getTranslation(entry.message, language),
          ])

          setTranslationEnd(id, language, translatedMessage, translatedTitle)
        } catch (error: any) {
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
