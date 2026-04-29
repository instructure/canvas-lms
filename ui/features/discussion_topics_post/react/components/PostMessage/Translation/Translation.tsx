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
import {
  IconAiLine,
  IconWarningSolid,
  IconRefreshLine,
  IconLikeLine,
  IconLikeSolid,
} from '@instructure/ui-icons'
import {createContext, PropsWithChildren, useContext, useEffect, useRef, useState} from 'react'
import {DiscussionManagerUtilityContext} from '../../../utils/constants'
import {useTranslationStore} from '../../../hooks/useTranslationStore'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getTranslation} from '../../../utils'
import {Link} from '@instructure/ui-link'
import {showFlashAlert} from '@instructure/platform-alerts'
import {IconButton, Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('discussion_topics_post')

interface TranslationContextType {
  id: string
  originalMessage: string
  originalTitle?: string
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

  const previousLoadingRef = useRef(false)
  const hasAnnouncedRef = useRef(false)

  const retryTranslation = async () => {
    const language = entryInfo?.language || activeLanguage
    if (!language) return

    // Reset announcement tracking for retry
    hasAnnouncedRef.current = false

    try {
      setTranslationStart(id)

      const [translatedTitle, translatedMessage] = await Promise.all([
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore - getTranslation's third argument (options) is optional at runtime but required by tsgo
        getTranslation(title, language),
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore - getTranslation's third argument (options) is optional at runtime but required by tsgo
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

  // Screen reader announcements for single entry translations
  useEffect(() => {
    // Skip announcements if translating all (handled by DiscussionTranslationModuleContainer)
    if (isTranslateAll) {
      return
    }

    const isLoading = entryInfo?.loading || false
    const hasError = !!entryInfo?.error
    const hasTranslation = !!(entryInfo?.translatedMessage || entryInfo?.translatedTitle)

    // Announce when translation starts loading
    if (isLoading && !previousLoadingRef.current && !hasAnnouncedRef.current) {
      showFlashAlert({
        message: I18n.t('Translating Text'),
        srOnly: true,
        politeness: 'polite',
      })
      previousLoadingRef.current = true
    }
    // Announce when translation completes (loading finished)
    else if (!isLoading && previousLoadingRef.current && !hasAnnouncedRef.current) {
      if (hasError) {
        showFlashAlert({
          message: I18n.t('Translation failed'),
          srOnly: true,
          politeness: 'assertive',
        })
      } else if (hasTranslation && entryInfo?.language) {
        const languageName =
          translationLanguages?.current?.find((lang: any) => lang.id === entryInfo.language)
            ?.name || entryInfo.language
        showFlashAlert({
          message: I18n.t('Text Translated to %{language}', {language: languageName}),
          srOnly: true,
          politeness: 'polite',
        })
      }
      previousLoadingRef.current = false
      hasAnnouncedRef.current = true
    }
  }, [
    entryInfo?.loading,
    entryInfo?.error,
    entryInfo?.translatedMessage,
    entryInfo?.translatedTitle,
    entryInfo?.language,
    isTranslateAll,
    translationLanguages,
  ])

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
        originalTitle: id === 'topic' ? title : undefined,
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

  const {id, originalMessage, originalTitle, isTranslationReady, translationError} = context

  if (!isTranslationReady || translationError || translateAll) {
    return null
  }

  const handleChangeLanguage = () => {
    setModalOpen(id, originalMessage, originalTitle)
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

declare const ENV: {
  course_id?: string
  discussion_topic_id?: string
  discussion_translation_feedback?: boolean
}

const FeedbackInner = ({
  id,
  translateTargetLanguage,
}: {
  id: string
  translateTargetLanguage: string
}) => {
  const [feedbackNotes, setLocalFeedbackNotes] = useState('')
  const liked = useTranslationStore(state => state.entries[id]?.feedbackLiked || false)
  const disliked = useTranslationStore(state => state.entries[id]?.feedbackDisliked || false)
  const feedbackLoading = useTranslationStore(state => state.entries[id]?.feedbackLoading || false)
  const storedNotes = useTranslationStore(state => state.entries[id]?.feedbackNotes)
  const setFeedbackState = useTranslationStore(state => state.setFeedbackState)
  const setFeedbackLoadingAction = useTranslationStore(state => state.setFeedbackLoading)
  const setFeedbackNotesAction = useTranslationStore(state => state.setFeedbackNotes)

  const contentType = id === 'topic' ? 'DiscussionTopic' : 'DiscussionEntry'
  const contentId = id === 'topic' ? ENV.discussion_topic_id : id

  const postFeedback = async (action: string, notes?: string) => {
    setFeedbackLoadingAction(id, true)

    try {
      const {json}: any = await doFetchApi({
        method: 'POST',
        path: `/courses/${ENV.course_id}/translate/feedback`,
        body: {
          _action: action,
          content_type: contentType,
          content_id: contentId,
          target_language: translateTargetLanguage,
          feature_slug: 'discussion_topic',
          notes,
        },
      })
      setFeedbackState(id, json.liked, json.disliked)
      if (notes) {
        setFeedbackNotesAction(id, notes)
      }
    } catch (_error) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('There was an unexpected error while submitting feedback.'),
      })
    } finally {
      setFeedbackLoadingAction(id, false)
    }
  }

  const handleLike = () => {
    postFeedback(liked ? 'reset_like' : 'like')
  }

  const handleDislike = () => {
    postFeedback(disliked ? 'reset_like' : 'dislike')
  }

  const handleSendNotes = () => {
    if (!feedbackNotes.trim()) return
    postFeedback('dislike', feedbackNotes)
  }

  return (
    <Flex direction="column" margin="small 0 0 0">
      <Flex justifyItems="end" alignItems="center">
        <Flex.Item margin="0 small 0 0">
          <Text color="secondary" size="small">
            {liked || disliked
              ? I18n.t('Thank you for sharing!')
              : I18n.t('Was this translation helpful?')}
          </Text>
        </Flex.Item>
        <IconButton
          onClick={handleLike}
          size="small"
          withBackground={false}
          withBorder={false}
          color={liked ? 'primary' : 'secondary'}
          screenReaderLabel={
            liked ? I18n.t('Like translation, selected') : I18n.t('Like translation')
          }
          interaction={feedbackLoading ? 'disabled' : 'enabled'}
          data-testid="translation-like-button"
        >
          {liked ? <IconLikeSolid /> : <IconLikeLine />}
        </IconButton>
        <IconButton
          onClick={handleDislike}
          size="small"
          withBackground={false}
          withBorder={false}
          color={disliked ? 'primary' : 'secondary'}
          screenReaderLabel={
            disliked ? I18n.t('Dislike translation, selected') : I18n.t('Dislike translation')
          }
          interaction={feedbackLoading ? 'disabled' : 'enabled'}
          data-testid="translation-dislike-button"
        >
          {disliked ? <IconLikeSolid rotate="180" /> : <IconLikeLine rotate="180" />}
        </IconButton>
      </Flex>
      {disliked && !storedNotes && (
        <Flex direction="column" gap="medium" margin="medium 0 0 0">
          <Text size="small">
            {I18n.t('Can you please explain why you disapprove of the translation?')}
          </Text>
          <Flex gap="small" alignItems="end">
            <Flex.Item shouldGrow={true}>
              <TextInput
                renderLabel={I18n.t('Explanation')}
                placeholder={I18n.t('Start typing...')}
                value={feedbackNotes}
                onChange={(_e, value) => setLocalFeedbackNotes(value)}
                data-testid="translation-feedback-input"
              />
            </Flex.Item>
            <Flex.Item>
              <Button
                color="secondary"
                onClick={handleSendNotes}
                interaction={!feedbackLoading && feedbackNotes.trim() ? 'enabled' : 'disabled'}
                data-testid="translation-feedback-submit"
              >
                {I18n.t('Send Feedback')}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex>
      )}
    </Flex>
  )
}

const Feedback = () => {
  const context = useContext(TranslationContext)

  if (context === undefined) {
    return null
  }

  const {id, isTranslationReady, translateTargetLanguage, translationError} = context

  if (!isTranslationReady || translationError || !translateTargetLanguage) {
    return null
  }

  if (!ENV.discussion_translation_feedback) {
    return null
  }

  return <FeedbackInner id={id} translateTargetLanguage={translateTargetLanguage} />
}

Translation.Content = Content

Translation.Divider = Divider

Translation.Error = Error

Translation.Actions = Actions

Translation.Feedback = Feedback

export {Translation}
