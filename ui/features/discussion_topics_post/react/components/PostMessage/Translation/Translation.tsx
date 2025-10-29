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

import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconAiLine, IconWarningSolid, IconRefreshLine} from '@instructure/ui-icons'
import {createContext, PropsWithChildren, useContext, useEffect} from 'react'
import {DiscussionManagerUtilityContext} from '../../../utils/constants'
import {useTranslationStore} from '../../../hooks/useTranslationStore'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getTranslation} from '../../../utils'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('discussion_topics_post')

interface TranslationContextType {
  id: string
  originalMessage: string
  isTranslating: boolean
  isTranslationReady: boolean
  translateTargetLanguage: string | null
  translationError: {type: string; message: string} | null
  translatedTitle: string | null
  translatedMessage: string | null
  translationLanguages?: {id: string; translated_to_name: string}[]
  retryTranslation?: () => void
}

const TranslationContext = createContext<TranslationContextType | undefined>(undefined)

interface TranslationProps {
  id: string
  title: string
  message: string
}

const Translation = ({id, title, message, children}: PropsWithChildren<TranslationProps>) => {
  const entryInfo = useTranslationStore(state => state.entries[id])
  const activeLanguage = useTranslationStore(state => state.activeLanguage)
  const isTranslateAll = useTranslationStore(state => state.translateAll)
  const setTranslationStart = useTranslationStore(state => state.setTranslationStart)
  const setTranslationEnd = useTranslationStore(state => state.setTranslationEnd)
  const setTranslationError = useTranslationStore(state => state.setTranslationError)

  const {translationLanguages, entryTranslatingSet, enqueueTranslation}: any = useContext(
    DiscussionManagerUtilityContext,
  )

  const addEntry = useTranslationStore(state => state.addEntry)
  const removeEntry = useTranslationStore(state => state.removeEntry)

  const retryTranslation = async () => {
    const language = entryInfo?.language || activeLanguage
    if (!language) return

    try {
      setTranslationStart(id)

      const [translatedTitle, translatedMessage] = await Promise.all([
        getTranslation(title, language),
        getTranslation(message, language),
      ])

      setTranslationEnd(id, language, translatedMessage, translatedTitle)
    } catch (error: any) {
      setTranslationEnd(id)
      if (error.translationError) {
        setTranslationError(id, error.translationError, language)
      }
    }
  }

  useEffect(() => {
    addEntry(id, {title, message})

    if (isTranslateAll) {
      // Double-check translateAll is still active before enqueueing
      const currentState = useTranslationStore.getState()
      if (!currentState.translateAll) {
        return
      }

      const translationJob = async (signal: AbortSignal) => {
        try {
          // Check if already aborted before starting
          if (signal.aborted) {
            return
          }

          // Get current language from store, not from closure
          const currentLanguage = useTranslationStore.getState().activeLanguage
          if (!currentLanguage) {
            return
          }

          setTranslationStart(id)

          const [translatedTitle, translatedMessage] = await Promise.all([
            getTranslation(title, currentLanguage, signal),
            getTranslation(message, currentLanguage, signal),
          ])

          // Check multiple conditions before updating state
          const currentState = useTranslationStore.getState()

          if (
            signal.aborted ||
            !currentState.translateAll ||
            currentState.activeLanguage !== currentLanguage
          ) {
            return
          }

          setTranslationEnd(id, currentLanguage, translatedMessage, translatedTitle)
        } catch (error: any) {
          // Don't update state if the request was aborted
          if (error.name === 'AbortError' || error.message?.includes('aborted')) {
            return
          }

          // Get current language from store for error reporting
          const errorLanguage = useTranslationStore.getState().activeLanguage

          setTranslationEnd(id)
          if (error.translationError) {
            setTranslationError(id, error.translationError, errorLanguage!)
          } else {
            setTranslationError(
              id,
              {
                type: 'newError',
                message: I18n.t('There was an unexpected error during translation.'),
              },
              errorLanguage!,
            )
          }
        }
      }

      enqueueTranslation(translationJob)
    }

    return () => {
      removeEntry(id)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const isTranslating = entryTranslatingSet?.has(id)

  if (isTranslating || !entryInfo) {
    return null
  }

  let isTranslationReady = false

  if (!entryInfo.loading) {
    if (entryInfo.translatedMessage && !entryInfo.title) {
      isTranslationReady = true
    }

    if (entryInfo.translatedTitle && !entryInfo.message) {
      isTranslationReady = true
    }

    if (entryInfo.translatedTitle && entryInfo.translatedMessage) {
      isTranslationReady = true
    }
  }

  return (
    <TranslationContext.Provider
      value={{
        id,
        originalMessage: message,
        isTranslating: entryInfo.loading,
        isTranslationReady,
        translateTargetLanguage: entryInfo.language || null,
        translatedTitle: entryInfo.translatedTitle || null,
        translatedMessage: entryInfo.translatedMessage || null,
        translationError: entryInfo.error || null,
        translationLanguages: translationLanguages?.current,
        retryTranslation,
      }}
    >
      {children}
    </TranslationContext.Provider>
  )
}

const hrStyle = {
  borderStyle: 'dashed none none',
  borderWidth: '2px',
  margin: 0,
}

const Divider = () => {
  const context = useContext(TranslationContext)

  if (context === undefined) {
    return null
  }

  const {translationLanguages, translateTargetLanguage, isTranslationReady, translationError} =
    context

  if (!translateTargetLanguage || (!isTranslationReady && !translationError)) {
    return null
  }

  return (
    <Flex direction="row" alignItems="center" margin="medium 0 medium 0">
      <Flex.Item shouldGrow margin="0 small 0 0">
        <hr role="presentation" aria-hidden="true" style={hrStyle} />
      </Flex.Item>
      <Flex.Item>
        <Text color="secondary" size="small" fontStyle="italic">
          <span style={{marginRight: '0.5rem'}}>
            <IconAiLine />
          </span>
          <span>
            {
              translationLanguages?.find(language => language.id === translateTargetLanguage)
                ?.translated_to_name
            }
          </span>
        </Text>
      </Flex.Item>
      <Flex.Item shouldGrow margin="0 0 0 small">
        <hr role="presentation" aria-hidden="true" style={hrStyle} />
      </Flex.Item>
    </Flex>
  )
}

interface ContentProps {
  children: ({
    title,
    message,
    targetLanguage,
  }: {
    title: string | null
    message: string | null
    targetLanguage?: string
  }) => React.ReactNode
}

const Content = ({children}: ContentProps) => {
  const context = useContext(TranslationContext)

  if (context === undefined) {
    return null
  }

  const {
    isTranslationReady,
    translatedTitle,
    translatedMessage,
    translateTargetLanguage,
    translationError,
  } = context

  if (!isTranslationReady || translationError) {
    return null
  }

  return (
    <>
      {children({
        title: translatedTitle,
        message: translatedMessage,
        targetLanguage: translateTargetLanguage || undefined,
      })}
    </>
  )
}

const Error = () => {
  const context = useContext(TranslationContext)

  if (context === undefined) {
    return null
  }

  const {isTranslating, translateTargetLanguage, translationError, retryTranslation} = context

  if (isTranslating || !translateTargetLanguage || !translationError) {
    return null
  }

  if (translationError.type === 'rateLimitError') {
    return (
      <Flex direction="column" gap="medium" margin="0 0 small 0">
        <Flex direction="row" alignItems="center" gap="x-small">
          <IconWarningSolid color="error" title="warning" />
          <Text color="danger" data-testid="error_type_rate_limit">
            {translationError.message}
          </Text>
        </Flex>
        <Link
          variant="standalone"
          onClick={retryTranslation}
          data-testid="retry-translation-button"
          width="fit-content"
          forceButtonRole={false}
        >
          <Flex direction="row" alignItems="center" gap="x-small">
            <IconRefreshLine />
            <Text>{I18n.t('Retry Translation')}</Text>
          </Flex>
        </Link>
      </Flex>
    )
  }

  if (translationError.type === 'error' || translationError.type === 'newError') {
    return (
      <Flex direction="row" alignItems="center" margin="0 0 small 0" gap="x-small">
        <IconWarningSolid color="error" title="warning" />
        <Text color="danger" data-testid="error_type_error">
          {translationError.message}
        </Text>
      </Flex>
    )
  }

  if (translationError.type === 'info') {
    return (
      <Flex direction="row" alignItems="center" margin="0 0 small 0" gap="x-small">
        <Text color="secondary" fontStyle="italic" data-testid="error_type_info">
          {translationError.message}
        </Text>
      </Flex>
    )
  }

  return null
}

const Actions = () => {
  const context = useContext(TranslationContext)
  const clearEntry = useTranslationStore(state => state.clearEntry)
  const setModalOpen = useTranslationStore(state => state.setModalOpen)
  const translateAll = useTranslationStore(state => state.translateAll)

  if (context === undefined) {
    return null
  }

  const {id, originalMessage, isTranslationReady, translationError} = context

  if (!isTranslationReady || translationError || translateAll) {
    return null
  }

  const handleChangeLanguage = () => {
    setModalOpen(id, originalMessage)
  }

  const handleHideTranslation = () => {
    clearEntry(id)
  }

  return (
    <Flex direction="row" gap="x-small" margin="small 0" alignItems="center">
      <Flex.Item>
        <Link
          onClick={handleChangeLanguage}
          isWithinText={false}
          data-testid="change-language-link"
        >
          <Flex direction="row" gap="x-small" alignItems="center">
            <Text size="small">{I18n.t('Change translation language')}</Text>
          </Flex>
        </Link>
      </Flex.Item>
      <Flex.Item>
        <Text color="brand" size="small">
          •
        </Text>
      </Flex.Item>
      <Flex.Item>
        <Link
          onClick={handleHideTranslation}
          isWithinText={false}
          data-testid="hide-translation-link"
        >
          <Flex direction="row" gap="x-small" alignItems="center">
            <Text size="small">{I18n.t('Hide translation')}</Text>
          </Flex>
        </Link>
      </Flex.Item>
    </Flex>
  )
}

Translation.Content = Content

Translation.Divider = Divider

Translation.Error = Error

Translation.Actions = Actions

export {Translation}
