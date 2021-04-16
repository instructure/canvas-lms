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

import I18n from 'i18n!k5_dashboard'
import React, {useState} from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton, Button} from '@instructure/ui-buttons'
import {IconEmailLine} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {readableRoleName, sendMessage} from '@canvas/k5/react/utils'
import {Avatar} from '@instructure/ui-avatar'
import PropTypes from 'prop-types'
import {Heading} from '@instructure/ui-heading'
import {TextArea} from '@instructure/ui-text-area'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Spinner} from '@instructure/ui-spinner'

export default function StaffInfo({
  id,
  name,
  bio,
  avatarUrl = '/images/messages/avatar-50.png',
  role
}) {
  const [isModalOpen, setModalOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [subject, setSubject] = useState('')
  const [isSending, setSending] = useState(false)

  const handleSend = () => {
    setSending(true)
    sendMessage(id, message, subject || null)
      .then(_data => {
        showFlashSuccess(I18n.t('Message to %{name} sent.', {name}))()
        setMessage('')
        setSubject('')
        setModalOpen(false)
        setSending(false)
      })
      .catch(err => {
        showFlashError(I18n.t('Failed sending message.'))(err)
        setSending(false)
      })
  }

  const allowMessaging = () => ENV.current_user_id !== id

  return (
    <View>
      <Flex>
        <Flex.Item align="start">
          <Avatar name={name} src={avatarUrl} alt={I18n.t('Avatar for %{name}', {name})} />
        </Flex.Item>
        <Flex.Item shouldGrow padding="0 small">
          <Heading level="h3">{name}</Heading>
          <Text as="div" size="small" data-automation="instructor-role">
            {readableRoleName(role)}
          </Text>
          {bio && (
            <Text as="div" data-automation="instructor-bio">
              {bio}
            </Text>
          )}
        </Flex.Item>
        {allowMessaging() && (
          <Flex.Item>
            <IconButton
              screenReaderLabel={I18n.t('Send a message to %{name}', {name})}
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={() => setModalOpen(true)}
            >
              <IconEmailLine />
            </IconButton>
          </Flex.Item>
        )}
      </Flex>
      <PresentationContent>
        <hr style={{margin: '0.8em 0'}} />
      </PresentationContent>

      {allowMessaging() && (
        <Modal
          label={I18n.t('Message %{name}', {name})}
          open={isModalOpen}
          size="small"
          onDismiss={() => setModalOpen(false)}
        >
          <Modal.Body>
            <FormFieldGroup
              description={<ScreenReaderContent>{I18n.t('Message Form')}</ScreenReaderContent>}
              layout="stacked"
              rowSpacing="medium"
            >
              <TextInput
                renderLabel={I18n.t('Subject')}
                placeholder={I18n.t('No subject')}
                value={subject}
                onChange={e => setSubject(e.target.value)}
              />
              <TextArea
                label={I18n.t('Message')}
                placeholder={I18n.t('Message')}
                value={message}
                onChange={e => setMessage(e.target.value)}
                height="8em"
                resize="vertical"
              />
            </FormFieldGroup>
          </Modal.Body>
          <Modal.Footer>
            <Button
              color="secondary"
              onClick={() => setModalOpen(false)}
              interaction={!isSending ? 'enabled' : 'disabled'}
            >
              {I18n.t('Cancel')}
            </Button>
            &nbsp;
            <Button
              color="primary"
              onClick={handleSend}
              interaction={message.length && !isSending ? 'enabled' : 'disabled'}
            >
              {I18n.t('Send')}
            </Button>
            {isSending && (
              <Spinner renderTitle={I18n.t('Sending message')} size="x-small" margin="small" />
            )}
          </Modal.Footer>
        </Modal>
      )}
    </View>
  )
}

export const StaffShape = {
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  bio: PropTypes.string,
  avatarUrl: PropTypes.string,
  role: PropTypes.string.isRequired
}

StaffInfo.propTypes = StaffShape
