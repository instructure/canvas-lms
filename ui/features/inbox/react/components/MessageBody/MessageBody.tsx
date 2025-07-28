/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {useScope as createI18nScope} from '@canvas/i18n'
import {signatureSeparator} from '../../utils/constants'
import {useTranslationContext} from '../../hooks/useTranslationContext'

const I18n = createI18nScope('conversations_2')

type Message = {
  text: React.ReactNode
  type: 'newError' | 'error' | 'hint' | 'success' | 'screenreader-only'
}

type Props = {
  onBodyChange: (body: string) => void
  messages: Message[]
  inboxSignatureBlock: boolean
  signature?: string
}

export const MessageBody = (props: Props) => {
  const signature =
    (props.inboxSignatureBlock && props.signature && `${signatureSeparator}${props.signature}`) ||
    ''

  const {body, setBody, translating, textTooLongErrors} = useTranslationContext()

  useEffect(() => {
    if (signature) setBody((body: string) => body + signature)
  }, [setBody, signature])

  const handleBodyChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setBody(e.target.value)
    props.onBodyChange(e.target.value)
  }

  return (
    <TextArea
      label={<ScreenReaderContent>{I18n.t('Message Body')}</ScreenReaderContent>}
      messages={textTooLongErrors ? props.messages?.concat(textTooLongErrors) : props.messages}
      autoGrow={false}
      height="200px"
      maxHeight="200px"
      value={body}
      onChange={handleBodyChange}
      disabled={translating}
      data-testid="message-body"
    />
  )
}
