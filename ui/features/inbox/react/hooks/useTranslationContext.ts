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

import { createContext, Dispatch, SetStateAction, useContext, useState } from "react"
import { updateTranslatedModalBody, translateMessage } from "../utils/inbox_translator";
import { useScope as createI18nScope } from '@canvas/i18n'
import { translationSeparator } from "../utils/constants";

export interface TranslationContextValue {
  body: string;
  setBody: Dispatch<SetStateAction<string>>;
  translating: boolean;
  setTranslating: Dispatch<SetStateAction<boolean>>;
  translationTargetLanguage: string | null;
  setTranslationTargetLanguage: Dispatch<SetStateAction<string | null>>;
  messagePosition: string | null;
  setMessagePosition: Dispatch<SetStateAction<string | null>>;
  translateBody: (isPrimary: boolean) => void;
  translateBodyWith: (isPrimary: boolean, bodyText: string, { tgtLang }: any) => Promise<void>;
}

interface Inputs {
  subject?: string;
  activeSignature?: string;
  setModalError: (err: string | null) => void
  body: string;
  setBody: Dispatch<SetStateAction<string>>;
}

const I18n = createI18nScope('conversations_2')

export const TranslationContext = createContext<TranslationContextValue | null>(null)
TranslationContext.displayName = "TranslationContext"

export const useTranslationContextState = ({ subject, activeSignature, setModalError, body, setBody }: Inputs): TranslationContextValue => {
  const [translationTargetLanguage, setTranslationTargetLanguage] = useState<string | null>(null)
  const [translating, setTranslating] = useState(false)
  const [messagePosition, setMessagePosition] = useState<string | null>(null)

  const getBodyWithoutTranslation = (isPrimary: boolean, bodyText: string) => {
    if (bodyText.includes(translationSeparator)) {
      return bodyText.split(translationSeparator)[isPrimary ? 1 : 0]
    }

    return bodyText
  }

  const translateBody = (isPrimary: boolean) => {
    translateBodyWith(isPrimary, body)
  }

  const translateBodyWith = async (isPrimary: boolean, bodyText: string, { tgtLang }: any = {}) => {
    if (!tgtLang && !translationTargetLanguage) {
      return
    }

    const strippedBody = getBodyWithoutTranslation(isPrimary, bodyText)

    setTranslating(true)
    try {
      const translatedText = await translateMessage({
        subject: subject,
        body: strippedBody,
        signature: activeSignature,
        tgtLang: typeof tgtLang !== 'undefined' ? tgtLang : translationTargetLanguage,
      })


      // TODO: fix typescript related issue and remove the ! mark
      updateTranslatedModalBody(translatedText!, isPrimary, setBody, activeSignature, strippedBody)
    } catch (_err) {
      setModalError(I18n.t('Error while trying to translate message'))
      setTimeout(() => {
        setModalError(null)
      }, 2500)
    } finally {
      setTranslating(false)
    }
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
    setMessagePosition
  }
}

export const useTranslationContext = () => {
  const currentContext = useContext(TranslationContext)

  if (!currentContext) {
    throw new Error(
      "useTranslationContext has to be used within <TranslationContext.Provider"
    )
  }

  return currentContext
}
