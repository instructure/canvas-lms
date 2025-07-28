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

import {ConversationMessage} from '../../../graphql/ConversationMessage'
import {MessageBody} from '../../components/MessageBody/MessageBody'
import {PastMessages} from '../../components/PastMessages/PastMessages'
import PropTypes from 'prop-types'
import React from 'react'

import {AttachmentDisplay, MediaAttachment} from '@canvas/message-attachments'
import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import TranslationControls from '../../components/TranslationControls/TranslationControls'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {ComposeInputWrapper} from '../../components/ComposeInputWrapper/ComposeInputWrapper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'

const {Item} = Flex

const I18n = createI18nScope('conversations_2')

const ModalBody = props => {
  const shouldTranslate = ENV?.inbox_translation_enabled
  const invalidBody = !!props.bodyMessages?.length

  return (
    <Modal.Body padding="none">
      {props.modalError && (
        <Alert margin="small" variant="error" timeout={2500}>
          {props.modalError}
        </Alert>
      )}
      <Flex direction="column" width="100%" height="100%">
        {props.children}
        <View borderWidth="small none none none" padding="x-small">
          <ComposeInputWrapper
            title={
              <PresentationContent>
                <Text>{I18n.t('Message')}</Text>
                <Text color={invalidBody ? 'danger' : 'primary'}>{' *'}</Text>
              </PresentationContent>
            }
            input={
              <MessageBody
                onBodyChange={props.onBodyChange}
                messages={props.bodyMessages}
                inboxSignatureBlock={props.inboxSignatureBlock}
                signature={props.signature}
              />
            }
          />
          {shouldTranslate && (
            <TranslationControls
              signature={props.signature}
              inboxSettingsFeature={props.inboxSettingsFeature}
            />
          )}
        </View>
        {props.pastMessages?.length > 0 && <PastMessages messages={props.pastMessages} />}
        <Flex alignItems="start" borderWidth="small none none none" padding="small">
          {props.mediaUploadFile && props.mediaUploadFile.uploadedFile && (
            <Item data-testid="media-attachment">
              <MediaAttachment
                file={{
                  mediaID: props.mediaUploadFile.mediaObject.media_object.media_id,
                  src: URL.createObjectURL(props.mediaUploadFile.uploadedFile),
                  title:
                    props.mediaUploadFile.mediaObject.media_object.user_entered_title ??
                    props.mediaUploadFile.mediaObject.media_object.title,
                  type: props.mediaUploadFile.mediaObject.media_object.media_type,
                  mediaTracks: props.mediaUploadFile.mediaObject.media_object.media_tracks,
                }}
                onRemoveMediaComment={props.onRemoveMediaComment}
              />
            </Item>
          )}

          <Item shouldShrink={true}>
            <AttachmentDisplay
              attachments={props.attachments}
              onReplaceItem={props.replaceAttachment}
              onDeleteItem={props.removeAttachment}
            />
          </Item>
        </Flex>
      </Flex>
    </Modal.Body>
  )
}

ModalBody.propTypes = {
  attachments: PropTypes.array,
  bodyMessages: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string,
      type: PropTypes.string,
    }),
  ),
  children: PropTypes.element,
  onBodyChange: PropTypes.func,
  pastMessages: PropTypes.arrayOf(ConversationMessage.shape),
  removeAttachment: PropTypes.func,
  replaceAttachment: PropTypes.func,
  modalError: PropTypes.string,
  mediaUploadFile: PropTypes.object,
  onRemoveMediaComment: PropTypes.func,
  inboxSignatureBlock: PropTypes.bool,
  signature: PropTypes.string,
}

export default ModalBody
