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

import React, {useMemo, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Modal} from '@instructure/ui-modal'
import {TextArea} from '@instructure/ui-text-area'
import {Button, CloseButton} from '@instructure/ui-buttons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

import type {MessageDataSet} from './Messages'

const I18n = createI18nScope('messages')

const TABS: Array<Record<string, string>> = [
  {id: 'message-meta-data', title: I18n.t('Metadata')},
  {id: 'message-plain', title: I18n.t('Plain Text')},
  {id: 'message-html', title: I18n.t('HTML')},
]

const modalLabel = () => I18n.t('Send a reply message')

type MessageProps = MessageDataSet & {userId: string}

export default function Message(props: MessageProps): JSX.Element {
  const [selectedTab, setSelectedTab] = useState<number>(0)
  const [replyModalOpen, setReplyModalOpen] = useState<boolean>(false)
  const [message, setMessage] = useState<string>('')

  const elementTabs: Record<string, HTMLElement> = useMemo(
    function () {
      return Object.fromEntries(
        TABS.map(tab => [tab.id, props.element.querySelector(`.${tab.id}`)!]),
      )
    },
    [props.element],
  )

  function createFormData() {
    const formData = new FormData()
    const fromAddr = props.element.querySelector('.message-meta-data .message-to')?.textContent
    formData.append('from', (fromAddr ?? '').trim())
    formData.append('message_id', props.messageId)
    formData.append('secure_id', props.secureId)
    formData.append('subject', props.subject)
    formData.append('message', message.trim())
    return formData
  }

  function handleReplyOpen() {
    setReplyModalOpen(true)
  }

  function handleReplyClose() {
    setMessage('')
    setReplyModalOpen(false)
  }

  async function sendReply(body: FormData) {
    const path = `/users/${props.userId}/messages`
    try {
      await doFetchApi({method: 'POST', path, body})
      showFlashSuccess(I18n.t('Your email is being delivered.'))()
    } catch (e) {
      showFlashError(
        I18n.t('There was an error sending your email. Please reload the page and try again.'),
      )(e as Error)
    }
  }

  function handleReplySend() {
    console.info(`Reply modal sent for id ${props.messageId} (${props.secureId})`)
    sendReply(createFormData())
    handleReplyClose()
  }

  function handleTabChange(_e: unknown, {index}: {index: number}) {
    setSelectedTab(index)
  }

  function renderTabs() {
    return (
      <Tabs data-testid="message-tabs" variant="secondary" onRequestTabChange={handleTabChange}>
        {TABS.map((tab, index) => (
          <Tabs.Panel
            data-testid={`message-tab-${tab.id}`}
            key={tab.id}
            unmountOnExit={false}
            renderTitle={tab.title}
            isSelected={selectedTab === index}
          >
            <div dangerouslySetInnerHTML={{__html: elementTabs[tab.id].innerHTML}}></div>
          </Tabs.Panel>
        ))}
      </Tabs>
    )
  }

  function renderModal() {
    return (
      <Modal size="small" open={replyModalOpen} onDismiss={handleReplyClose} label={modalLabel()}>
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={handleReplyClose}
            screenReaderLabel={I18n.t('Cancel')}
          />
          <Heading variant="titleCardRegular">{modalLabel()}</Heading>
        </Modal.Header>
        <Modal.Body>
          <TextArea
            label={I18n.t('Reply message')}
            placeholder={I18n.t('Enter text')}
            value={message}
            onChange={e => setMessage(e.target.value)}
          />
        </Modal.Body>
        <Modal.Footer>
          <Button color="primary" margin="none x-small" onClick={handleReplySend}>
            {I18n.t('Send')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }

  return (
    <View
      as="div"
      borderRadius="small"
      borderWidth="small"
      padding="paddingCardSmall"
      margin="moduleElements none"
      elementRef={ref => {
        if (!ref) return
        const replyButton = ref.querySelector<HTMLAnchorElement>('.reply-button')
        if (replyButton) replyButton.addEventListener('click', handleReplyOpen)
      }}
    >
      <Flex alignItems="start" margin="space12 none">
        <Flex.Item shouldGrow>
          <Heading variant="titleCardRegular">{props.subject}</Heading>
        </Flex.Item>
        <Flex.Item>
          <Pill>{props.workflowState}</Pill>
        </Flex.Item>
      </Flex>
      {renderTabs()}
      {renderModal()}
    </View>
  )
}
