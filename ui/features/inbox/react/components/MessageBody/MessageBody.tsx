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

import React, {useContext, useEffect} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ModalBodyContext, signatureSeparator} from '../../utils/constants'

const I18n = useI18nScope('conversations_2')

type Message = {
  text: string
  type: 'error' | 'hint' | 'success' | 'screenreader-only'
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

  const {body, setBody, translating} = useContext(ModalBodyContext)

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
      messages={props.messages}
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
