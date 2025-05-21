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

import {useCallback, useEffect, useMemo, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Alert} from '@instructure/ui-alerts'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {FormMessage} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {useFileManagement} from '../../../contexts/FileManagementContext'
import {useRows} from '../../../contexts/RowsContext'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {isFile, pluralizeContextTypeString} from '../../../../utils/fileFolderUtils'
import {type File, type Folder} from '../../../../interfaces/File'
import {
  CONTENT_OPTIONS,
  defaultCopyright,
  defaultCCValue,
  defaultSelectedRight,
  parseNewRows,
} from './UsageRightsModalUtils'

export type UsageRightsModalProps = {
  open: boolean
  items: (File | Folder)[]
  onDismiss: () => void
}

type LicenseOption = {
  id: string
  name: string
  url: string
}

const I18n = createI18nScope('files_v2')

const UsageRightsModal = ({open, items, onDismiss}: UsageRightsModalProps) => {
  const {contextId, contextType} = useFileManagement()
  const usageRightRef = useRef<HTMLInputElement | null>(null)
  const [isRequestInFlight, setIsRequestInFlight] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  const [messages, setMessages] = useState<FormMessage[]>([])
  const [licenseOptions, setLicenseOptions] = useState<LicenseOption[]>([])
  const [usageRight, setUsageRight] = useState<string>(() => defaultSelectedRight(items))
  const [copyrightHolder, setCopyrightHolder] = useState<string | null>(() =>
    defaultCopyright(items),
  )
  const [ccLicenseOption, setCcLicenseOption] = useState<string | null>(() =>
    defaultCCValue(usageRight, items),
  )

  const {currentRows, setCurrentRows} = useRows()

  const showCreativeCommonsOptions = useMemo(() => usageRight === 'creative_commons', [usageRight])
  const showDifferentRightsMessage = useMemo(
    () => (copyrightHolder == null || usageRight === 'choose') && items.length > 1,
    [copyrightHolder, items.length, usageRight],
  )

  const resetState = useCallback(() => {
    setIsRequestInFlight(false)
    setError(null)
    setMessages([])
    const usageRight = defaultSelectedRight(items)
    setUsageRight(usageRight)
    setCopyrightHolder(defaultCopyright(items))
    setCcLicenseOption(defaultCCValue(usageRight, items))
  }, [items])

  const startUpdateOperation = useCallback(() => {
    const folderIds: string[] = []
    const fileIds: string[] = []
    items.forEach(item => {
      if (isFile(item)) {
        fileIds.push(item.id.toString())
      } else {
        folderIds.push(item.id.toString())
      }
    })

    const newUsageRights: Record<string, string> = {}
    if (copyrightHolder) newUsageRights.legal_copyright = copyrightHolder
    if (usageRight) newUsageRights.use_justification = usageRight
    if (ccLicenseOption) newUsageRights.license = ccLicenseOption

    return doFetchApi({
      method: 'PUT',
      path: `/api/v1/${pluralizeContextTypeString(contextType)}/${contextId}/usage_rights`,
      params: {
        folder_ids: folderIds,
        file_ids: fileIds,
        usage_rights: newUsageRights,
      },
    })
  }, [ccLicenseOption, contextId, contextType, copyrightHolder, items, usageRight])

  const handleSaveClick = useCallback(() => {
    if (usageRight === 'choose') {
      setMessages([{type: 'newError', text: I18n.t('You must specify a usage right')}])
      usageRightRef.current?.focus()
      return
    }

    setIsRequestInFlight(true)
    startUpdateOperation()
      .then(() => {
        onDismiss()
        showFlashSuccess(I18n.t('Usage rights have been set.'))()
        const newRows = parseNewRows({
          items,
          currentRows,
          usageRight,
          ccLicenseOption,
          copyrightHolder,
        })
        setCurrentRows(newRows)
      })
      .catch(showFlashError(I18n.t('There was an error setting usage rights.')))
      .finally(() => setIsRequestInFlight(false))
  }, [
    onDismiss,
    startUpdateOperation,
    usageRight,
    items,
    ccLicenseOption,
    copyrightHolder,
    currentRows,
    setCurrentRows,
  ])

  const renderHeader = useCallback(
    () => (
      <>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Manage Usage Rights')}</Heading>
      </>
    ),
    [onDismiss],
  )

  const renderBody = useCallback(() => {
    if (error) {
      return <Alert variant="error">{error}</Alert>
    }

    if (isRequestInFlight) {
      return (
        <View as="div" textAlign="center">
          <Spinner
            renderTitle={() => I18n.t('Loading')}
            aria-live="polite"
            data-testid="usage-rights-spinner"
          />
        </View>
      )
    }

    return (
      <>
        <FileFolderInfo items={items} />
        {showDifferentRightsMessage && (
          <Alert variant="warning" renderCloseButtonLabel={I18n.t('Close warning message')}>
            {I18n.t('Items selected have different usage rights.')}
          </Alert>
        )}

        <View as="div" margin="small none none none">
          <SimpleSelect
            data-testid="usage-rights-justification-selector"
            inputRef={(inputElement: HTMLInputElement | null) =>
              (usageRightRef.current = inputElement)
            }
            isRequired={true}
            messages={messages}
            value={usageRight}
            onChange={(_, {value}) => {
              setUsageRight((value as string) || 'choose')
              setMessages([])
              if (value === 'creative_commons') {
                setCcLicenseOption(licenseOptions[0].id)
              } else {
                setCcLicenseOption(null)
              }
            }}
            renderLabel={I18n.t('Usage Rights')}
          >
            {CONTENT_OPTIONS.map(option => (
              <SimpleSelect.Option key={option.value} id={option.value} value={option.value}>
                {option.display}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </View>

        {showCreativeCommonsOptions && (
          <View as="div" margin="small none none none">
            <SimpleSelect
              data-testid="usage-rights-license-selector"
              value={ccLicenseOption || ''}
              onChange={(_, {value}) => setCcLicenseOption((value as string) || null)}
              renderLabel={I18n.t('Creative Commons License')}
            >
              {licenseOptions.map(option => (
                <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
                  {option.name}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>
          </View>
        )}

        <View as="div" margin="small none none none">
          <TextInput
            data-testid="usage-rights-holder-input"
            renderLabel={I18n.t('Copyright Holder')}
            value={copyrightHolder || ''}
            onChange={(_, value) => setCopyrightHolder(value)}
          />
        </View>
        <View as="div" margin="xxx-small none none none">
          <Text size="small">{I18n.t('Example: (c) 2024 Acme Inc.')}</Text>
        </View>
      </>
    )
  }, [
    ccLicenseOption,
    copyrightHolder,
    error,
    isRequestInFlight,
    items,
    licenseOptions,
    messages,
    showCreativeCommonsOptions,
    showDifferentRightsMessage,
    usageRight,
  ])

  const renderFooter = useCallback(() => {
    return (
      <>
        <Button
          data-testid="usage-rights-cancel-button"
          margin="0 x-small 0 0"
          disabled={isRequestInFlight}
          onClick={onDismiss}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid="usage-rights-save-button"
          color="primary"
          onClick={handleSaveClick}
          disabled={isRequestInFlight}
        >
          {I18n.t('Save')}
        </Button>
      </>
    )
  }, [handleSaveClick, onDismiss, isRequestInFlight])

  const filterLicenseOptions = useCallback((options?: LicenseOption[]) => {
    if (!options) throw new Error()

    const onlyCC = options.filter(option => option.id.indexOf('cc') === 0)
    setLicenseOptions(onlyCC)
  }, [])

  // Reset the state when the open prop changes so we don't carry over state
  // from the previously opened modal
  useEffect(() => {
    if (open) {
      resetState()

      if (licenseOptions.length === 0) {
        setIsRequestInFlight(true)
        doFetchApi<LicenseOption[]>({
          path: `/api/v1/${pluralizeContextTypeString(contextType)}/${contextId}/content_licenses`,
        })
          .then(response => response.json)
          .then(filterLicenseOptions)
          .catch(() => setError('There was an error getting the content licenses.'))
          .finally(() => setIsRequestInFlight(false))
      }
    }
    // eslint-disable-next-line react-compiler/react-compiler
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  return (
    <>
      <Modal
        open={open}
        onDismiss={onDismiss}
        size="small"
        label={I18n.t('Manage Usage Rights')}
        shouldCloseOnDocumentClick={false}
        onExited={resetState}
      >
        <Modal.Header>{renderHeader()}</Modal.Header>
        <Modal.Body>{renderBody()}</Modal.Body>
        <Modal.Footer>{renderFooter()}</Modal.Footer>
      </Modal>
    </>
  )
}

export default UsageRightsModal
