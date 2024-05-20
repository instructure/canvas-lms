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

import _ from 'lodash'
import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Tag} from '@instructure/ui-tag'
import {TextArea} from '@instructure/ui-text-area'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('groups')

GroupCategoryMessageAllUnassignedModal.propTypes = {
  groupCategory: shape({name: string.isRequired}),
  recipients: arrayOf(shape({id: string.isRequired, short_name: string.isRequired})),
  open: bool.isRequired,
  onDismiss: func.isRequired,
}

export default function GroupCategoryMessageAllUnassignedModal({
  groupCategory,
  recipients,
  ...modalProps
}) {
  const [message, setMessage] = useState('')
  const [status, setStatus] = useState(null)

  const contextAssetString = ENV.context_asset_string
  const chunkSize = ENV.MAX_GROUP_CONVERSATION_SIZE || 100

  const payload = {
    body: message,
    context_code: contextAssetString,
    recipients: recipients.map(user => user.id),
  }

  useEffect(() => {
    if (!modalProps.open) resetState()
  }, [modalProps.open])

  function resetState() {
    setMessage('')
    setStatus(null)
  }

  function handleSend() {
    setStatus('info')
    const chunks = _.chunk(payload.recipients, chunkSize)
    const promiseArray = []

    chunks.forEach(chunk => {
      const chunkData = {...payload, recipients: chunk}
      promiseArray.push(
        doFetchApi({
          method: 'POST',
          path: `/api/v1/conversations`,
          body: chunkData,
        })
      )
    })
    Promise.all(promiseArray)
      .then(notifyDidSave)
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        captureException(err)
        if (err.response) console.error(err.response) // eslint-disable-line no-console
        setStatus('error')
      })
  }

  function notifyDidSave() {
    showFlashSuccess(I18n.t('Message Sent!'))()
    modalProps.onDismiss()
  }

  function renderSelectedUserTags() {
    return recipients.map(user => <Tag key={user.id} text={user.short_name} margin="xxx-small" />)
  }

  function Footer() {
    const sendButtonState = message.length === 0 || status === 'info' ? 'disabled' : 'enabled'
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          type="submit"
          interaction={sendButtonState}
          color="primary"
          margin="0 0 0 x-small"
          onClick={handleSend}
        >
          {I18n.t('Send Message')}
        </Button>
      </>
    )
  }

  let alertMessage = ''
  if (status === 'info') alertMessage = I18n.t('Sending Message...')
  else if (status === 'error') alertMessage = I18n.t('Sending Message Failed, please try again')

  const alert = alertMessage ? (
    <Alert variant={status}>
      <div role="alert" aria-live="assertive" aria-atomic={true}>
        {alertMessage}
      </div>
      {status === 'info' ? <Spinner renderTitle={alertMessage} size="x-small" /> : null}
    </Alert>
  ) : null

  return (
    <CanvasModal
      label={I18n.t('Message students for %{groupCategoryName}', {
        groupCategoryName: groupCategory.name,
      })}
      size="medium"
      shouldCloseOnDocumentClick={false}
      footer={<Footer />}
      {...modalProps}
    >
      <FormFieldGroup
        description={I18n.t('Recipients: Students who have not joined a group')}
        layout="stacked"
        rowSpacing="small"
      >
        <Flex>
          <Flex.Item>{renderSelectedUserTags()}</Flex.Item>
        </Flex>
        <TextArea
          id="message_all_unassigned"
          label={
            <ScreenReaderContent>
              {I18n.t('Required input. Message all unassigned students.')}
            </ScreenReaderContent>
          }
          placeholder={I18n.t('Type message here...')}
          height="200px"
          value={message}
          onChange={e => setMessage(e.target.value)}
        />
      </FormFieldGroup>
      {alert}
    </CanvasModal>
  )
}
