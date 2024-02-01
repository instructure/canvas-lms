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
import {shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('groups')

GroupCategoryCloneModal.propTypes = {
  groupCategory: shape({
    id: string,
    name: string,
  }),
}

export default function GroupCategoryCloneModal({groupCategory, ...modalProps}) {
  const [name, setName] = useState('')
  const [status, setStatus] = useState(null)

  useEffect(() => {
    if (groupCategory.name)
      setName(I18n.t('(Clone) %{groupCategoryName}', {groupCategoryName: groupCategory.name}))
    if (!modalProps.open) resetState()
  }, [groupCategory.name, modalProps.open])

  function handleSend() {
    setStatus('info')
    startSendOperation()
      .then(res => notifyDidSave(res))
      .catch(err => {
        console.error(err) // eslint-disable-line no-console
        captureException(err)
        if (err.response) console.error(err.response) // eslint-disable-line no-console
        setStatus('error')
      })
  }

  function startSendOperation() {
    const path = `/group_categories/${groupCategory.id}/clone_with_name`
    return doFetchApi({
      method: 'POST',
      path,
      body: {name},
    })
  }

  function refreshGroupSet(res) {
    window.location.hash = `#tab-${res.json.group_category.id}`
    window.location.reload()
  }

  function notifyDidSave(res) {
    showFlashSuccess(I18n.t('Group set cloned successfully'))()
    modalProps.onDismiss()
    refreshGroupSet(res)
  }

  function resetState() {
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
          onClick={handleSend}
        >
          {I18n.t('Submit')}
        </Button>
      </>
    )
  }

  let alertMessage = ''
  if (status === 'info') alertMessage = I18n.t('Cloning group set')
  else if (status === 'error')
    alertMessage = I18n.t('An error occurred when cloning the group set.')

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
      size="small"
      shouldCloseOnDocumentClick={false}
      footer={<Footer />}
      {...modalProps}
    >
      {alert}
      <TextInput
        id="cloned_category_name"
        renderLabel={I18n.t('Group Set Name')}
        placeholder={I18n.t('Name')}
        value={name}
        onChange={(_event, value) => setName(value)}
        isRequired={true}
      />
    </CanvasModal>
  )
}
