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

import {createContext, Dispatch, SetStateAction, useContext, useState} from 'react'
import {updateTranslatedModalBody, translateMessage} from '../utils/inbox_translator'
import {useScope as createI18nScope} from '@canvas/i18n'
import {translationSeparator} from '../utils/constants'
import {FormMessage} from '@instructure/ui-form-field'

export interface TranslationContextValue {
  body: string
  setBody: Dispatch<SetStateAction<string>>
  translating: boolean
  setTranslating: Dispatch<SetStateAction<boolean>>
  translationTargetLanguage: string | null
  setTranslationTargetLanguage: Dispatch<SetStateAction<string | null>>
  messagePosition: string | null
  setMessagePosition: Dispatch<SetStateAction<string | null>>
  translateBody: (isPrimary: boolean) => void
  translateBodyWith: (isPrimary: boolean, bodyText: string, {tgtLang}: any) => Promise<void>
  errorMessages: FormMessage[]
  setErrorMessages: Dispatch<SetStateAction<FormMessage[]>>
  textTooLongErrors: FormMessage[]
}

interface Inputs {
  subject?: string
  activeSignature?: string
  setModalError: (err: string | null) => void
  body: string
  setBody: Dispatch<SetStateAction<string>>
}

const I18n = createI18nScope('conversations_2')

export const TranslationContext = createContext<TranslationContextValue | null>(null)
TranslationContext.displayName = 'TranslationContext'

export const useTranslationContextState = ({
  subject,
  activeSignature,
  setModalError,
  body,
  setBody,
}: Inputs): TranslationContextValue => {
  const [translationTargetLanguage, setTranslationTargetLanguage] = useState<string | null>(null)
  const [translating, setTranslating] = useState(false)
  const [messagePosition, setMessagePosition] = useState<string | null>(null)
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>([])
  const [textTooLongErrors, setTextTooLongErrors] = useState<FormMessage[]>([])

  const getBodyWithoutTranslation = (isPrimary: boolean, bodyText: string) => {
    if (bodyText.includes(translationSeparator)) {
      return bodyText.split(translationSeparator)[isPrimary ? 1 : 0]
    }

    return bodyText
  }

  const translateBody = (isPrimary: boolean) => {
    translateBodyWith(isPrimary, body)
  }

  const translateBodyWith = async (isPrimary: boolean, bodyText: string, {tgtLang}: any = {}) => {
    if (!tgtLang && !translationTargetLanguage) {
      return
    }

    const strippedBody = getBodyWithoutTranslation(isPrimary, bodyText)

    setTranslating(true)
    setTextTooLongErrors([])

    translateMessage({
      subject: subject,
      body: strippedBody,
      signature: activeSignature,
      tgtLang: typeof tgtLang !== 'undefined' ? tgtLang : translationTargetLanguage,
    })
      .then(translatedText => {
        updateTranslatedModalBody(
          translatedText!,
          isPrimary,
          setBody,
          activeSignature,
          strippedBody,
        )
      })
      .catch(e => {
        if (e.translationError) {
          setErrorMessages([
            {
              type: 'newError',
              text: e.translationError.message,
            },
          ])
        } else if (e.translationErrorTextTooLong) {
          setTextTooLongErrors([
            {
              type: 'newError',
              text: e.translationErrorTextTooLong.message,
            },
          ])
        } else {
          setErrorMessages([
            {
              type: 'newError',
              text: I18n.t('There was an unexpected error during translation.'),
            },
          ])
        }
      })
      .finally(() => {
        setTranslating(false)
      })
  }

  return {
    body,
    setBody,
    translationTargetLanguage,
    setTranslationTargetLanguage,
    translating,
    setTranslating,
    translateBody,
    translateBodyWith,
    messagePosition,
    setMessagePosition,
    errorMessages,
    setErrorMessages,
    textTooLongErrors,
  }
}

export const useTranslationContext = () => {
  const currentContext = useContext(TranslationContext)

  if (!currentContext) {
    throw new Error('useTranslationContext has to be used within <TranslationContext.Provider')
  }

  return currentContext
}
