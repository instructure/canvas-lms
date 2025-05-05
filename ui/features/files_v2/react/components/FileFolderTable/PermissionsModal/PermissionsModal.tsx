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
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getFilesEnv} from '../../../../utils/filesEnvUtils'
import {Modal} from '@instructure/ui-modal'
import {type File, type Folder} from '../../../../interfaces/File'
import {isFile} from '../../../../utils/fileFolderUtils'
import {useFileManagement} from '../../../contexts/FileManagementContext'
import {useRows} from '../../../contexts/RowsContext'
import type {FormMessage} from '@instructure/ui-form-field'
import {PermissionsModalHeader} from './PermissionsModalHeader'
import {PermissionsModalBody} from './PermissionsModalBody'
import {PermissionsModalFooter} from './PermissionsModalFooter'
import {
  allAreEqual,
  defaultAvailabilityOption,
  defaultDate,
  defaultDateRangeType,
  defaultVisibilityOption,
  parseNewRows,
  type AvailabilityOptionId,
  type AvailabilityOption,
  type DateRangeTypeId,
  type DateRangeTypeOption,
  type VisibilityOption,
  AVAILABILITY_OPTIONS,
  DATE_RANGE_TYPE_OPTIONS,
  VISIBILITY_OPTIONS,
  isStartDateRequired,
  isEndDateRequired,
} from './PermissionsModalUtils'

export type PermissionsModalProps = {
  open: boolean
  items: (File | Folder)[]
  onDismiss: () => void
}

const I18n = createI18nScope('files_v2')

