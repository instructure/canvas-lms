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
import {ComposeActionButtons} from '../../components/ComposeActionButtons/ComposeActionButtons'
import {Conversation} from '../../../graphql/Conversation'
import HeaderInputs from './HeaderInputs'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import ModalBody from './ModalBody'
import ModalHeader from './ModalHeader'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState, useEffect} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'
import {uploadFiles} from '@canvas/upload-file'
import UploadMedia from '@instructure/canvas-media'
import {
  UploadMediaStrings,
  MediaCaptureStrings,
  SelectStrings,
} from '@canvas/upload-media-translations'
import {ConversationContext} from '../../../util/constants'
import {useQuery} from '@apollo/client'
import {RECIPIENTS_OBSERVERS_QUERY, INBOX_SETTINGS_QUERY} from '../../../graphql/Queries'
import {TranslationContext, useTranslationContextState} from '../../hooks/useTranslationContext'
import {useFetchAllPages} from '@canvas/apollo-v3/hooks/useFetchAllPages'

const I18n = createI18nScope('conversations_2')

// @ts-expect-error TS7006 (typescriptify)
const ComposeModalContainer = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const [attachments, setAttachments] = useState([])
  const [attachmentsToUpload, setAttachmentsToUpload] = useState([])
  const [subject, setSubject] = useState('')
  const [addressBookInputValue, setAddressBookInputValue] = useState('')
  const [bodyMessages, setBodyMessages] = useState([])
  const [addressBookMessages, setAddressBookMessages] = useState([])
  const [sendIndividualMessages, setSendIndividualMessages] = useState(false)
  const [selectedContext, setSelectedContext] = useState()
  const [courseMessages, setCourseMessages] = useState([])
  const [mediaUploadOpen, setMediaUploadOpen] = useState(false)
  const [uploadingMediaFile, setUploadingMediaFile] = useState(false)
  const [mediaUploadFile, setMediaUploadFile] = useState(null)
  const {isSubmissionCommentsType} = useContext(ConversationContext)
  const [loadingObservers, setLoadingObservers] = useState(false)
  const [includeObserversMessages, setIncludeObserversMessages] = useState(null)
  const [activeSignature, setActiveSignature] = useState()

  const [body, setBody] = useState('')

  const contextValues = useTranslationContextState({
    subject,
    activeSignature,
    setModalError: props.setModalError,
    body,
    setBody,
  })

  const {loading: inboxSettingsLoading} = useQuery(INBOX_SETTINGS_QUERY, {
    onCompleted: data => {
      let signature
      if (data?.myInboxSettings?.useSignature) {
        signature = data.myInboxSettings.signature
      }
      setActiveSignature(signature)
    },
    onError: () => {
      setOnFailure(I18n.t('There was an error while loading inbox settings'))
      dismiss()
    },
    skip: !props.inboxSignatureBlock || !props.open,
  })

  const [
    getRecipientsObserversQuery,
    {
      data: recipientsObserversData,
      loading: recipientsObserversDataLoading,
      error: recipientsObserversError,
    },
  ] = useFetchAllPages(RECIPIENTS_OBSERVERS_QUERY, {
    getPageInfo: data => data?.legacyNode?.recipientsObservers?.pageInfo,
  })

  useEffect(() => {
    if (recipientsObserversError) {
      setIncludeObserversMessages({
        // @ts-expect-error TS2353 (typescriptify)
        text: I18n.t('Observers were not included. Please try again.'),
        type: 'newError',
      })
      setLoadingObservers(false)
    } else if (recipientsObserversDataLoading) {
      setLoadingObservers(true)
    } else {
      setLoadingObservers(false)
      if (!recipientsObserversData) {
        return
      }
      const observersToAdd = recipientsObserversData?.legacyNode?.recipientsObservers?.nodes || []

      if (observersToAdd.length > 0) {
        // @ts-expect-error TS7006 (typescriptify)
        const newObservers = observersToAdd.map(u => {
          return {
            _id: u._id,
            id: u.id,
            name: u.name,
            itemType: 'user',
            totalRecipients: 1,
          }
        })

        // Make sure no observers are added twice
        // @ts-expect-error TS7006 (typescriptify)
        const selectedRecipientIds = new Set(props.selectedIds.map(item => item.id))
        const uniqueSelectedIds = [
          ...props.selectedIds,
          // @ts-expect-error TS7006 (typescriptify)
          ...newObservers.filter(item => !selectedRecipientIds.has(item.id)),
        ]

        props.onSelectedIdsChange(uniqueSelectedIds)
      } else {
        setIncludeObserversMessages({
          // @ts-expect-error TS2353 (typescriptify)
          text: I18n.t('Selected recipient(s) do not have assigned Observers'),
          type: 'info',
        })
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [recipientsObserversData, recipientsObserversDataLoading, recipientsObserversError])

  // @ts-expect-error TS7006 (typescriptify)
  const getContextName = contextId => {
    const courseOptions = [
      props.courses?.favoriteCoursesConnection?.nodes,
      props.courses?.favoriteGroupsConnection.nodes,
    ]

    // @ts-expect-error TS7006 (typescriptify)
    const mergeOptions = lists => {
      // @ts-expect-error TS7006 (typescriptify)
      return lists.flatMap(list =>
        // @ts-expect-error TS7006 (typescriptify)
        list.map(option => ({
          assetString: option.assetString,
          contextName: option.contextName,
        })),
      )
    }

    const mergedOptions = mergeOptions(courseOptions)

    // @ts-expect-error TS7006 (typescriptify)
    return mergedOptions.find(item => item.assetString === contextId)?.contextName
  }

  useEffect(() => {
    if (
      (props.isReply || props.isForward) &&
      ['Course', 'Group'].includes(props.pastConversation?.contextType)
    ) {
      setSelectedContext({
        // @ts-expect-error TS2353 (typescriptify)
        contextID: props.pastConversation?.contextAssetString,
        contextName: props.pastConversation?.contextName,
      })
    } else if (props.contextIdFromUrl) {
      setSelectedContext({
        // @ts-expect-error TS2353 (typescriptify)
        contextID: props.contextIdFromUrl,
        contextName: getContextName(props.contextIdFromUrl),
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (!props.isReply && !props.isForward && props.activeCourseFilterID) {
      setSelectedContext({
        // @ts-expect-error TS2353 (typescriptify)
        contextID: props.activeCourseFilterID,
        contextName: getContextName(props.activeCourseFilterID),
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.courses, props.activeCourseFilterID, props.isForward, props.isReply])

  const getRecipientsObserver = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (selectedContext?.contextID) {
      getRecipientsObserversQuery({
        variables: {
          userID: ENV.current_user_id?.toString(),
          // @ts-expect-error TS2339 (typescriptify)
          contextCode: selectedContext?.contextID,
          // @ts-expect-error TS7006 (typescriptify)
          recipientIds: props.selectedIds.map(rec => rec?._id || rec.id),
        },
      })
    }
  }
  // @ts-expect-error TS7006 (typescriptify)
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

  // @ts-expect-error TS7006 (typescriptify)
  const addAttachment = async e => {
    const files = Array.from(e.currentTarget?.files)
    if (!files.length) {
      setOnFailure(I18n.t('Error adding files to conversation message'))
      return
    }

    const newAttachmentsToUpload = files.map((file, i) => {
      // @ts-expect-error TS18046 (typescriptify)
      return {isLoading: true, id: file.url ? `${i}-${file.url}` : `${i}-${file.name}`}
    })

    // @ts-expect-error TS2769 (typescriptify)
    setAttachmentsToUpload(prev => prev.concat(newAttachmentsToUpload))
    setOnSuccess(I18n.t('Uploading files'))

    try {
      const newFiles = await uploadFiles(files, '/files/pending', {conversations: true})
      // @ts-expect-error TS2769 (typescriptify)
      setAttachments(prev => prev.concat(newFiles))
    } catch (err) {
      setOnFailure(I18n.t('Error uploading files'))
    } finally {
      setAttachmentsToUpload(prev => {
        const attachmentsStillUploading = prev.filter(
          file => !newAttachmentsToUpload.includes(file),
        )
        return attachmentsStillUploading
      })
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  const removeAttachment = id => {
    setAttachments(prev => {
      // @ts-expect-error TS2339 (typescriptify)
      const index = prev.findIndex(attachment => attachment.id === id)
      prev.splice(index, 1)
      return [...prev]
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  const replaceAttachment = async (id, e) => {
    removeAttachment(id)
    addAttachment(e)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const onSubjectChange = value => {
    setSubject(value.currentTarget.value)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const onBodyChange = value => {
    if (value) {
      setBodyMessages([])
    }
  }

  const onSendIndividualMessagesChange = () => {
    setSendIndividualMessages(prev => !prev)
  }

  // if maxGroupRecipientsMet, change individual message setting to true
  useEffect(() => {
    if (props.maxGroupRecipientsMet) {
      setSendIndividualMessages(true)
    }
  }, [props.maxGroupRecipientsMet])

  // @ts-expect-error TS7006 (typescriptify)
  const onContextSelect = context => {
    if (context && context?.contextID) {
      setCourseMessages([])
    }
    props.onSelectedIdsChange([])
    // @ts-expect-error TS2353 (typescriptify)
    setSelectedContext({contextID: context.contextID, contextName: context.contextName})
  }

  const validMessageFields = () => {
    let isValid = true
    const errors = [] // Initialize an array to collect errors

    if (!body) {
      const errorMessage = I18n.t('Please insert a message')
      // @ts-expect-error TS2322 (typescriptify)
      setBodyMessages([{text: errorMessage, type: 'newError'}])
      errors.push(errorMessage) // Add error message to the array
      isValid = false
    }

    if (!isSubmissionCommentsType) {
      if (addressBookInputValue !== '') {
        const errorMessage = I18n.t('No matches found. Please insert a valid recipient.')
        // @ts-expect-error TS2322 (typescriptify)
        setAddressBookMessages([{text: errorMessage, type: 'newError'}])
        errors.push(errorMessage) // Add error message to the array
        isValid = false
      } else if (props.selectedIds.length === 0) {
        const errorMessage = I18n.t('Please select a recipient')
        // @ts-expect-error TS2322 (typescriptify)
        setAddressBookMessages([{text: errorMessage, type: 'newError'}])
        errors.push(errorMessage) // Add error message to the array
        isValid = false
      }
    }

    if (!isSubmissionCommentsType && !props.isReply && !props.isForward) {
      if (
        // @ts-expect-error TS2339 (typescriptify)
        !ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT &&
        // @ts-expect-error TS2339 (typescriptify)
        (!selectedContext || !selectedContext?.contextID)
      ) {
        const errorMessage = I18n.t('Please select a course')
        // @ts-expect-error TS2322 (typescriptify)
        setCourseMessages([{text: errorMessage, type: 'newError'}])
        errors.push(errorMessage) // Add error message to the array
        isValid = false
      }
    }

    // Aggregate errors and output to the screen reader
    if (errors.length > 0) {
      setOnFailure(errors.join(', '), true)
    }

    return isValid
  }

  // @ts-expect-error TS7006 (typescriptify)
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
          body,
        },
      })
    } else if (props.isReply) {
      await props.addConversationMessage({
        variables: {
          // @ts-expect-error TS2339 (typescriptify)
          attachmentIds: attachments.map(a => a.id),
          body,
          includedMessages: props.pastConversation?.conversationMessagesConnection.nodes.map(
            // @ts-expect-error TS7006 (typescriptify)
            c => c._id,
          ),
          // @ts-expect-error TS2339 (typescriptify)
          mediaCommentId: mediaUploadFile?.mediaObject?.media_object?.media_id,
          // @ts-expect-error TS2339 (typescriptify)
          mediaCommentType: mediaUploadFile?.mediaObject?.media_object?.media_type,
        },
      })
    } else if (props.isForward) {
      await props.addConversationMessage({
        variables: {
          // @ts-expect-error TS2339 (typescriptify)
          attachmentIds: attachments.map(a => a.id),
          body,
          includedMessages: props.pastConversation?.conversationMessagesConnection.nodes.map(
            // @ts-expect-error TS7006 (typescriptify)
            c => c._id,
          ),
          // @ts-expect-error TS7006 (typescriptify)
          recipients: props.selectedIds.map(rec => rec?._id || rec.id),
          // @ts-expect-error TS2339 (typescriptify)
          mediaCommentId: mediaUploadFile?.mediaObject?.media_object?.media_id,
          // @ts-expect-error TS2339 (typescriptify)
          mediaCommentType: mediaUploadFile?.mediaObject?.media_object?.media_type,
          // @ts-expect-error TS2339 (typescriptify)
          contextCode: ENV.CONVERSATIONS.ACCOUNT_CONTEXT_CODE,
        },
      })
    } else {
      const hideIndividualMessageCheckbox =
        ENV?.FEATURES?.restrict_student_access &&
        // @ts-expect-error TS2339 (typescriptify)
        ENV?.current_user_has_teacher_enrollment &&
        !(ENV?.current_user_roles || []).includes('student')

      await props.createConversation({
        variables: {
          // @ts-expect-error TS2339 (typescriptify)
          attachmentIds: attachments.map(a => a.id),
          bulkMessage: hideIndividualMessageCheckbox ? true : sendIndividualMessages,
          body,
          // @ts-expect-error TS2339 (typescriptify)
          contextCode: selectedContext?.contextID || ENV?.CONVERSATIONS?.ACCOUNT_CONTEXT_CODE,
          // @ts-expect-error TS7006 (typescriptify)
          recipients: props.selectedIds.map(rec => rec?._id || rec.id),
          subject,
          groupConversation: true,
          // @ts-expect-error TS2339 (typescriptify)
          mediaCommentId: mediaUploadFile?.mediaObject?.media_object?.media_id,
          // @ts-expect-error TS2339 (typescriptify)
          mediaCommentType: mediaUploadFile?.mediaObject?.media_object?.media_type,
        },
      })
    }
  }

  const resetState = () => {
    setAttachments([])
    setAttachmentsToUpload([])
    // @ts-expect-error TS2345 (typescriptify)
    setBody(null)
    setBodyMessages([])
    setAddressBookMessages([])
    // @ts-expect-error TS2345 (typescriptify)
    setSelectedContext(null)
    setCourseMessages([])
    props.onSelectedIdsChange([])
    props.setSendingMessage(false)
    // @ts-expect-error TS2345 (typescriptify)
    setSubject(null)
    setSendIndividualMessages(false)
    setMediaUploadFile(null)
  }

  const dismiss = () => {
    resetState()
    props.onDismiss()
  }

  const loadInboxSettingsSpinner = () => (
    <ModalSpinner
      label={I18n.t('Loading Inbox Settings')}
      message={I18n.t('Loading Inbox Settings')}
      onExited={() => {}}
    />
  )

  if (inboxSettingsLoading) return loadInboxSettingsSpinner()

  const shouldShowModalSpinner =
    props.sendingMessage && !attachmentsToUpload.length && !uploadingMediaFile

  return (
    <>
      <Responsive
        match="media"
        // @ts-expect-error TS2769 (typescriptify)
        query={responsiveQuerySizes({mobile: true, desktop: true})}
        props={{
          mobile: {
            modalSize: 'fullscreen',
            dataTestId: 'compose-modal-mobile',
          },
          desktop: {
            modalSize: 'medium',
            dataTestId: 'compose-modal-desktop',
          },
        }}
        render={responsiveProps => (
          <TranslationContext.Provider value={contextValues}>
            <Modal
              open={props.open}
              onDismiss={props.onDismiss}
              // @ts-expect-error TS18049 (typescriptify)
              size={responsiveProps.modalSize}
              label={I18n.t('Compose Message')}
              shouldCloseOnDocumentClick={false}
              onExited={resetState}
              // @ts-expect-error TS18049 (typescriptify)
              data-testid={responsiveProps.dataTestId}
              id="compose-message-modal"
            >
              <ModalHeader onDismiss={dismiss} headerTitle={props?.submissionCommentsHeader} />
              <ModalBody
                attachments={[...attachments, ...attachmentsToUpload]}
                bodyMessages={bodyMessages}
                onBodyChange={onBodyChange}
                pastMessages={props.pastConversation?.conversationMessagesConnection.nodes}
                removeAttachment={removeAttachment}
                replaceAttachment={replaceAttachment}
                modalError={props.modalError}
                mediaUploadFile={mediaUploadFile}
                onRemoveMediaComment={onRemoveMedia}
                signature={activeSignature}
                inboxSignatureBlock={props.inboxSignatureBlock}
              >
                {isSubmissionCommentsType ? null : (
                  <HeaderInputs
                    activeCourseFilter={selectedContext}
                    contextName={props.pastConversation?.contextName}
                    courses={props.courses}
                    selectedRecipients={props.selectedIds}
                    maxGroupRecipientsMet={props.maxGroupRecipientsMet}
                    isReply={props.isReply}
                    isForward={props.isForward}
                    onContextSelect={onContextSelect}
                    onSelectedIdsChange={onSelectedIdsChange}
                    onSendIndividualMessagesChange={onSendIndividualMessagesChange}
                    onSubjectChange={onSubjectChange}
                    onAddressBookInputValueChange={setAddressBookInputValue}
                    sendIndividualMessages={sendIndividualMessages}
                    subject={
                      props.isReply || props.isForward ? props.pastConversation?.subject : subject
                    }
                    addressBookMessages={addressBookMessages}
                    courseMessages={courseMessages}
                    data-testid="compose-modal-inputs"
                    isPrivateConversation={props.isPrivateConversation}
                    selectedContext={selectedContext}
                    getRecipientsObserver={getRecipientsObserver}
                    areObserversLoading={loadingObservers}
                    includeObserversMessages={includeObserversMessages}
                    setIncludeObserversMessages={setIncludeObserversMessages}
                  />
                )}
              </ModalBody>
              <Modal.Footer>
                <ComposeActionButtons
                  onAttachmentUpload={addAttachment}
                  onMediaUpload={() => setMediaUploadOpen(true)}
                  onCancel={dismiss}
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
          </TranslationContext.Provider>
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
        rcsConfig={{
          contextId: ENV.current_user_id,
          contextType: 'user',
        }}
        userLocale={ENV.LOCALE}
      />

      {shouldShowModalSpinner && (
        // @ts-expect-error TS2741 (typescriptify)
        <ModalSpinner label={I18n.t('Sending Message')} message={I18n.t('Sending Message')} />
      )}
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
  contextIdFromUrl: PropTypes.string,
  maxGroupRecipientsMet: PropTypes.bool,
  submissionCommentsHeader: PropTypes.string,
  modalError: PropTypes.string,
  setModalError: PropTypes.func,
  isPrivateConversation: PropTypes.bool,
  activeCourseFilterID: PropTypes.string,
  inboxSignatureBlock: PropTypes.bool,
}
