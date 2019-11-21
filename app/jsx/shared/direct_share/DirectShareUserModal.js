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

import I18n from 'i18n!direct_share_user_modal'
import React, {Suspense, lazy, useState, useRef} from 'react'
import {oneOf, shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import CanvasModal from 'jsx/shared/components/CanvasModal'
import {CONTENT_SHARE_TYPES} from 'jsx/shared/proptypes/contentShare'
import doFetchApi from 'jsx/shared/effects/doFetchApi'

const DirectShareUserPanel = lazy(() => import('./DirectShareUserPanel'))

DirectShareUserModal.propTypes = {
  contentShare: shape({
    content_id: string,
    content_type: oneOf(CONTENT_SHARE_TYPES)
  }),
  courseId: string
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
        receiver_ids: selectedUsers.map(user => user.id)
      }
    })
  }

  function handleSend() {
    setPostStatus('info')
    startSendOperation()
      .then(() => setPostStatus('success'))
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        if (err.response) console.error(err.response) // eslint-disable-line no-console
        setPostStatus('error')
      })
  }

  function Footer() {
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          disabled={selectedUsers.length === 0 || postStatus !== null}
          variant="primary"
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
      <Spinner renderTitle={I18n.t('Loading...')} />
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
  else if (postStatus === 'success') alertMessage = I18n.t('Content share started successfully')
  else if (postStatus === 'error') alertMessage = I18n.t('Error starting content share')

  const alert = alertMessage ? (
    <Alert variant={postStatus}>
      <div role="alert" aria-live="assertive" aria-atomic>
        {alertMessage}
      </div>
      {postStatus === 'info' ? <Spinner renderTitle="" size="x-small" /> : null}
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