const PermissionsModal = ({open, items, onDismiss}: PermissionsModalProps) => {
  const {contextId, contextType} = useFileManagement()
  const enableVisibility = contextType === 'course'
  const visibilityOptions = useMemo<Record<string, VisibilityOption>>(() => {
    const equal = allAreEqual(
      items.filter(item => isFile(item)),
      ['visibility_level'],
    )
    return equal
      ? VISIBILITY_OPTIONS
      : {keep: {id: 'keep', label: I18n.t('Keep')}, ...VISIBILITY_OPTIONS}
  }, [items])

  const unlockAtDateInputRef = useRef<HTMLInputElement | null>(null)
  const unlockAtTimeInputRef = useRef<HTMLInputElement | null>(null)
  const lockAtDateInputRef = useRef<HTMLInputElement | null>(null)
  const lockAtTimeInputRef = useRef<HTMLInputElement | null>(null)
  const [isRequestInFlight, setIsRequestInFlight] = useState<boolean>(false)
  const [availabilityOption, setAvailabilityOption] = useState<AvailabilityOption>(() =>
    defaultAvailabilityOption(items),
  )
  const [unlockAt, setUnlockAt] = useState<string | null>(() => defaultDate(items, 'unlock_at'))
  const [unlockAtError, setUnlockAtError] = useState<FormMessage[]>()
  const [lockAt, setLockAt] = useState<string | null>(() => defaultDate(items, 'lock_at'))
  const [lockAtError, setLockAtError] = useState<FormMessage[]>()
  const [dateRangeType, setDateRangeType] = useState<DateRangeTypeOption | null>(() =>
    defaultDateRangeType(items),
  )
  const [visibilityOption, setVisibilityOption] = useState(() =>
    defaultVisibilityOption(items, visibilityOptions),
  )
  const [error, setError] = useState<string | null>()

  const {currentRows, setCurrentRows} = useRows()

  const resetState = useCallback(() => {
    setIsRequestInFlight(false)
    setAvailabilityOption(defaultAvailabilityOption(items))
    setUnlockAt(defaultDate(items, 'unlock_at'))
    setLockAt(defaultDate(items, 'lock_at'))
    setDateRangeType(defaultDateRangeType(items))
    setVisibilityOption(defaultVisibilityOption(items, visibilityOptions))
    setError(null)
  }, [items, visibilityOptions])

  const resetError = useCallback(() => setError(null), [])

  useEffect(() => {
    setError(null)
    setLockAtError([])
    setUnlockAtError([])
  }, [availabilityOption.id, unlockAt, lockAt])

  const startUpdateOperation = useCallback(() => {
    let unlock_at = null
    let lock_at = null

    if (availabilityOption.id === 'date_range') {
      unlock_at = isStartDateRequired(dateRangeType) ? unlockAt : null
      lock_at = isEndDateRequired(dateRangeType) ? lockAt : null
    }

    const opts: Record<string, string | boolean> = {
      hidden: availabilityOption.id === 'link_only',
      unlock_at: unlock_at || '',
      lock_at: lock_at || '',
      locked: availabilityOption.id === 'unpublished',
    }

    if (enableVisibility && visibilityOption) {
      opts.visibility_level = visibilityOption.id
    }

    return Promise.all(
      items.map(item =>
        doFetchApi<File | Folder>({
          method: 'PUT',
          path: `/api/v1/${isFile(item) ? 'files' : 'folders'}/${item.id}`,
          body: opts,
        }),
      ),
    )
  }, [
    availabilityOption.id,
    dateRangeType,
    enableVisibility,
    items,
    lockAt,
    unlockAt,
    visibilityOption,
  ])

  const isValidByDateRange = useCallback(() => {
    const errorMsg = I18n.t('Invalid date.')
    if (dateRangeType?.id === 'start') {
      if (!unlockAt) {
        setUnlockAtError([{text: errorMsg, type: 'newError'}])
        unlockAtDateInputRef.current?.focus()
        return false
      }
    }

    if (dateRangeType?.id === 'end') {
      if (!lockAt) {
        setLockAtError([{text: errorMsg, type: 'newError'}])
        lockAtDateInputRef.current?.focus()
        return false
      }
    }

    if (dateRangeType?.id === 'range') {
      if (!unlockAt && !lockAt) {
        setUnlockAtError([{text: errorMsg, type: 'newError'}])
        setLockAtError([{text: errorMsg, type: 'newError'}])
        unlockAtDateInputRef.current?.focus()
        return false
      }

      if (!unlockAt) {
        setUnlockAtError([{text: errorMsg, type: 'newError'}])
        unlockAtDateInputRef.current?.focus()
        return false
      }

      if (!lockAt) {
        setLockAtError([{text: errorMsg, type: 'newError'}])
        lockAtDateInputRef.current?.focus()
        return false
      }

      if (unlockAt && lockAt && unlockAt > lockAt) {
        setUnlockAtError([
          {text: I18n.t('Unlock date cannot be after lock date.'), type: 'newError'},
        ])
        unlockAtDateInputRef.current?.focus()
        return false
      }
    }

    return true
  }, [dateRangeType, lockAt, unlockAt])

  const handleSaveClick = useCallback(() => {
    if (availabilityOption.id === 'date_range') {
      if (!isValidByDateRange()) {
        return
      }
    }

    const usageRightsRequiredForContext =
      getFilesEnv().contextFor({contextId, contextType})?.usage_rights_required || false
    const hasItemsWithoutUsageRights = items.some(item =>
      isFile(item) ? !item.usage_rights : false,
    )

    if (
      usageRightsRequiredForContext &&
      hasItemsWithoutUsageRights &&
      availabilityOption.id !== 'unpublished'
    ) {
      setError(
        I18n.t('Selected items must have usage rights assigned before they can be published.'),
      )
      return
    }

    setIsRequestInFlight(true)
    showFlashAlert({message: I18n.t('Starting update operation...')})
    return startUpdateOperation()
      .then(() => {
        onDismiss()
        showFlashSuccess(I18n.t('Permissions have been successfully set.'))()
        const newRows = parseNewRows({
          items,
          availabilityOptionId: availabilityOption.id,
          dateRangeType: dateRangeType,
          currentRows,
          unlockAt,
          lockAt,
        })
        setCurrentRows(newRows)
      })
      .catch(() => {
        showFlashError(I18n.t('An error occurred while setting permissions. Please try again.'))()
      })
      .finally(() => setIsRequestInFlight(false))
  }, [
    availabilityOption.id,
    dateRangeType,
    contextId,
    contextType,
    items,
    onDismiss,
    startUpdateOperation,
    unlockAt,
    lockAt,
    currentRows,
    setCurrentRows,
    isValidByDateRange,
  ])

  const handleChangeAvailabilityOption = useCallback(
    (_: React.SyntheticEvent, data: {id?: string}) => {
      if (data.id) {
        setAvailabilityOption(
          AVAILABILITY_OPTIONS[data.id as AvailabilityOptionId] as AvailabilityOption,
        )
        if (data.id === 'date_range') {
          setDateRangeType(DATE_RANGE_TYPE_OPTIONS.range)
        }
      }
    },
    [],
  )

  const handleChangeVisibilityOption = useCallback(
    (_: React.SyntheticEvent, data: {id?: string}) => {
      if (data.id) {
        setVisibilityOption(visibilityOptions[data.id] as VisibilityOption)
      }
    },
    [visibilityOptions],
  )

  const handleChangeDateRangeType = useCallback((_: React.SyntheticEvent, data: {id?: string}) => {
    if (data.id) {
      setDateRangeType(
        (DATE_RANGE_TYPE_OPTIONS[data.id as DateRangeTypeId] as DateRangeTypeOption) || null,
      )
    }
  }, [])

  const setUnlockAtInputRef = useCallback((el: HTMLInputElement | null) => {
    unlockAtDateInputRef.current = el
  }, [])

  const setUnlockAtTimeInputRef = useCallback((el: HTMLInputElement | null) => {
    unlockAtTimeInputRef.current = el
  }, [])

  const handleChangeUnlockAt = useCallback((_: React.SyntheticEvent, isoValue?: string) => {
    setUnlockAt(isoValue || null)
  }, [])

  const setLockAtInputRef = useCallback((el: HTMLInputElement | null) => {
    lockAtDateInputRef.current = el
  }, [])

  const setLockAtTimeInputRef = useCallback((el: HTMLInputElement | null) => {
    lockAtTimeInputRef.current = el
  }, [])

  const handleChangeLockAt = useCallback((_: React.SyntheticEvent, isoValue?: string) => {
    setLockAt(isoValue || null)
  }, [])

  return (
    <>
      <Modal
        open={open}
        onDismiss={onDismiss}
        size="small"
        label={I18n.t('Edit Permissions')}
        shouldCloseOnDocumentClick={false}
        onEntering={resetState}
      >
        <Modal.Header>
          <PermissionsModalHeader onDismiss={onDismiss} />
        </Modal.Header>
        <Modal.Body>
          <PermissionsModalBody
            isRequestInFlight={isRequestInFlight}
            items={items}
            error={error || null}
            onDismissAlert={resetError}
            availabilityOption={availabilityOption}
            onChangeAvailabilityOption={handleChangeAvailabilityOption}
            enableVisibility={enableVisibility}
            visibilityOption={visibilityOption}
            visibilityOptions={visibilityOptions}
            onChangeVisibilityOption={handleChangeVisibilityOption}
            dateRangeType={dateRangeType}
            onChangeDateRangeType={handleChangeDateRangeType}
            unlockAt={unlockAt}
            unlockAtDateInputRef={setUnlockAtInputRef}
            unlockAtTimeInputRef={setUnlockAtTimeInputRef}
            unlockAtError={unlockAtError}
            onChangeUnlockAt={handleChangeUnlockAt}
            lockAt={lockAt}
            lockAtDateInputRef={setLockAtInputRef}
            lockAtTimeInputRef={setLockAtTimeInputRef}
            lockAtError={lockAtError}
            onChangeLockAt={handleChangeLockAt}
          />
        </Modal.Body>
        <Modal.Footer>
          <PermissionsModalFooter
            isRequestInFlight={isRequestInFlight}
            onDismiss={onDismiss}
            onSave={handleSaveClick}
          />
        </Modal.Footer>
      </Modal>
    </>
  )
}

export default PermissionsModal
