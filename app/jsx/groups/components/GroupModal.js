/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import I18n from 'i18n!groups'
import {func, number, shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {showFlashSuccess} from 'jsx/shared/FlashAlert'
import CanvasModal from 'jsx/shared/components/CanvasModal'
import doFetchApi from 'jsx/shared/effects/doFetchApi'
import GroupMembershipInput from './GroupMembershipInput'

GroupModal.propTypes = {
  groupCategory: shape({
    id: string,
    role: string,
    group_limit: number
  }),
  onSave: func
}

export default function GroupModal({groupCategory, onSave, ...modalProps}) {
  const [name, setName] = useState('')
  const [groupLimit, setGroupLimit] = useState('')
  const [joinLevel, setJoinLevel] = useState('')
  const [postStatus, setPostStatus] = useState(null)

  useEffect(() => {
    if (!modalProps.open) resetState()
  }, [modalProps.open])

  const isStudentGroup = groupCategory.role ? groupCategory.role === 'student_organized' : false
  let payload
  if (isStudentGroup) {
    payload = {
      group_category_id: groupCategory.id,
      join_level: joinLevel || 'invitation_only',
      name
    }
  } else {
    payload = {
      group_category_id: groupCategory.id,
      isFull: '',
      max_membership: (groupLimit ? groupLimit.toString() : null) || groupCategory.group_limit,
      name
    }
  }

  function resetState() {
    setName('')
    setGroupLimit('')
    setPostStatus(null)
  }

  function startSendOperation() {
    return doFetchApi({
      method: 'POST',
      path: `/api/v1/group_categories/${groupCategory.id}/groups`,
      body: payload
    })
  }

  function handleSend() {
    setPostStatus('info')
    startSendOperation()
      .then(notifyDidCreate)
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        if (err.response) console.error(err.response) // eslint-disable-line no-console
        setPostStatus('error')
      })
  }

  function notifyDidCreate() {
    showFlashSuccess(I18n.t('Group created successfully'))()
    modalProps.onDismiss()
    onSave()
  }

  function Footer() {
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          type="submit"
          disabled={name.length === 0 || postStatus === 'info'}
          color="primary"
          margin="0 0 0 x-small"
          onClick={handleSend}
        >
          {I18n.t('Save')}
        </Button>
      </>
    )
  }

  let alertMessage = ''
  if (postStatus === 'info') alertMessage = I18n.t('Creating group')
  else if (postStatus === 'error') alertMessage = I18n.t('Error during group creation')

  const alert = alertMessage ? (
    <Alert variant={postStatus}>
      <div role="alert" aria-live="assertive" aria-atomic>
        {alertMessage}
      </div>
      {postStatus === 'info' ? <Spinner renderTitle={alertMessage} size="x-small" /> : null}
    </Alert>
  ) : null

  return (
    <CanvasModal
      label={I18n.t('Add Group')}
      size="small"
      shouldCloseOnDocumentClick={false}
      footer={<Footer />}
      {...modalProps}
    >
      {alert}
      <FormFieldGroup
        description={<ScreenReaderContent>{I18n.t('Add Group')}</ScreenReaderContent>}
        layout="stacked"
        rowSpacing="large"
      >
        <TextInput
          id="group_name"
          renderLabel={I18n.t('Group Name')}
          placeholder={I18n.t('Name')}
          onChange={(_event, value) => setName(value)}
          isRequired
        />
        {isStudentGroup ? (
          <SimpleSelect
            renderLabel={I18n.t('Joining')}
            defaultValue="invitation_only"
            onChange={(_event, data) => setJoinLevel(data.value)}
          >
            <SimpleSelect.Option id="invitation_only" value="invitation_only">
              {I18n.t('Invitation Only')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="parent_context_auto_join" value="parent_context_auto_join">
              {I18n.t('Members are free to join')}
            </SimpleSelect.Option>
          </SimpleSelect>
        ) : (
          <GroupMembershipInput onChange={setGroupLimit} value={groupLimit} />
        )}
      </FormFieldGroup>
    </CanvasModal>
  )
}
