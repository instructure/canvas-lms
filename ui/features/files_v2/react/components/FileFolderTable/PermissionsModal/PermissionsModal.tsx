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

import {ReactElement, useCallback, useMemo, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {queryClient} from '@canvas/query'
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {
  IconCalendarMonthLine,
  IconOffLine,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {type File, type Folder} from '../../../../interfaces/File'
import {isFile} from '../../../../utils/fileFolderUtils'
import {useFileManagement} from '../../Contexts'

type AvailabilityOptionId = 'published' | 'unpublished' | 'link_only' | 'date_range'

type AvailabilityOption = {
  id: AvailabilityOptionId
  label: string
  icon: ReactElement
}

type VisibilityOption = {
  id: string
  label: string
}

type PermissionsModalHeaderProps = {
  onDismiss: () => void
}

type PermissionsModalBodyProps = {
  isRequestInFlight: boolean
  items: (File | Folder)[]
  error: string | null
  onDismissAlert: () => void
  availabilityOption: AvailabilityOption
  onChangeAvailabilityOption: (
    event: React.SyntheticEvent,
    data: {
      id?: string
    },
  ) => void
  enableVisibility: boolean
  visibilityOption: VisibilityOption
  visibilityOptions: Record<string, VisibilityOption>
  onChangeVisibilityOption: (
    event: React.SyntheticEvent,
    data: {
      id?: string
    },
  ) => void
  unlockAt: string | null
  unlockAtInputRef: (el: HTMLInputElement | null) => void
  onChangeUnlockAt: (event: React.SyntheticEvent, isoValue?: string) => void
  lockAt: string | null
  lockAtInputRef: (el: HTMLInputElement | null) => void
  onChangeLockAt: (event: React.SyntheticEvent, isoValue?: string) => void
}

type PermissionsModalFooterProps = {
  isRequestInFlight: boolean
  onDismiss: () => void
  onSave: () => void
}

export type PermissionsModalProps = {
  open: boolean
  items: (File | Folder)[]
  onDismiss: () => void
}

const I18n = createI18nScope('files_v2')

const AVAILABILITY_OPTIONS: Record<AvailabilityOptionId, AvailabilityOption> = {
  published: {
    id: 'published',
    label: I18n.t('Publish'),
    icon: <IconPublishSolid color="success" />,
  },
  unpublished: {
    id: 'unpublished',
    label: I18n.t('Unpublish'),
    icon: <IconUnpublishedLine />,
  },
  link_only: {
    id: 'link_only',
    label: I18n.t('Only available with link'),
    icon: <IconOffLine />,
  },
  date_range: {
    id: 'date_range',
    label: I18n.t('Schedule availability'),
    icon: <IconCalendarMonthLine />,
  },
}

const VISIBILITY_OPTIONS: Record<string, VisibilityOption> = {
  inherit: {
    id: 'inherit',
    label: I18n.t('Inherit from Course'),
  },
  context: {
    id: 'context',
    label: I18n.t('Course Members'),
  },
  institution: {
    id: 'institution',
    label: I18n.t('Institution Members'),
  },
  public: {
    id: 'public',
    label: I18n.t('Public'),
  },
}

const allAreEqual = (items: (File | Folder)[], attributes: string[]) =>
  items.every(item =>
    attributes.every(
      attribute =>
        items[0][attribute] === item[attribute] || (!items[0][attribute] && !item[attribute]),
    ),
  )

const defaultAvailabilityOption = (items: (File | Folder)[]) => {
  if (items.length === 0) return AVAILABILITY_OPTIONS.published

  if (!allAreEqual(items, ['hidden', 'locked', 'lock_at', 'unlock_at'])) {
    return AVAILABILITY_OPTIONS.published
  }
  const item = items[0]
  if (item.locked) {
    return AVAILABILITY_OPTIONS.unpublished
  } else if (item.lock_at || item.unlock_at) {
    return AVAILABILITY_OPTIONS.date_range
  } else if (item.hidden) {
    return AVAILABILITY_OPTIONS.link_only
  } else {
    return AVAILABILITY_OPTIONS.published
  }
}

const defaultDate = (items: (File | Folder)[], key: 'unlock_at' | 'lock_at') => {
  if (items.length === 0) return null

  if (!allAreEqual(items, ['hidden', 'locked', 'lock_at', 'unlock_at'])) {
    return null
  }
  const item = items[0]
  return item[key]
}

const defaultVisibilityOption = (
  items: (File | Folder)[],
  visibilityOptions: Record<string, VisibilityOption>,
) => {
  if (items.length === 0) return visibilityOptions.inherit

  if (visibilityOptions.keep) {
    return visibilityOptions.keep
  }
  const item = items[0]
  if (isFile(item) && item.visibility_level) return visibilityOptions[item.visibility_level]
  return visibilityOptions.inherit
}

const PermissionsModalHeader = ({onDismiss}: PermissionsModalHeaderProps) => (
  <>
    <CloseButton
      placement="end"
      offset="small"
      onClick={onDismiss}
      screenReaderLabel={I18n.t('Close')}
    />
    <Heading>{I18n.t('Edit Permissions')}</Heading>
  </>
)

const PermissionsModalBody = ({
  isRequestInFlight,
  items,
  error,
  onDismissAlert,
  availabilityOption,
  onChangeAvailabilityOption,
  enableVisibility,
  visibilityOption,
  visibilityOptions,
  onChangeVisibilityOption,
  unlockAt,
  unlockAtInputRef,
  onChangeUnlockAt,
  lockAt,
  lockAtInputRef,
  onChangeLockAt,
}: PermissionsModalBodyProps) => {
  const allFolders = useMemo(() => items.every(item => !isFile(item)), [items])

  if (isRequestInFlight) {
    return (
      <View as="div" textAlign="center">
        <Spinner
          renderTitle={() => I18n.t('Loading')}
          aria-live="polite"
          data-testid="permissions-spinner"
        />
      </View>
    )
  }

  return (
    <>
      <FileFolderInfo items={items} />
      {error && (
        <Alert
          variant="error"
          renderCloseButtonLabel={I18n.t('Close warning message')}
          onDismiss={onDismissAlert}
        >
          {error}
        </Alert>
      )}
      <View as="div" margin="small none none none">
        <SimpleSelect
          data-testid="permissions-availability-selector"
          renderLabel={I18n.t('Available')}
          renderBeforeInput={availabilityOption.icon}
          value={availabilityOption.id}
          onChange={onChangeAvailabilityOption}
        >
          {Object.values(AVAILABILITY_OPTIONS).map(option => (
            <SimpleSelect.Option
              key={option.id}
              id={option.id}
              value={option.id}
              renderBeforeLabel={option.icon}
            >
              {option.label}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </View>

      {availabilityOption.id === 'date_range' && (
        <>
          <View as="div" margin="small none none none">
            <DateTimeInput
              description={<></>}
              prevMonthLabel={I18n.t('Previous month')}
              nextMonthLabel={I18n.t('Next month')}
              invalidDateTimeMessage={I18n.t('Invalid date')}
              dateRenderLabel={I18n.t('Available from')}
              timeRenderLabel={I18n.t('Time')}
              layout="columns"
              value={unlockAt || undefined}
              dateInputRef={unlockAtInputRef}
              onChange={onChangeUnlockAt}
            />
          </View>

          <View as="div" margin="small none none none">
            <DateTimeInput
              description={<></>}
              prevMonthLabel={I18n.t('Previous month')}
              nextMonthLabel={I18n.t('Next month')}
              invalidDateTimeMessage={I18n.t('Invalid date')}
              dateRenderLabel={I18n.t('Until')}
              timeRenderLabel={I18n.t('Time')}
              layout="columns"
              value={lockAt || undefined}
              dateInputRef={lockAtInputRef}
              onChange={onChangeLockAt}
            />
          </View>
        </>
      )}

      {enableVisibility && !allFolders && (
        <View as="div" margin="small none none none">
          <SimpleSelect
            data-testid="permissions-visibility-selector"
            disabled={availabilityOption.id === 'unpublished'}
            renderLabel={I18n.t('Visibility')}
            value={visibilityOption.id}
            onChange={onChangeVisibilityOption}
          >
            {Object.values(visibilityOptions).map(option => (
              <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
                {option.label}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </View>
      )}
    </>
  )
}

const PermissionsModalFooter = ({
  isRequestInFlight,
  onDismiss,
  onSave,
}: PermissionsModalFooterProps) => (
  <>
    <Button
      data-testid="permissions-cancel-button"
      margin="0 x-small 0 0"
      disabled={isRequestInFlight}
      onClick={onDismiss}
    >
      {I18n.t('Cancel')}
    </Button>
    <Button
      data-testid="permissions-save-button"
      color="primary"
      disabled={isRequestInFlight}
      onClick={onSave}
    >
      {I18n.t('Save')}
    </Button>
  </>
)

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

  const unlockAtInputRef = useRef<HTMLInputElement | null>(null)
  const lockAtInputRef = useRef<HTMLInputElement | null>(null)
  const [isRequestInFlight, setIsRequestInFlight] = useState<boolean>(false)
  const [availabilityOption, setAvailabilityOption] = useState<AvailabilityOption>(() =>
    defaultAvailabilityOption(items),
  )
  const [unlockAt, setUnlockAt] = useState<string | null>(() => defaultDate(items, 'unlock_at'))
  const [lockAt, setLockAt] = useState<string | null>(() => defaultDate(items, 'lock_at'))
  const [visibilityOption, setVisibilityOption] = useState(() =>
    defaultVisibilityOption(items, visibilityOptions),
  )
  const [error, setError] = useState<string | null>()

  const resetState = useCallback(() => {
    setIsRequestInFlight(false)
    setAvailabilityOption(defaultAvailabilityOption(items))
    setUnlockAt(defaultDate(items, 'unlock_at'))
    setLockAt(defaultDate(items, 'lock_at'))
    setVisibilityOption(defaultVisibilityOption(items, visibilityOptions))
    setError(null)
  }, [items, visibilityOptions])

  const resetError = useCallback(() => setError(null), [])

  const startUpdateOperation = useCallback(() => {
    let unlock_at = null
    let lock_at = null

    if (availabilityOption.id === 'date_range') {
      unlock_at = unlockAt
      lock_at = lockAt
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
  }, [availabilityOption.id, enableVisibility, items, lockAt, unlockAt, visibilityOption])

  const handleSaveClick = useCallback(() => {
    const unlockAtHasError =
      availabilityOption.id === 'date_range' &&
      !unlockAt &&
      unlockAtInputRef.current?.value.trim() !== ''
    if (unlockAtHasError) {
      unlockAtInputRef.current?.focus()
      return
    }
    const lockAtHasError =
      availabilityOption.id === 'date_range' &&
      !lockAt &&
      lockAtInputRef.current?.value.trim() !== ''
    if (lockAtHasError) {
      lockAtInputRef.current?.focus()
      return
    }

    const usageRightsRequiredForContext =
      filesEnv.contextFor({contextId, contextType})?.usage_rights_required || false
    const hasItemsWithoutUsageRights = items.some(item =>
      isFile(item) ? !item.usage_rights : false,
    )

    if (usageRightsRequiredForContext && hasItemsWithoutUsageRights) {
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
        queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
      })
      .catch(() => {
        showFlashError(I18n.t('An error occurred while setting permissions. Please try again.'))()
      })
      .finally(() => setIsRequestInFlight(false))
  }, [
    availabilityOption.id,
    contextId,
    contextType,
    items,
    lockAt,
    onDismiss,
    startUpdateOperation,
    unlockAt,
  ])

  const handleChangeAvailabilityOption = useCallback(
    (_: React.SyntheticEvent, data: {id?: string}) => {
      if (data.id) {
        setAvailabilityOption(
          AVAILABILITY_OPTIONS[data.id as AvailabilityOptionId] as AvailabilityOption,
        )
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

  const setUnlockAtInputRef = useCallback((el: HTMLInputElement | null) => {
    unlockAtInputRef.current = el
  }, [])

  const handleChangeUnlockAt = useCallback(
    (_: React.SyntheticEvent, isoValue?: string) => setUnlockAt(isoValue || null),
    [],
  )

  const setLockAtInputRef = useCallback((el: HTMLInputElement | null) => {
    unlockAtInputRef.current = el
  }, [])

  const handleChangeLockAt = useCallback(
    (_: React.SyntheticEvent, isoValue?: string) => setLockAt(isoValue || null),
    [],
  )

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
            unlockAt={unlockAt}
            unlockAtInputRef={setUnlockAtInputRef}
            onChangeUnlockAt={handleChangeUnlockAt}
            lockAt={lockAt}
            lockAtInputRef={setLockAtInputRef}
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
