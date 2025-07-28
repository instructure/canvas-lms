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

import { useMemo, useEffect } from 'react'
import { useTranslationContext } from "./useTranslationContext"
import { signatureSeparator, translationSeparator } from '../utils/constants'
import { stripSignature } from '../utils/inbox_translator'

const useTranslationDisplay = ({
  signature,
  inboxSettingsFeature,
  includeTranslation
}: {
  signature: string,
  inboxSettingsFeature: boolean,
  includeTranslation: boolean
}) => {
  useTranslationContext()

  const {
    setMessagePosition,
    messagePosition,
    body,
    setBody
  } = useTranslationContext()

  // If we have a message position, the message has been translated.
  const primary = useMemo(() => {
    if (messagePosition === null) {
      return null
    }

    return messagePosition === 'primary'
  }, [messagePosition])

  const translated = useMemo(() => {
    return messagePosition !== null && body.includes(translationSeparator)
  }, [messagePosition, body])

  /**
   * Handle placing translated message in primary or secondary position
   * */
  const handleIsPrimaryChange = (isPrimary: boolean) => {
    // If not already translated, translate the body.
    setMessagePosition(isPrimary ? 'primary' : 'secondary')

    if (primary !== null) {
      setBody((prevBody: string) => {
        let newBody = prevBody
        // Strip the signature
        if (inboxSettingsFeature && signature !== '') {
          newBody = stripSignature(prevBody)
        }

        // Split on the translation separator
        const [part1, part2] = newBody.split(translationSeparator)
        // Flip the message
        newBody = [part2, part1].join(translationSeparator)

        // Add the signature back in.
        if (inboxSettingsFeature && signature !== '' && signature !== undefined) {
          return [newBody, signature].join(signatureSeparator)
        }

        // No signature, return the body flipped.
        return newBody
      })
    }
  }

  useEffect(() => {
    if (!includeTranslation && translated) {
      setMessagePosition(null)
      setBody((prevBody: string) => {
        if (inboxSettingsFeature && signature !== '') {
          prevBody = stripSignature(prevBody)
        }

        const [part1, part2] = prevBody.split(translationSeparator)
        const newBody = messagePosition === 'primary' ? part2 : part1

        if (inboxSettingsFeature && signature !== '') {
          return [newBody, signature].join(signatureSeparator)
        }

        return newBody
      })
    }
  }, [
    includeTranslation,
    setMessagePosition,
    messagePosition,
    inboxSettingsFeature,
    signature,
    setBody,
    translated,

  ])

  return {
    handleIsPrimaryChange,
    primary
  }

}

export default useTranslationDisplay
