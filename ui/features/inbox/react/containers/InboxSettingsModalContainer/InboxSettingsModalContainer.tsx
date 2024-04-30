/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import React, {useState, useEffect} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import type {InboxSettings} from '../../../inboxModel'
import ModalSpinner from '../ComposeModalContainer/ModalSpinner'
import {INBOX_SETTINGS_QUERY} from '../../../graphql/Queries'
import {UPDATE_INBOX_SETTINGS} from '../../../graphql/Mutations'
import {useQuery, useMutation} from 'react-apollo'

const I18n = useI18nScope('conversations_2')

export interface Props {
  open: boolean
  onDismissWithAlert: (arg?: string) => void
}

export const SAVE_SETTINGS_OK = 'SAVE_SETTINGS_OK'
export const SAVE_SETTINGS_FAIL = 'SAVE_SETTINGS_FAIL'
export const LOAD_SETTINGS_FAIL = 'LOAD_SETTINGS_FAIL'
export const defaultInboxSettings: InboxSettings = {
  useSignature: false,
  signature: '',
  useOutOfOffice: false,
  outOfOfficeFirstDate: undefined,
  outOfOfficeLastDate: undefined,
  outOfOfficeSubject: '',
  outOfOfficeMessage: '',
}

const InboxSettingsModalContainer = ({open, onDismissWithAlert}: Props) => {
  const [formState, setFormState] = useState<InboxSettings>(defaultInboxSettings)
  const [validSignature, setValidSignature] = useState<boolean>(true)
  const [updateInboxSettings, {loading: updateInboxSettingsLoading}] =
    useMutation(UPDATE_INBOX_SETTINGS)

  const {
    loading: inboxSettingsLoading,
    data: inboxSettingsData,
    error: inboxSettingsError,
  } = useQuery(INBOX_SETTINGS_QUERY)

  useEffect(() => {
    if (inboxSettingsError) {
      resetState()
      onDismissWithAlert(LOAD_SETTINGS_FAIL)
    }
    if (inboxSettingsData) {
      if (inboxSettingsData?.myInboxSettings === null) {
        setFormState(defaultInboxSettings)
      } else {
        setFormState(filterState(inboxSettingsData?.myInboxSettings))
      }
    }
  }, [inboxSettingsData, inboxSettingsError]) // eslint-disable-line react-hooks/exhaustive-deps

  const saveInboxSettings = () => {
    ;(async () => {
      try {
        const updateInboxSettingsResult = await updateInboxSettings({
          variables: {
            input: filterState(formState),
          },
        })
        const errorMessage =
          updateInboxSettingsResult.data?.updateMyInboxSettings?.errors?.[0]?.message
        if (errorMessage) throw new Error(errorMessage)
        onDismissWithAlert(SAVE_SETTINGS_OK)
      } catch (_err) {
        onDismissWithAlert(SAVE_SETTINGS_FAIL)
      }
    })()
  }

  const filterState = (state: Object = defaultInboxSettings): InboxSettings => {
    const allowedKeys = new Set([
      'useSignature',
      'signature',
      'useOutOfOffice',
      'outOfOfficeFirstDate',
      'outOfOfficeLastDate',
      'outOfOfficeSubject',
      'outOfOfficeMessage',
    ])
    return Object.entries(state).reduce((acc, [key, val]) => {
      if (allowedKeys.has(key)) acc = {...acc, [key]: val}
      return acc
    }, {})
  }

  const resetState = () => {
    setValidSignature(true)
  }

  const dismiss = () => {
    resetState()
    onDismissWithAlert()
  }

  const validateSignature = (signature: string) => {
    if (signature.length > 255) {
      setValidSignature(false)
    } else {
      setValidSignature(true)
    }
  }

  const onSignatureChange = (value: string) => {
    validateSignature(value)
    setFormState(state => ({...state, signature: value}))
  }

  const onUseSignature = (value: string) =>
    setFormState(state => ({...state, useSignature: value === 'true'}))

  const shouldDisableSaveButton =
    !validSignature ||
    updateInboxSettingsLoading ||
    (!!formState?.useSignature && (formState?.signature?.length || 0) < 1)

  const loadInboxSettingsSpinner = () => (
    <ModalSpinner
      label={I18n.t('Loading Inbox Settings')}
      message={I18n.t('Loading Inbox Settings')}
      onExited={() => {}}
    />
  )

  if (inboxSettingsLoading) return loadInboxSettingsSpinner()

  return (
    <Responsive
      match="media"
      query={{...responsiveQuerySizes({mobile: true, desktop: true})}}
      props={{
        mobile: {
          modalSize: 'fullscreen',
          dataTestId: 'inbox-settings-modal-mobile',
          modalBodyPadding: 'medium',
        },
        desktop: {
          modalSize: 'medium',
          dataTestId: 'inbox-settings-modal-desktop',
          modalBodyPadding: 'large',
        },
      }}
      render={responsiveProps => (
        <>
          <Modal
            open={open}
            onDismiss={dismiss}
            size={responsiveProps?.modalSize}
            label={I18n.t('Inbox Settings')}
            shouldCloseOnDocumentClick={false}
            onExited={resetState}
            data-testid={responsiveProps?.dataTestId}
          >
            <Modal.Body padding={responsiveProps?.modalBodyPadding || 'medium'}>
              <>
                <View as="div">
                  <Text weight="bold">{I18n.t('Signature')}</Text>
                </View>
                <View as="div" padding="x-small 0 0">
                  {I18n.t('Signature will be added at the end of all messaging.')}
                </View>
                <View as="div" padding="medium 0 small 0">
                  <RadioInputGroup
                    name="signature_toggle"
                    description={
                      <ScreenReaderContent>{I18n.t('Signature On/Off')}</ScreenReaderContent>
                    }
                    value={formState.useSignature ? 'true' : 'false'}
                    onChange={radioGroupInput => {
                      onUseSignature(radioGroupInput.currentTarget.value)
                    }}
                  >
                    <RadioInput label={I18n.t('Signature Off')} value="false" />
                    <RadioInput label={I18n.t('Signature On')} value="true" />
                  </RadioInputGroup>
                </View>
                <View as="div">
                  <View as="div" padding="xx-small 0 x-small 0">
                    <Text weight="bold">{I18n.t('Add Signature*')}</Text>
                  </View>
                  <TextArea
                    label={<ScreenReaderContent>{I18n.t('Signature')}</ScreenReaderContent>}
                    height="8rem"
                    maxHeight="10rem"
                    placeholder={I18n.t('Add Signature')}
                    value={formState.signature}
                    disabled={!formState.useSignature}
                    onChange={e => onSignatureChange(e.currentTarget.value)}
                    messages={
                      !validSignature
                        ? [{text: I18n.t('Must be 255 characters or less'), type: 'error'}]
                        : undefined
                    }
                  />
                </View>
              </>
            </Modal.Body>
            <Modal.Footer>
              <Button
                type="button"
                color="secondary"
                margin="0 x-small 0 0"
                data-testid="cancel-button"
                onClick={dismiss}
              >
                {I18n.t('Cancel')}
              </Button>
              <Button
                color={updateInboxSettingsLoading ? 'secondary' : 'primary'}
                margin="0 x-small 0 0"
                onClick={saveInboxSettings}
                interaction={shouldDisableSaveButton ? 'disabled' : 'enabled'}
                data-testid="save-button"
              >
                {I18n.t('Save')}
              </Button>
            </Modal.Footer>
          </Modal>
          <ModalSpinner
            label={I18n.t('Saving Settings')}
            message={I18n.t('Saving Settings')}
            open={updateInboxSettingsLoading}
            onExited={() => {}}
          />
        </>
      )}
    />
  )
}

export default InboxSettingsModalContainer
