/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Suspense, lazy, useState, useRef} from 'react'
import {oneOf, shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {CONTENT_SHARE_TYPES} from '@canvas/content-sharing/react/proptypes/contentShare'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('direct_share_user_modal')

const DirectShareUserPanel = lazy(() => import('./DirectShareUserPanel'))

DirectShareUserModal.propTypes = {
  contentShare: shape({
    content_id: string,
    content_type: oneOf(CONTENT_SHARE_TYPES),
  }),
  courseId: string,
}

export default function DirectShareUserModal({contentShare, courseId, ...modalProps}) {
  const [selectedUsers, setSelectedUsers] = useState([])
  const [postStatus, setPostStatus] = useState(null)
  const previousOpen = useRef(modalProps.open)

  function resetState() {
    setSelectedUsers([])
    setPostStatus(null)
  }

  function handleUserSelected(newUser) {
    if (!selectedUsers.find(user => user.id === newUser.id)) {
      setSelectedUsers(selectedUsers.concat([newUser]))
    }
  }

  function handleUserRemoved(doomedUser) {
    setSelectedUsers(selectedUsers.filter(user => user.id !== doomedUser.id))
  }

  function startSendOperation() {
    return doFetchApi({
      method: 'POST',
      path: '/api/v1/users/self/content_shares',
      body: {
        ...contentShare,
        receiver_ids: selectedUsers.map(user => user.id),
      },
    })
  }

  function handleSend() {
    setPostStatus('info')
    startSendOperation()
      .then(sendSuccessful)
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        if (err.response) console.error(err.response) // eslint-disable-line no-console
        setPostStatus('error')
        captureException(err)
      })
  }

  function sendSuccessful() {
    showFlashSuccess(I18n.t('Content share started successfully'))()
    modalProps.onDismiss()
  }

  function Footer() {
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          disabled={selectedUsers.length === 0 || postStatus === 'info'}
          color="primary"
          margin="0 0 0 x-small"
          onClick={handleSend}
        >
          {I18n.t('Send')}
        </Button>
      </>
    )
  }

  const suspenseFallback = (
    <View as="div" textAlign="center">
      <Spinner renderTitle={I18n.t('Loading')} />
    </View>
  )

  // Reset the state when the open prop changes so we don't carry over state
  // from the previously opened dialog
  if (modalProps.open !== previousOpen.current) {
    previousOpen.current = modalProps.open
    resetState()
  }

  let alertMessage = ''
  if (postStatus === 'info') alertMessage = I18n.t('Starting content share')
  else if (postStatus === 'error') alertMessage = I18n.t('Error starting content share')

  const alert = alertMessage ? (
    <Alert variant={postStatus}>
      <div role="alert" aria-live="assertive" aria-atomic={true}>
        {alertMessage}
      </div>
      {postStatus === 'info' ? <Spinner renderTitle={alertMessage} size="x-small" /> : null}
    </Alert>
  ) : null

  // TODO: should show the title of item being shared
  return (
    <CanvasModal label={I18n.t('Send To...')} size="medium" {...modalProps} footer={<Footer />}>
      <Suspense fallback={suspenseFallback}>
        {alert}
        <DirectShareUserPanel
          courseId={courseId}
          selectedUsers={selectedUsers}
          onUserSelected={handleUserSelected}
          onUserRemoved={handleUserRemoved}
        />
      </Suspense>
    </CanvasModal>
  )
}
