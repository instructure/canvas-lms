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

import {useMutation, useQuery} from '@apollo/client'
import {GET_PREFERRED_LANGUAGE} from '../../graphql/Queries'
import {useMemo, useCallback} from 'react'
import {UPDATE_DISCUSSION_TOPIC_PARTICIPANT} from '../../graphql/Mutations'
import {useTranslationStore} from './useTranslationStore'
import {getTranslation} from '../utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'

const I18n = createI18nScope('discussion_topics_post')

declare const ENV: GlobalEnv & {
  discussion_translation_languages: Record<string, string>[]
}

const matchLanguage = (languageId: string, languageEnum: string[]) =>
  languageEnum.find(lang => lang.toLowerCase().replace('_', '-') === languageId.toLowerCase())

const convertLangugeFromEnum = (language: string | null) =>
  language ? language.toLowerCase().replace('_', '-') : ''

const translationLangaugesFromENV = ENV?.discussion_translation_languages || []

const useTranslation = () => {
  const discussionTopicId = useTranslationStore(state => state.discussionTopicId)
  const setModalOpen = useTranslationStore(state => state.setModalOpen)
  const setTranslateContent = useTranslationStore(state => state.setTranslateContent)
  const setTranslationStart = useTranslationStore(state => state.setTranslationStart)
  const setTranslationEnd = useTranslationStore(state => state.setTranslationEnd)
  const setTranslationError = useTranslationStore(state => state.setTranslationError)

  const isActiveLanguageSet = useTranslationStore(state => state.isActiveLanguageSet)
  const setActiveLanguage = useTranslationStore(state => state.setActiveLanguage)

  const {data, loading} = useQuery(GET_PREFERRED_LANGUAGE, {
    variables: {discussionTopicId},
    skip: !discussionTopicId,
    onCompleted: data => {
      if (!data?.legacyNode?.participant?.preferredLanguage) {
        return
      }

      const preferredLanguage = convertLangugeFromEnum(
        data.legacyNode.participant.preferredLanguage,
      )

      if (preferredLanguage && !isActiveLanguageSet) {
        setActiveLanguage(preferredLanguage)
      }
    },
  })

  const [update, {loading: updateLoading}] = useMutation(UPDATE_DISCUSSION_TOPIC_PARTICIPANT)

  const preferredLanguagesEnum = useMemo(() => {
    if (loading || !data?.__type?.enumValues) {
      return []
    }

    return data?.__type?.enumValues.map(({name}: {name: string}) => name)
  }, [data, loading])

  // The raw preferred language is in the form of "EN_US", we need to convert it to "en-US"
  const preferredLanguage = useMemo(() => {
    if (loading || !data?.legacyNode?.participant) {
      return null
    }

    const language = data.legacyNode.participant.preferredLanguage

    return (
      translationLangaugesFromENV.find(
        lang => lang.id.toLowerCase() === convertLangugeFromEnum(language),
      )?.id || null
    )
  }, [data, loading])

  const savePreferredLanguage = useCallback(
    async (languageId: string, discussionTopicId: string) => {
      const preferredLanguage = matchLanguage(languageId, preferredLanguagesEnum)

      if (!preferredLanguage) {
        // TODO: Handle error
        return
      }

      await update({
        variables: {
          discussionTopicId,
          preferredLanguage,
        },
      })
    },
    [preferredLanguagesEnum, update],
  )

  /*
   * Translate the currently active entry from the store
   * It will return early if preferred language or entryId is not set
   */
  const getTranslations = useCallback(
    async ({
      language,
      entryId,
      message,
      title,
    }: {
      language: string
      entryId: string
      message?: string | null
      title?: string | null
    }) => {
      if (!language || !entryId) {
        return null
      }

      return await Promise.all([getTranslation(title, language), getTranslation(message, language)])
    },
    [],
  )

  const translateEntry = useCallback(
    async ({
      language,
      entryId,
      message,
      title,
    }: {
      language: string
      entryId: string
      message?: string | null
      title?: string | null
    }) => {
      try {
        setTranslationStart(entryId)
        const [translatedTitle, translatedMessage] = await getTranslations({
          language,
          entryId,
          message,
          title,
        })

        setTranslationEnd(entryId, language, translatedMessage, translatedTitle)
      } catch (error: any) {
        // TODO: Fix any type
        setTranslationEnd(entryId)
        if (error.translationError) {
          setTranslationError(entryId, error.translationError, language)
        } else {
          setTranslationError(
            entryId,
            {
              type: 'newError',
              message: I18n.t('There was an unexpected error during translation.'),
            },
            language,
          )
        }
      }
    },
    [setTranslationEnd, setTranslationError, setTranslationStart, getTranslations],
  )

  /*
   * Try to translate if we are not sure if the preferred language is set
   */
  const tryTranslate = useCallback(
    async (entryId: string, message: string, title?: string) => {
      if (useTranslationStore.getState().entries[entryId]?.loading) {
        return
      }

      if (!preferredLanguage) {
        setModalOpen(entryId, message, title)
        return
      }

      setTranslateContent(entryId, message)

      translateEntry({language: preferredLanguage, entryId, message, title})
    },
    [preferredLanguage, setModalOpen, setTranslateContent, translateEntry],
  )

  /*
   * Force translate the currently active entry from the store
   * It will return early if preferred language or entryId is not set
   * This is used when user changes the preferred language from the modal
   */
  const forceTranslate = useCallback(
    async (language?: string) => {
      const {translationEntryId, translationMessage, translationTitle} =
        useTranslationStore.getState()

      // For typescript typequard
      const lang = language || preferredLanguage

      if (!lang || !translationEntryId) {
        return
      }

      translateEntry({
        language: lang,
        entryId: translationEntryId,
        message: translationMessage,
        title: translationTitle,
      })
    },
    [preferredLanguage, translateEntry],
  )

  return {
    preferredLanguage,
    preferredLanguagesEnum,
    savePreferredLanguage,
    updateLoading,
    tryTranslate,
    forceTranslate,
    translateEntry,
  }
}

export {useTranslation}
