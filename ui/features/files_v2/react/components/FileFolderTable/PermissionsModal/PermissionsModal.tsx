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
import {captureException} from '@sentry/react'
import {queryClient} from '@canvas/query'
import {
  showFlashAlert,
  showFlashError,
  showFlashSuccess,
  showFlashWarning,
} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getFilesEnv} from '../../../../utils/filesEnvUtils'
import {
  type UpdatePermissionBody,
  updatePermissionForItem,
} from '../../../queries/updatePermissionForItem'
import {BulkItemRequestsError} from '../../../queries/BultItemRequestsError'
import {makeBulkItemRequests} from '../../../queries/makeBulkItemRequests'
import {Modal} from '@instructure/ui-modal'
import {type File, type Folder} from '../../../../interfaces/File'
import {isFile} from '../../../../utils/fileFolderUtils'
import {useFileManagement} from '../../../contexts/FileManagementContext'
import {useRows} from '../../../contexts/RowsContext'
import {UnauthorizedError} from '../../../../utils/apiUtils'
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

  const {setSessionExpired} = useRows()

  const permissionRequestBody = useMemo(() => {
    let unlock_at = null
    let lock_at = null

    if (availabilityOption.id === 'date_range') {
      unlock_at = isStartDateRequired(dateRangeType) ? unlockAt : null
      lock_at = isEndDateRequired(dateRangeType) ? lockAt : null
    }

    const data: UpdatePermissionBody = {
      hidden: availabilityOption.id === 'link_only',
      locked: availabilityOption.id === 'unpublished',
      unlock_at: unlock_at || '',
      lock_at: lock_at || '',
    }

    if (enableVisibility && visibilityOption) {
      data.visibility_level = visibilityOption.id
    }

    return data
  }, [availabilityOption, dateRangeType, lockAt, unlockAt, enableVisibility, visibilityOption])

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
    return makeBulkItemRequests(items, item => updatePermissionForItem(item, permissionRequestBody))
  }, [items, permissionRequestBody])

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

  const handleSaveClick = useCallback(async () => {
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
    const errorMessage = I18n.t('An error occurred while setting permissions. Please try again.')

    try {
      await startUpdateOperation()
      onDismiss()
      showFlashSuccess(I18n.t('Permissions have been successfully set.'))()
      queryClient.refetchQueries({queryKey: ['quota'], type: 'active'})
      await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    } catch (err) {
      if (err instanceof UnauthorizedError) {
        setSessionExpired(true)
        return
      } else if (err instanceof BulkItemRequestsError) {
        onDismiss()

        if (err.failedItems.length === items.length) {
          showFlashError(errorMessage)()
        } else {
          showFlashWarning(errorMessage)()
          queryClient.refetchQueries({queryKey: ['quota'], type: 'active'})
          await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
        }
      } else {
        // Impossible branch, makeBulkItemRequests should always throw either UnauthorizedError or BulkItemRequestsError
        showFlashError(errorMessage)()
        captureException(errorMessage)
      }
    } finally {
      setIsRequestInFlight(false)
    }
  }, [
    availabilityOption.id,
    contextId,
    contextType,
    isValidByDateRange,
    items,
    onDismiss,
    setSessionExpired,
    startUpdateOperation,
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
