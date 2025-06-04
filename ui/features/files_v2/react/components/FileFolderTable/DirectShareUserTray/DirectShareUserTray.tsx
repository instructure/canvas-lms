/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {createRef, Ref, useCallback, useEffect, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {BasicUser, ContentShareUserSearchSelectorRef} from './ContentShareUserSearchSelector'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {type File} from '../../../../interfaces/File'
import DirectShareUserPanel from './DirectShareUserPanel'
import {doFetchApiWithAuthCheck, UnauthorizedError} from '../../../../utils/apiUtils'
import FileFolderTray from '../../shared/TrayWrapper'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {getName} from '../../../../utils/fileFolderUtils'

const I18n = createI18nScope('files_v2')

export type DirectShareUserTrayProps = {
  open: boolean
  onDismiss: () => void
  courseId: string
  file: File
}

type DirectShareUserTrayBodyProps = {
  requestInFlight: boolean
  file: File
  courseId: string
  selectedUsers: BasicUser[]
  onUserSelected: (newUser?: BasicUser) => void
  onUserRemoved: (doomedUser: BasicUser) => void
  selectorRef: Ref<ContentShareUserSearchSelectorRef>
}

type DirectShareUserTrayFooterProps = {
  requestInFlight: boolean
  onDismiss: () => void
  onSend: () => void
}

const DirectShareUserTrayHeader = () => <Heading level="h3">{I18n.t('Send To...')}</Heading>

const DirectShareUserTrayBody = ({
  requestInFlight,
  file,
  courseId,
  selectedUsers,
  onUserSelected,
  onUserRemoved,
  selectorRef,
}: DirectShareUserTrayBodyProps) => {
  if (requestInFlight) {
    return (
      <View as="div" textAlign="center">
        <Spinner
          data-testid="send-to-spinner"
          renderTitle={I18n.t('Sending %{file}', {
            file: getName(file),
          })}
          margin="0 0 0 medium"
          aria-live="polite"
        />
      </View>
    )
  }

  return (
    <Flex direction="column">
      <Flex.Item padding="small">
        <FileFolderInfo items={[file]} />
      </Flex.Item>
      <Flex.Item padding="small">
        <DirectShareUserPanel
          selectorRef={selectorRef}
          courseId={courseId}
          selectedUsers={selectedUsers}
          onUserSelected={onUserSelected}
          onUserRemoved={onUserRemoved}
        />
      </Flex.Item>
    </Flex>
  )
}

const DirectShareUserTrayFooter = ({
  requestInFlight,
  onDismiss,
  onSend,
}: DirectShareUserTrayFooterProps) => (
  <>
    <Button data-testid="direct-share-user-cancel" disabled={requestInFlight} onClick={onDismiss}>
      {I18n.t('Cancel')}
    </Button>
    <Button
      data-testid="direct-share-user-send"
      disabled={requestInFlight}
      color="primary"
      margin="0 0 0 x-small"
      onClick={onSend}
    >
      {I18n.t('Send')}
    </Button>
  </>
)

const DirectShareUserTray = ({open, onDismiss, courseId, file}: DirectShareUserTrayProps) => {
  const selectorRef: Ref<ContentShareUserSearchSelectorRef> =
    createRef<ContentShareUserSearchSelectorRef>()
  const [selectedUsers, setSelectedUsers] = useState<BasicUser[]>([])
  const [requestInFlight, setRequestInFlight] = useState<boolean>(false)

  const resetState = useCallback(() => {
    setSelectedUsers([])
    setRequestInFlight(false)
  }, [])

  const handleUserSelected = useCallback(
    (newUser?: BasicUser) => {
      if (newUser && !selectedUsers.find(user => user.id === newUser.id)) {
        setSelectedUsers(selectedUsers.concat([newUser]))
      }
    },
    [selectedUsers],
  )

  const handleUserRemoved = useCallback(
    (doomedUser: BasicUser) => {
      setSelectedUsers(selectedUsers.filter(user => user.id !== doomedUser.id))
    },
    [selectedUsers],
  )

  const startSendOperation = useCallback(
    () =>
      doFetchApiWithAuthCheck({
        method: 'POST',
        path: '/api/v1/users/self/content_shares',
        body: {
          content_id: file.id,
          content_type: 'attachment',
          receiver_ids: selectedUsers.map(user => user.id),
        },
      }),
    [file.id, selectedUsers],
  )

  const sendSuccessful = useCallback(() => {
    showFlashSuccess(I18n.t('Send operation started successfully.'))()
    onDismiss()
  }, [onDismiss])

  const handleSend = useCallback(() => {
    if (!selectorRef.current?.validate()) return

    showFlashAlert({message: I18n.t('Starting send operation...')})
    setRequestInFlight(true)
    startSendOperation()
      .then(sendSuccessful)
      .catch(error => {
        if (error instanceof UnauthorizedError) {
          window.location.href = '/login'
          return
        }
        showFlashError(I18n.t('Error starting content share.'))(error)
      })
      .finally(() => setRequestInFlight(false))
  }, [selectorRef, sendSuccessful, startSendOperation])

  // Reset the state when the open prop changes so we don't carry over state
  // from the previously opened tray
  useEffect(() => {
    if (open) resetState()
  }, [open, resetState])

  return (
    <FileFolderTray
      closeLabel={I18n.t('Close')}
      label={I18n.t('Send To...')}
      onDismiss={onDismiss}
      open={open}
      header={<DirectShareUserTrayHeader />}
      footer={
        <DirectShareUserTrayFooter
          requestInFlight={requestInFlight}
          onDismiss={onDismiss}
          onSend={handleSend}
        />
      }
    >
      <DirectShareUserTrayBody
        requestInFlight={requestInFlight}
        file={file}
        courseId={courseId}
        selectedUsers={selectedUsers}
        onUserSelected={handleUserSelected}
        onUserRemoved={handleUserRemoved}
        selectorRef={selectorRef}
      />
    </FileFolderTray>
  )
}

export default DirectShareUserTray
