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
import React, {Suspense, lazy, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import CanvasModal from 'jsx/shared/components/CanvasModal'

const DirectShareUserPanel = lazy(() => import('./DirectShareUserPanel'))

export default function DirectShareUserModal({...modalProps}) {
  const [selectedUsers, setSelectedUsers] = useState([])

  function handleUserSelected(newUser) {
    if (!selectedUsers.find(user => user.id === newUser.id)) {
      setSelectedUsers(selectedUsers.concat([newUser]))
    }
  }

  function handleUserRemoved(doomedUser) {
    setSelectedUsers(selectedUsers.filter(user => user.id !== doomedUser.id))
  }

  function handleDismiss() {
    setSelectedUsers([])
    modalProps.onDismiss()
  }

  function handleSend() {
    console.log('TODO: share content with users', selectedUsers)
  }

  function Footer() {
    return (
      <>
        <Button onClick={handleDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          disabled={selectedUsers.length === 0}
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

  // TODO: should show the title of item being shared
  return (
    <CanvasModal label={I18n.t('Send To...')} size="medium" {...modalProps} footer={<Footer />}>
      <Suspense fallback={suspenseFallback}>
        <DirectShareUserPanel
          selectedUsers={selectedUsers}
          onUserSelected={handleUserSelected}
          onUserRemoved={handleUserRemoved}
        />
      </Suspense>
    </CanvasModal>
  )
}
