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
import {useScope as useI18nScope} from '@canvas/i18n'
import {func, number, shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {showFlashAlert, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import GroupMembershipInput from './GroupMembershipInput'

const I18n = useI18nScope('groups')

GroupModal.propTypes = {
  groupCategory: shape({id: string}),
  group: shape({
    id: string,
    group_category_id: string,
    name: string,
    join_level: string,
    role: string,
    group_limit: number,
    members_count: number,
  }),
  onSave: func.isRequired,
  requestMethod: string.isRequired,
}

export default function GroupModal({groupCategory, group, onSave, requestMethod, ...modalProps}) {
  const [name, setName] = useState('')
  const [groupLimit, setGroupLimit] = useState('')
  const [joinLevel, setJoinLevel] = useState('')
  const [status, setStatus] = useState(null)

  useEffect(() => {
    if (group.name) setName(group.name)
    if (group.group_limit) setGroupLimit(group.group_limit)
    if (group.join_level) setJoinLevel(group.join_level)
    if (!modalProps.open) resetState()
  }, [group.name, group.group_limit, group.join_level, modalProps.open])

  const isNameOnly = modalProps.nameOnly ? modalProps.nameOnly : false
  const isStudentGroup = group.role ? group.role === 'student_organized' : false
  const groupCategoryId = groupCategory ? groupCategory.id : group.group_category_id

  const payload = () => {
    if (isStudentGroup) {
      return {
        group_category_id: groupCategoryId,
        join_level: joinLevel || 'invitation_only',
        name,
      }
    } else {
      return {
        group_category_id: groupCategoryId,
        isFull: '',
        max_membership: groupLimit ? groupLimit.toString() : '',
        name,
      }
    }
  }

  function validateBeforeSend() {
    // prefer undefined over null as a fallback for the following
    // comparison to evaluate properly given a group members count
    const groupMembershipLimit = groupLimit ? parseInt(groupLimit, 10) : undefined
    if (groupMembershipLimit < group.members_count) {
      showFlashAlert({
        type: 'error',
        message: I18n.t(
          'Group membership limit must be equal to or greater than current members count.'
        ),
      })
    } else if (groupMembershipLimit === 1) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('Group membership limit must be greater than 1.'),
      })
    } else {
      handleSend()
    }
  }

  function handleSend() {
    setStatus('info')
    startSendOperation()
      .then(notifyDidSave)
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        if (err.response) console.error(err.response) // eslint-disable-line no-console
        setStatus('error')
      })
  }

  function startSendOperation() {
    const path =
      requestMethod === 'POST'
        ? `/api/v1/group_categories/${groupCategoryId}/groups`
        : `/api/v1/groups/${group.id}`
    return doFetchApi({
      method: requestMethod,
      path,
      body: payload(),
    })
  }

  function notifyDidSave() {
    showFlashSuccess(I18n.t('Group saved successfully'))()
    modalProps.onDismiss()
    onSave()
  }

  function resetState() {
    setName('')
    setGroupLimit('')
    setStatus(null)
  }

  function Footer() {
    const saveButtonState = name.length === 0 || status === 'info' ? 'disabled' : 'enabled'
    return (
      <>
        <Button onClick={modalProps.onDismiss}>{I18n.t('Cancel')}</Button>
        <Button
          type="submit"
          interaction={saveButtonState}
          color="primary"
          margin="0 0 0 x-small"
          onClick={validateBeforeSend}
        >
          {I18n.t('Save')}
        </Button>
      </>
    )
  }

  let alertMessage = ''
  if (status === 'info') alertMessage = I18n.t('Saving group')
  else if (status === 'error') alertMessage = I18n.t('An error occurred when saving the group.')

  const alert = alertMessage ? (
    <Alert variant={status}>
      <div role="alert" aria-live="assertive" aria-atomic={true}>
        {alertMessage}
      </div>
      {status === 'info' ? <Spinner renderTitle={alertMessage} size="x-small" /> : null}
    </Alert>
  ) : null

  const groupOptions = isStudentGroup ? (
    <SimpleSelect
      renderLabel={I18n.t('Joining')}
      defaultValue="invitation_only"
      value={joinLevel}
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
    <GroupMembershipInput onChange={setGroupLimit} value={groupLimit.toString()} />
  )

  return (
    <CanvasModal
      size="small"
      shouldCloseOnDocumentClick={false}
      footer={<Footer />}
      {...modalProps}
    >
      {alert}
      <FormFieldGroup
        description={<ScreenReaderContent>{modalProps.label}</ScreenReaderContent>}
        layout="stacked"
        rowSpacing="large"
      >
        <TextInput
          id="group_name"
          renderLabel={I18n.t('Group Name')}
          placeholder={I18n.t('Name')}
          value={name}
          onChange={(_event, value) => setName(value)}
          isRequired={true}
        />
        {isNameOnly ? null : groupOptions}
      </FormFieldGroup>
    </CanvasModal>
  )
}
