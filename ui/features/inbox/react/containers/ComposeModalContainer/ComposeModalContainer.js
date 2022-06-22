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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import closedCaptionLanguages from '@canvas/util/closedCaptionLanguages'
import {ComposeActionButtons} from '../../components/ComposeActionButtons/ComposeActionButtons'
import {Conversation} from '../../../graphql/Conversation'
import HeaderInputs from './HeaderInputs'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import ModalBody from './ModalBody'
import ModalHeader from './ModalHeader'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'
import {uploadFiles} from '@canvas/upload-file'
import UploadMedia from '@instructure/canvas-media'
import {
  UploadMediaStrings,
  MediaCaptureStrings,
  SelectStrings
} from '@canvas/upload-media-translations'
import {ConversationContext} from '../../../util/constants'

const I18n = useI18nScope('conversations_2')

const ComposeModalContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [attachments, setAttachments] = useState([])
  const [attachmentsToUpload, setAttachmentsToUpload] = useState([])
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')
  const [addressBookInputValue, setAddressBookInputValue] = useState('')
  const [bodyMessages, setBodyMessages] = useState([])
  const [addressBookMessages, setAddressBookMessages] = useState([])
  const [sendIndividualMessages, setSendIndividualMessages] = useState(false)
  const [userNote, setUserNote] = useState(false)
  const [selectedContext, setSelectedContext] = useState()
  const [courseMessages, setCourseMessages] = useState([])
  const [mediaUploadOpen, setMediaUploadOpen] = useState(false)
  const [uploadingMediaFile, setUploadingMediaFile] = useState(false)
  const [mediaUploadFile, setMediaUploadFile] = useState(null)
  const {isSubmissionCommentsType} = useContext(ConversationContext)

  const onMediaUploadComplete = (err, data) => {
    if (err) {
      setOnFailure(I18n.t('There was an error uploading the media.'))
    } else {
      setUploadingMediaFile(false)
      setMediaUploadFile(data)
    }
  }

  const onRemoveMedia = () => {
    setMediaUploadFile(null)
  }

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

  const onUserNoteChange = () => {
    setUserNote(prev => !prev)
  }

  const onSendIndividualMessagesChange = () => {
    setSendIndividualMessages(prev => !prev)
  }

  const onContextSelect = context => {
    if (context && context?.contextID) {
      setCourseMessages([])
    }

    setSelectedContext({contextID: context.contextID, contextName: context.contextName})
  }

  const validMessageFields = () => {
    let isValid = true
    if (!body) {
      setBodyMessages([{text: I18n.t('Please insert a message body.'), type: 'error'}])
      isValid = false
    }

    if (!isSubmissionCommentsType) {
      if (addressBookInputValue !== '') {
        setAddressBookMessages([
          {text: I18n.t('No matches found. Please insert a valid recipient.'), type: 'error'}
        ])
        isValid = false
      } else if (props.selectedIds.length === 0) {
        setAddressBookMessages([{text: I18n.t('Please select a recipient.'), type: 'error'}])
        isValid = false
      }
    }

    if (!isSubmissionCommentsType && !props.isReply && !props.isForward) {
      if (
        !ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT &&
        (!selectedContext || !selectedContext?.contextID)
      ) {
        setCourseMessages([{text: I18n.t('Please select a course'), type: 'error'}])
        isValid = false
      }
    }

    return isValid
  }

  const onSelectedIdsChange = selectedIds => {
    if (selectedIds.length > 0 && addressBookMessages.length > 0) {
      setAddressBookMessages([])
    }

    props.onSelectedIdsChange(selectedIds)
  }

  const sendMessage = async () => {
    if (isSubmissionCommentsType) {
      await props.createSubmissionComment({
        variables: {
          body
        }
      })
    } else if (props.isReply) {
      await props.addConversationMessage({
        variables: {
          attachmentIds: attachments.map(a => a.id),
          body,
          userNote,
          includedMessages: props.pastConversation?.conversationMessagesConnection.nodes.map(
            c => c._id
          ),
          mediaCommentId: mediaUploadFile?.mediaObject?.media_object?.media_id,
          mediaCommentType: mediaUploadFile?.mediaObject?.media_object?.media_type
        }
      })
    } else if (props.isForward) {
      await props.addConversationMessage({
        variables: {
          attachmentIds: attachments.map(a => a.id),
          body,
          includedMessages: props.pastConversation?.conversationMessagesConnection.nodes.map(
            c => c._id
          ),
          recipients: props.selectedIds.map(rec => rec?._id || rec.id),
          mediaCommentId: mediaUploadFile?.mediaObject?.media_object?.media_id,
          mediaCommentType: mediaUploadFile?.mediaObject?.media_object?.media_type,
          contextCode: ENV.CONVERSATIONS.ACCOUNT_CONTEXT_CODE
        }
      })
    } else {
      await props.createConversation({
        variables: {
          attachmentIds: attachments.map(a => a.id),
          body,
          userNote,
          contextCode: selectedContext?.contextID,
          recipients: props.selectedIds.map(rec => rec?._id || rec.id),
          subject,
          groupConversation: !sendIndividualMessages,
          mediaCommentId: mediaUploadFile?.mediaObject?.media_object?.media_id,
          mediaCommentType: mediaUploadFile?.mediaObject?.media_object?.media_type
        }
      })
    }
  }

  const resetState = () => {
    setAttachments([])
    setAttachmentsToUpload([])
    setBody(null)
    setBodyMessages([])
    setAddressBookMessages([])
    setSelectedContext(null)
    setCourseMessages([])
    props.onSelectedIdsChange([])
    props.setSendingMessage(false)
    setSubject(null)
    setSendIndividualMessages(false)
    setMediaUploadFile(null)
  }

  return (
    <>
      <Responsive
        match="media"
        query={responsiveQuerySizes({mobile: true, desktop: true})}
        props={{
          mobile: {
            modalSize: 'fullscreen',
            dataTestId: 'compose-modal-mobile'
          },
          desktop: {
            modalSize: 'medium',
            dataTestId: 'compose-modal-desktop'
          }
        }}
        render={responsiveProps => (
          <Modal
            open={props.open}
            onDismiss={props.onDismiss}
            size={responsiveProps.modalSize}
            label={I18n.t('Compose Message')}
            shouldCloseOnDocumentClick={false}
            onExited={resetState}
            data-testid={responsiveProps.dataTestId}
          >
            <ModalHeader
              onDismiss={props.onDismiss}
              headerTitle={props?.submissionCommentsHeader}
            />
            <ModalBody
              attachments={[...attachments, ...attachmentsToUpload]}
              bodyMessages={bodyMessages}
              onBodyChange={onBodyChange}
              pastMessages={props.pastConversation?.conversationMessagesConnection.nodes}
              removeAttachment={removeAttachment}
              replaceAttachment={replaceAttachment}
              modalError={props.modalError}
            >
              {isSubmissionCommentsType ? null : (
                <HeaderInputs
                  activeCourseFilter={selectedContext}
                  setUserNote={setUserNote}
                  contextName={props.pastConversation?.contextName}
                  courses={props.courses}
                  selectedRecipients={props.selectedIds}
                  isReply={props.isReply}
                  isForward={props.isForward}
                  onContextSelect={onContextSelect}
                  onSelectedIdsChange={onSelectedIdsChange}
                  onUserNoteChange={onUserNoteChange}
                  onSendIndividualMessagesChange={onSendIndividualMessagesChange}
                  onSubjectChange={onSubjectChange}
                  onAddressBookInputValueChange={setAddressBookInputValue}
                  userNote={userNote}
                  sendIndividualMessages={sendIndividualMessages}
                  subject={
                    props.isReply || props.isForward ? props.pastConversation?.subject : subject
                  }
                  mediaAttachmentTitle={mediaUploadFile?.uploadedFile.name}
                  onRemoveMediaComment={onRemoveMedia}
                  addressBookMessages={addressBookMessages}
                  courseMessages={courseMessages}
                  data-testid="compose-modal-inputs"
                  isPrivateConversation={props.isPrivateConversation}
                />
              )}
            </ModalBody>
            <Modal.Footer>
              <ComposeActionButtons
                onAttachmentUpload={addAttachment}
                onMediaUpload={() => setMediaUploadOpen(true)}
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
                hasMediaComment={!!mediaUploadFile}
              />
            </Modal.Footer>
          </Modal>
        )}
      />
      <UploadMedia
        onStartUpload={() => setUploadingMediaFile(true)}
        onUploadComplete={onMediaUploadComplete}
        onDismiss={() => setMediaUploadOpen(false)}
        open={mediaUploadOpen}
        tabs={{embed: false, record: true, upload: true}}
        uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings, SelectStrings}}
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        languages={Object.keys(closedCaptionLanguages).map(key => {
          return {id: key, label: closedCaptionLanguages[key]}
        })}
        rcsConfig={{
          contextId: ENV.current_user_id,
          contextType: 'user'
        }}
      />
      <ModalSpinner
        label={I18n.t('Sending Message')}
        message={I18n.t('Sending Message')}
        open={props.sendingMessage && !attachmentsToUpload.length && !uploadingMediaFile}
      />
      <ModalSpinner
        label={I18n.t('Uploading Files')}
        message={I18n.t('Please wait while we upload attachments and media')}
        onExited={() => sendMessage()}
        open={props.sendingMessage && !!attachmentsToUpload.length && uploadingMediaFile}
      />
    </>
  )
}

export default ComposeModalContainer

ComposeModalContainer.propTypes = {
  addConversationMessage: PropTypes.func,
  createSubmissionComment: PropTypes.func,
  courses: PropTypes.object,
  createConversation: PropTypes.func,
  isReply: PropTypes.bool,
  isForward: PropTypes.bool,
  onDismiss: PropTypes.func,
  open: PropTypes.bool,
  pastConversation: Conversation.shape,
  sendingMessage: PropTypes.bool,
  setSendingMessage: PropTypes.func,
  onSelectedIdsChange: PropTypes.func,
  selectedIds: PropTypes.array,
  submissionCommentsHeader: PropTypes.string,
  modalError: PropTypes.string,
  isPrivateConversation: PropTypes.bool
}
