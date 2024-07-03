/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useLayoutEffect, useRef, useState} from 'react'
import formatMessage from '../../../../format-message'

import {Button, CloseButton, CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'
import {SVGIcon} from '@instructure/ui-svg-images'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {TextArea} from '@instructure/ui-text-area'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View, type ViewProps} from '@instructure/ui-view'
import {uid} from '@instructure/uid'

import {showFlashAlert} from '../../../../common/FlashAlert'
import doFetchApi, {type DoFetchApiResults} from '../do-fetch-api-effect'

import {AIWandSVG, AIAvatarSVG, InsertSVG, CopySVG, RefreshSVG, DislikeSVG} from './aiicons'
import {AIResponseModal} from './AIResponseModal'

const msgid = () => uid('msg', 3)

type AIToolsTrayContent = {
  type: 'selection' | 'full'
  content: string
}

type AIToolsTrayProps = {
  open: boolean
  container: HTMLElement
  mountNode: HTMLElement
  contextId: string
  contextType: string
  currentContent: AIToolsTrayContent
  onClose: () => void
  onInsertContent: (content: string) => void
  onReplaceContent: (content: string) => void
}

type AITask = 'modify' | 'generate'

type ChatMessageType = 'user' | 'response' | 'message' | 'waiting' | 'error'

type ChatMessage = {
  id: string
  type: ChatMessageType
  message: string
}

interface DoFetchError extends Error {
  response: Response
}

const modifyAllTaskMessage = formatMessage(
  'Hello. Please describe the modifications you would like to make to your composition.'
)
const modifySelectionTaskMessage = formatMessage(
  'Hello. Please describe the modifications you would like to make to your selection.'
)
const generateTaskMessage = formatMessage('Please decribe what you would like to compose.')

