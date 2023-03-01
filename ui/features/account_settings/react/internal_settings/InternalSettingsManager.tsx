// @ts-nocheck
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useMutation} from 'react-apollo'
import React, {useContext, useEffect, useState} from 'react'
import {
  CreateInternalSettingData,
  CreateInternalSettingVariables,
  DeleteInternalSettingData,
  InternalSetting,
  InternalSettingMutationVariables,
  UpdateInternalSettingData,
  UpdateInternalSettingVariables,
} from './types'
import {InternalSettingsTable} from './table/InternalSettingsTable'
import {Portal} from '@instructure/ui-portal'
import {Mask} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Dialog} from '@instructure/ui-dialog'
import {Heading} from '@instructure/ui-heading'
import {
  DELETE_INTERNAL_SETTING_MUTATION,
  UPDATE_INTERNAL_SETTING_MUTATION,
  CREATE_INTERNAL_SETTING_MUTATION,
} from './graphql/Mutations'

const I18n = useI18nScope('internal-settings')

const preventNavigationHandler = (e: BeforeUnloadEvent) => {
  e.preventDefault()
  e.returnValue = ''
  return ''
}

export const InternalSettingsManager = (props: {internalSettings: InternalSetting[]}) => {
  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)

  const [pendingChanges, setPendingChanges] = useState<{[id: string]: string}>({})
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null)
  const [pendingNewInternalSetting, setPendingNewInternalSetting] = useState<{
    name?: string
    value?: string
  } | null>(null)

  const [updateInternalSetting] = useMutation<
    UpdateInternalSettingData,
    UpdateInternalSettingVariables
  >(UPDATE_INTERNAL_SETTING_MUTATION)
  const [deleteInternalSetting] = useMutation<
    DeleteInternalSettingData,
    InternalSettingMutationVariables
  >(DELETE_INTERNAL_SETTING_MUTATION, {refetchQueries: ['GetInternalSettings']})
  const [createInternalSetting] = useMutation<
    CreateInternalSettingData,
    CreateInternalSettingVariables
  >(CREATE_INTERNAL_SETTING_MUTATION, {refetchQueries: ['GetInternalSettings']})

  const submitPendingChange = (id: string) => {
    updateInternalSetting({variables: {internalSettingId: id, value: pendingChanges[id]}})
      .then(result => {
        if (result.errors?.length || !result.data || result.data.errors) {
          setOnFailure(I18n.t('Failed to update internal setting'))
        } else {
          clearPendingChange(result.data.updateInternalSetting.internalSetting.id)
          setOnSuccess(I18n.t('Internal setting updated'))
        }
      })
      .catch(() => setOnFailure(I18n.t('Failed to update internal setting')))
  }

  const submitDelete = (id: string) => {
    deleteInternalSetting({variables: {internalSettingId: id}})
      .then(result => {
        if (result.errors?.length || !result.data || result.data.errors) {
          setOnFailure(I18n.t('Failed to delete internal setting'))
        } else {
          setOnSuccess(I18n.t('Internal setting deleted'))
        }
      })
      .catch(() => setOnFailure(I18n.t('Failed to delete internal setting')))
  }

  const submitNew = (name: string, value: string) => {
    if (props.internalSettings.findIndex(is => is.name === name) !== -1) {
      setOnFailure(I18n.t(`A setting with the name "%{name}" already exists.`, {name}))
      return
    }

    createInternalSetting({variables: {name, value}})
      .then(result => {
        if (result.errors?.length || !result.data || result.data.errors) {
          setOnFailure(I18n.t('Failed to create internal setting'))
        } else {
          clearPendingNewInternalSetting()
          setOnSuccess(I18n.t('Internal setting created'))
        }
      })
      .catch(() => setOnFailure(I18n.t('Failed to create internal setting')))
  }

  const addPendingChange = (id: string, newValue: string) => {
    setPendingChanges({...pendingChanges, [id]: newValue})
  }

  const clearPendingChange = (id: string) => {
    const {[id]: _, ...newPendingChanges} = pendingChanges
    setPendingChanges(newPendingChanges)
  }

  const confirmDeleteInternalSetting = () => {
    if (!pendingDeleteId) return

    submitDelete(pendingDeleteId)
    setPendingDeleteId(null)
  }

  const cancelDeleteInternalSetting = () => setPendingDeleteId(null)

  const clearPendingNewInternalSetting = () => setPendingNewInternalSetting(null)

  const handleSubmitNewInternalSetting = () => {
    if (!pendingNewInternalSetting?.name) return

    submitNew(pendingNewInternalSetting.name, pendingNewInternalSetting.value || '')
  }

  // Prevent accidental navigation when setting changes are pending
  useEffect(() => {
    if (Object.keys(pendingChanges).length) {
      window.addEventListener('beforeunload', preventNavigationHandler)
    } else {
      window.removeEventListener('beforeunload', preventNavigationHandler)
    }

    return () => {
      window.removeEventListener('beforeunload', preventNavigationHandler)
    }
  }, [pendingChanges])

  return (
    <div>
      <InternalSettingsTable
        internalSettings={props.internalSettings}
        pendingChanges={pendingChanges}
        pendingNewInternalSetting={pendingNewInternalSetting || undefined}
        onValueChange={addPendingChange}
        onClearPendingChange={clearPendingChange}
        onSubmitPendingChange={submitPendingChange}
        onDelete={setPendingDeleteId}
        onSetPendingNewInternalSetting={internalSetting =>
          setPendingNewInternalSetting({...pendingNewInternalSetting, ...internalSetting})
        }
        onClearPendingNewInternalSetting={clearPendingNewInternalSetting}
        onSubmitPendingNewInternalSetting={handleSubmitNewInternalSetting}
      />
      <Portal open={!!pendingDeleteId}>
        <Mask>
          <Dialog
            open={!!pendingDeleteId}
            shouldContainFocus={true}
            defaultFocusElement={() => {}}
            shouldReturnFocus={true}
            onDismiss={cancelDeleteInternalSetting}
          >
            <View
              as="div"
              maxWidth="40rem"
              maxHeight="30rem"
              background="primary"
              shadow="above"
              style={{position: 'relative'}}
              padding="medium"
            >
              <CloseButton
                placement="end"
                onClick={cancelDeleteInternalSetting}
                screenReaderLabel={I18n.t('Close')}
              />
              <Heading level="h2">{I18n.t('Confirm setting deletion')}</Heading>
              <p>{I18n.t('Are you sure you want to delete this setting?')}</p>
              <div style={{display: 'flex', justifyContent: 'right'}}>
                <Button margin="auto x-small" onClick={cancelDeleteInternalSetting}>
                  {I18n.t('Cancel')}
                </Button>
                <Button margin="auto x-small" color="danger" onClick={confirmDeleteInternalSetting}>
                  YOLO
                </Button>
              </div>
            </View>
          </Dialog>
        </Mask>
      </Portal>
    </div>
  )
}
