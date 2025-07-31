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

import {useContext, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getTranslation} from '../utils'
import {DiscussionManagerUtilityContext} from '../utils/constants'

const I18n = createI18nScope('discussion_topics_post')

export default function useTranslateEntry(
  id,
  title,
  message,
  setTranslatedTitle,
  setTranslatedMessage,
  setTranslationError,
) {
  const {setEntryTranslating, translateTargetLanguage, enqueueTranslation} = useContext(
    DiscussionManagerUtilityContext,
  )

  useEffect(() => {
    if (translateTargetLanguage == null) {
      setTranslatedTitle(null)
      setTranslatedMessage(null)
      return
    }

    setTranslationError(null)
    setEntryTranslating(id, true)

    const translateJob = async () => {
      try {
        const [translatedTitle, translatedMessage] = await Promise.all([
          getTranslation(title, translateTargetLanguage),
          getTranslation(message, translateTargetLanguage),
        ])

        setTranslatedTitle(translatedTitle)
        setTranslatedMessage(translatedMessage)
      } catch (e) {
        setTranslatedTitle(null)
        setTranslatedMessage(null)

        if (e.translationError) {
          setTranslationError(e.translationError)
        } else {
          setTranslationError({
            type: 'newError',
            message: I18n.t('There was an unexpected error during translation.'),
          })
        }
      } finally {
        setEntryTranslating(id, false)
      }
    }

    enqueueTranslation(translateJob)
  }, [
    id,
    title,
    message,
    translateTargetLanguage,
    setTranslatedTitle,
    setTranslatedMessage,
    setTranslationError,
    setEntryTranslating,
    enqueueTranslation,
  ])
}