export const AIToolsTray = ({
  open,
  container,
  mountNode,
  contextId,
  contextType,
  currentContent,
  onClose,
  onInsertContent,
  onReplaceContent,
}: AIToolsTrayProps) => {
  const [trayRef, setTrayRef] = useState<HTMLElement | null>(null)
  const [containerStyle] = useState<Partial<CSSStyleDeclaration>>(() => {
    if (container) {
      return {
        width: container.style.width,
        boxSizing: container.style.boxSizing,
        transition: container.style.transition,
      } as Partial<CSSStyleDeclaration>
    }
    return {}
  })
  const [isOpen, setIsOpen] = useState<boolean>(open)
  const [task, setTask] = useState<AITask>(() => {
    return currentContent.content.trim().length > 0 ? 'modify' : 'generate'
  })
  const [userPrompt, setUserPrompt] = useState<string>('')
  const [waitingForResponse, setWaitingForResponse] = useState<boolean>(false)
  const [responseHtml, setResponseHtml] = useState<string>('')
  const chatContainerRef = useRef<HTMLDivElement | null>(null)

  const getModifyTaskMessage = useCallback(() => {
    return currentContent.type === 'selection' ? modifySelectionTaskMessage : modifyAllTaskMessage
  }, [currentContent.type])

  const initChatMessages = useCallback((): ChatMessage[] => {
    return [
      task === 'modify'
        ? {
            id: msgid(),
            type: 'message',
            message: getModifyTaskMessage(),
          }
        : {id: msgid(), type: 'message', message: generateTaskMessage},
    ]
  }, [getModifyTaskMessage, task])

  const chatMessagesRef = useRef<ChatMessage[]>(initChatMessages())

  const reset = useCallback(() => {
    chatMessagesRef.current = initChatMessages()
    setWaitingForResponse(false)
    setUserPrompt('')
  }, [initChatMessages])

  useLayoutEffect(() => {
    const lastbox = chatContainerRef.current?.querySelector('.ai-chat-box:last-child')
    lastbox?.scrollIntoView({behavior: 'smooth', block: 'nearest'})
  }, [trayRef, chatMessagesRef.current.length])

  useEffect(() => {
    setTask(currentContent.content.trim().length > 0 ? 'modify' : 'generate')
  }, [currentContent.content])

  useEffect(() => {
    if (open !== isOpen) {
      setIsOpen(open)
      reset()
    }
  }, [isOpen, open, reset])

  useEffect(() => {
    const shrinking_selector = '#content' // '.block-editor-editor'

    if (open && trayRef) {
      const ed = document.querySelector(shrinking_selector) as HTMLElement | null

      if (!ed) return
      const edstyle = window.getComputedStyle(ed)
      const ed_rect = ed.getBoundingClientRect()
      const padding = parseInt(edstyle.paddingRight, 10)
      const tray_left = window.innerWidth - trayRef.offsetWidth
      if (ed_rect.right > tray_left) {
        ed.style.boxSizing = 'border-box'
        ed.style.width = `${ed_rect.width - (ed_rect.right - tray_left - padding)}px`
      }
    } else {
      const ed = document.querySelector(shrinking_selector) as HTMLElement | null
      if (!ed) return
      ed.style.boxSizing = containerStyle.boxSizing || ''
      ed.style.width = containerStyle.width || ''
      ed.style.transition = containerStyle.transition || ''
    }
  }, [containerStyle, open, trayRef])

  const getResponse = useCallback(
    (prompt: string) => {
      setWaitingForResponse(true)

      // the .finally triggered the error even though there is a .catch
      // eslint-disable-next-line promise/catch-or-return
      doFetchApi({
        path: '/api/v1/rich_content/generate',
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({
          // context_id: contextId,
          // context_type: contextType,
          course_id: contextId,
          prompt,
          current_copy: task === 'modify' ? currentContent : undefined,
          type_of_request: task,
        }),
      })
        .then((result: DoFetchApiResults<any>) => {
          const {json} = result
          if (json.error) {
            chatMessagesRef.current.push({
              id: msgid(),
              type: 'error',
              message: formatMessage(json.error),
            })
          } else {
            chatMessagesRef.current.push({id: msgid(), type: 'response', message: json.content})
          }
        })
        .catch(async (err: DoFetchError) => {
          const err_result = await err.response.json()
          const msg = err_result.error || formatMessage('An error occurred processing your request')
          chatMessagesRef.current.push({
            id: msgid(),
            type: 'error',
            message: msg,
          })
        })
        .finally(() => {
          setWaitingForResponse(false)
        })
    },
    [contextId, currentContent, task]
  )
  const handleCloseTray = useCallback(() => {
    onClose()
    chatMessagesRef.current.push({
      id: msgid(),
      type: 'message',
      message: task === 'modify' ? getModifyTaskMessage() : generateTaskMessage,
    })
    setUserPrompt('')
  }, [getModifyTaskMessage, onClose, task])

  const handleChangeTask = useCallback(
    (
      event: React.SyntheticEvent,
      data: {
        value?: string | number
        id?: string
      }
    ) => {
      setTask(data.value as AITask)
      setWaitingForResponse(false)
      chatMessagesRef.current.push({
        id: msgid(),
        type: 'message',
        message: data.value === 'modify' ? getModifyTaskMessage() : generateTaskMessage,
      })
    },
    [getModifyTaskMessage]
  )

  const handlePromptChange = useCallback((e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setUserPrompt(e.target.value)
  }, [])

  const handleSubmitPrompt = useCallback(() => {
    chatMessagesRef.current.push({id: msgid(), type: 'user', message: userPrompt.trim()})
    getResponse(userPrompt)
    setUserPrompt('')
  }, [getResponse, userPrompt])

  const handleInsertResponse = useCallback(
    (responseText: string) => {
      onInsertContent(responseText)
    },
    [onInsertContent]
  )

  const handleCopyResponse = useCallback(async (responseText: string) => {
    try {
      // @ts-expect-error ClipboardItem.supports really does exist
      if (ClipboardItem.supports('text/html')) {
        const htmlBlob = new Blob([responseText], {type: 'text/html'})
        await navigator.clipboard.write([new ClipboardItem({'text/html': htmlBlob})])
      } else {
        const div = document.createElement('div')
        div.innerHTML = responseText
        await navigator.clipboard.writeText(div.textContent || '')
      }
      showFlashAlert({
        message: formatMessage('Response copied to clipboard'),
        type: 'success',
        err: undefined,
      })
    } catch (err) {
      showFlashAlert({
        message: formatMessage('Failed to copy response'),
        type: 'error',
        err: undefined,
      })
    }
  }, [])

  const handleRefreshResponse = useCallback(() => {
    getResponse(userPrompt)
  }, [getResponse, userPrompt])

  const handleDislikeResponse = useCallback(() => {
    // eslint-disable-next-line no-console
    console.log('dislike response') // TODO: what?
  }, [])

  const handleShowWholeResponse = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      const msgId = (event.target as HTMLElement).dataset.messageId
      const message = chatMessagesRef.current.find(msg => msg.id === msgId)
      if (message) {
        setResponseHtml(message.message)
      }
    },
    []
  )

  const handleCloseResponseModal = useCallback(() => {
    setResponseHtml('')
  }, [])

  const handleInsertFromModal = useCallback(() => {
    handleInsertResponse(responseHtml)
    handleCloseResponseModal()
  }, [handleCloseResponseModal, handleInsertResponse, responseHtml])

  const handleReplaceFromModal = useCallback(() => {
    onReplaceContent(responseHtml)
    handleCloseResponseModal()
  }, [handleCloseResponseModal, onReplaceContent, responseHtml])

  const sharkfin = () => {
    return (
      <svg width="14" height="14" viewBox="0 0 14 14" xmlns="http://www.w3.org/2000/svg">
        <polyline points="0,14 0,0 14,14" fill="none" stroke="#ccc" strokeWidth="1" />
        <polyline points="0,14 14,14" stroke="white" strokeWidth="2" />
      </svg>
    )
  }

  const renderResponse = (msgId: string) => {
    const message = chatMessagesRef.current.find(msg => msg.id === msgId)
    if (!message) {
      return <span>{formatMessage("I'm sorry, but I cannot find the AI's answer")}</span>
    }
    const div = document.createElement('div')
    div.innerHTML = message.message
    return (
      <div style={{display: 'flex', flexDirection: 'column'}}>
        <TruncateText maxLines={3}>{div.textContent}</TruncateText>
        <span style={{alignSelf: 'end'}}>
          <CondensedButton onClick={handleShowWholeResponse} data-message-id={msgId}>
            {formatMessage('Show all')}
          </CondensedButton>
        </span>
      </div>
    )
  }

  // TODO: should the response box get truncated?
  const renderChatBox = (message: ChatMessage, key: string) => {
    return (
      <div
        id={message.id}
        className="ai-chat-box"
        key={key}
        style={{display: 'flex', flexDirection: 'column', justifyContent: 'start', rowGap: '4px'}}
      >
        <SVGIcon src={AIAvatarSVG} size="small" />
        <div
          style={{
            padding: '.5rem',
            border: '1px solid #ccc',
            borderRadius: '.5rem',
            position: 'relative',
          }}
        >
          {message.type === 'waiting' && <Spinner renderTitle={message.message} size="x-small" />}
          {(message.type === 'message' || message.type === 'user') && message.message}
          {message.type === 'response' && renderResponse(message.id)}
          {message.type === 'error' && <span>{message.message}</span>}

          <div
            style={{
              position: 'absolute',
              top: '-18px', // Adjust this value to position the sharkfin
              left: '40px', // Adjust this value to align the sharkfin horizontally
            }}
          >
            {sharkfin()}
          </div>
        </div>
        {message.type === 'response' ? (
          /* TODO: why is it to wide w/o maxWidth? */
          <div
            style={{
              display: 'flex',
              gap: '8px',
              justifyContent: 'end',
              maxWidth: '95%',
              margin: '5px 0',
            }}
          >
            <IconButton
              screenReaderLabel={formatMessage('Insert')}
              withBackground={false}
              withBorder={false}
              onClick={handleInsertResponse.bind(null, message.message)}
            >
              <SVGIcon src={InsertSVG} size="x-small" />
            </IconButton>
            <IconButton
              screenReaderLabel={formatMessage('Copy')}
              withBackground={false}
              withBorder={false}
              onClick={handleCopyResponse.bind(null, message.message)}
            >
              <SVGIcon src={CopySVG} size="x-small" />
            </IconButton>
            <IconButton
              screenReaderLabel={formatMessage('Retry')}
              withBackground={false}
              withBorder={false}
              onClick={handleRefreshResponse}
            >
              <SVGIcon src={RefreshSVG} size="x-small" />
            </IconButton>
            <IconButton
              screenReaderLabel={formatMessage('Dislike')}
              withBackground={false}
              withBorder={false}
              onClick={handleDislikeResponse}
            >
              <SVGIcon src={DislikeSVG} size="x-small" />
            </IconButton>
          </div>
        ) : null}
      </div>
    )
  }

  const renderChatMessages = () => {
    const messages = chatMessagesRef.current.map((message: ChatMessage) => {
      return renderChatBox(message, message.id)
    })
    if (waitingForResponse) {
      messages.push(
        renderChatBox(
          {id: msgid(), type: 'waiting', message: formatMessage('Waiting for response')},
          'ai-waiting-message'
        )
      )
    }
    return messages
  }

  return (
    <Tray
      contentRef={el => setTrayRef(el)}
      label="AIToolsTray"
      mountNode={mountNode}
      open={open}
      placement="end"
      size="small"
      onClose={handleCloseTray}
    >
      <View as="div" padding="small" position="relative" height="100vh" overflowY="hidden">
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: '16px',
            height: '100%',
            minHeight: '1px',
            maxHeight: '100%',
          }}
        >
          <Flex margin="0 0 medium" gap="small">
            <CloseButton placement="end" onClick={handleCloseTray} screenReaderLabel="Close" />
            <SVGIcon src={AIWandSVG} size="x-small" />
            <Heading level="h3">{formatMessage('Writing Assistant')}</Heading>
          </Flex>
          <SimpleSelect
            renderLabel={formatMessage('What would you like to do?')}
            value={task}
            onChange={handleChangeTask}
          >
            <SimpleSelect.Option
              id="modify"
              value="modify"
              isDisabled={currentContent.content.trim().length === 0}
            >
              {formatMessage('Modify')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="generate" value="generate">
              {formatMessage('Compose')}
            </SimpleSelect.Option>
          </SimpleSelect>
          <div style={{flexGrow: 1, overflowY: 'auto'}}>
            <div
              ref={chatContainerRef}
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
                justifyContent: 'end',
                minHeight: '100%',
              }}
            >
              {renderChatMessages()}
            </div>
          </div>
          <View as="div" padding="small 0 0 0" borderWidth="small 0 0 0">
            <TextArea
              id="ai-prompt"
              label={<ScreenReaderContent>{formatMessage('Enter text')}</ScreenReaderContent>}
              resize="vertical"
              value={userPrompt}
              onChange={handlePromptChange}
            />
          </View>
          <div style={{alignSelf: 'end'}}>
            <Button
              onClick={handleSubmitPrompt}
              interaction={waitingForResponse || !userPrompt.trim() ? 'disabled' : 'enabled'}
            >
              {formatMessage('Submit')}
            </Button>
          </div>
        </div>
        {responseHtml && (
          <AIResponseModal
            open={true}
            onClose={handleCloseResponseModal}
            html={responseHtml}
            onInsert={handleInsertFromModal}
            onReplace={handleReplaceFromModal}
          />
        )}
      </View>
    </Tray>
  )
}
