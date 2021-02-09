/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {AlertManagerContext} from 'jsx/shared/components/AlertManager'
import {ComposeActionButtons} from 'jsx/canvas_inbox/components/ComposeActionButtons/ComposeActionButtons'
import {Conversation} from '../../graphqlData/Conversation'
import HeaderInputs from './HeaderInputs'
import I18n from 'i18n!conversations_2'
import ModalBody from './ModalBody'
import ModalHeader from './ModalHeader'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {uploadFiles} from 'jsx/shared/upload_file'

import {Modal} from '@instructure/ui-modal'

const ComposeModalContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [attachments, setAttachments] = useState([])
  const [attachmentsToUpload, setAttachmentsToUpload] = useState([])
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')
  const [bodyMessages, setBodyMessages] = useState([])
  const [sendIndividualMessages, setSendIndividualMessages] = useState(false)
  const [selectedContext, setSelectedContext] = useState()

  const fileUploadUrl = attachmentFolderId => {
    return `/api/v1/folders/${attachmentFolderId}/files`
  }

  const addAttachment = async e => {
    const files = Array.from(e.currentTarget?.files)
    if (!files.length) {
      setOnFailure(I18n.t('Error adding files to conversation message'))
      return
    }

    const newAttachmentsToUpload = files.map((file, i) => {
      return {isLoading: true, id: file.url ? `${i}-${file.url}` : `${i}-${file.name}`}
    })

    setAttachmentsToUpload(prev => prev.concat(newAttachmentsToUpload))
    setOnSuccess(I18n.t('Uploading files'))

    try {
      const newFiles = await uploadFiles(
        files,
        fileUploadUrl(ENV.CONVERSATIONS.ATTACHMENTS_FOLDER_ID)
      )
      setAttachments(prev => prev.concat(newFiles))
    } catch (err) {
      setOnFailure(I18n.t('Error uploading files'))
    } finally {
      setAttachmentsToUpload(prev => {
        const attachmentsStillUploading = prev.filter(
          file => !newAttachmentsToUpload.includes(file)
        )
        return attachmentsStillUploading
      })
    }
  }

  const removeAttachment = id => {
    setAttachments(prev => {
      const index = prev.findIndex(attachment => attachment.id === id)
      prev.splice(index, 1)
      return [...prev]
    })
  }

  const replaceAttachment = async (id, e) => {
    removeAttachment(id)
    addAttachment(e)
  }

  const onSubjectChange = value => {
    setSubject(value.currentTarget.value)
  }

  const onBodyChange = value => {
    setBody(value)
    if (value) {
      setBodyMessages([])
    }
  }

  const onSendIndividualMessagesChange = () => {
    setSendIndividualMessages(prev => !prev)
  }

  const onContextSelect = id => {
    setSelectedContext(id)
  }

  const validMessageFields = () => {
    // TODO: validate recipients
    if (!body) {
      setBodyMessages([{text: I18n.t('Message body is required'), type: 'error'}])
      return false
    }
    return true
  }

  const sendMessage = async () => {
    if (props.isReply) {
      await props.addConversationMessage({
        variables: {
          attachmentIds: attachments.map(a => a.id),
          body,
          includedMessages: props.pastConversation?.conversationMessagesConnection.nodes.map(
            c => c._id
          )
        }
      })
    } else {
      await props.createConversation({
        variables: {
          attachmentIds: attachments.map(a => a.id),
          body,
          contextCode: selectedContext,
          recipients: ['5'], // TODO: replace this with selected users
          subject,
          groupConversation: !sendIndividualMessages
        }
      })
    }

    props.onDismiss()
  }

  const resetState = () => {
    setAttachments([])
    setAttachmentsToUpload([])
    setBody(null)
    setBodyMessages([])
    setSelectedContext(null)
    props.setSendingMessage(false)
    setSubject(null)
    setSendIndividualMessages(false)
  }

  return (
    <>
      <Modal
        open={props.open}
        onDismiss={props.onDismiss}
        size="medium"
        label={I18n.t('Compose Message')}
        shouldCloseOnDocumentClick={false}
        onExited={resetState}
      >
        <ModalHeader onDismiss={props.onDismiss} />
        <ModalBody
          attachments={[...attachments, ...attachmentsToUpload]}
          bodyMessages={bodyMessages}
          onBodyChange={onBodyChange}
          pastMessages={props.pastConversation?.conversationMessagesConnection.nodes}
          removeAttachment={removeAttachment}
          replaceAttachment={replaceAttachment}
        >
          <HeaderInputs
            contextName={props.pastConversation?.contextName}
            courses={props.courses}
            isReply={props.isReply}
            onContextSelect={onContextSelect}
            onSendIndividualMessagesChange={onSendIndividualMessagesChange}
            onSubjectChange={onSubjectChange}
            sendIndividualMessages={sendIndividualMessages}
            subject={props.isReply ? props.pastConversation?.subject : subject}
          />
        </ModalBody>
        <Modal.Footer>
          <ComposeActionButtons
            onAttachmentUpload={addAttachment}
            onMediaUpload={() => {}}
            onCancel={props.onDismiss}
            onSend={() => {
              if (!validMessageFields()) {
                return
              }

              if (!attachmentsToUpload.length) {
                sendMessage()
              }
              props.setSendingMessage(true)
            }}
            isSending={false}
          />
        </Modal.Footer>
      </Modal>
      <ModalSpinner
        label={I18n.t('Sending Message')}
        message={I18n.t('Sending Message')}
        open={props.sendingMessage && !attachmentsToUpload.length}
      />
      <ModalSpinner
        label={I18n.t('Uploading Files')}
        message={I18n.t('Please wait while we upload attachments')}
        onExited={() => sendMessage()}
        open={props.sendingMessage && attachmentsToUpload.length}
      />
    </>
  )
}

export default ComposeModalContainer

ComposeModalContainer.propTypes = {
  addConversationMessage: PropTypes.func,
  courses: PropTypes.object,
  createConversation: PropTypes.func,
  isReply: PropTypes.bool,
  onDismiss: PropTypes.func,
  open: PropTypes.bool,
  pastConversation: Conversation.shape,
  sendingMessage: PropTypes.bool,
  setSendingMessage: PropTypes.func
}
