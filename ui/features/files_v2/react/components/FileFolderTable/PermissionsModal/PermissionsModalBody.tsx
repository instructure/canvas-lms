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

import {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {isFile} from '../../../../utils/fileFolderUtils'
import {type File, type Folder} from '../../../../interfaces/File'
import {AvailabilitySelect, type AvailabilityOptionChangeHandler} from './AvailabilitySelect'
import {DateRangeSelect} from './DateRangeSelect'
import {VisibilitySelect, type VisibilityOptionChangeHandler} from './VisibilitySelect'
import {
  type DateRangeTypeOption,
  type AvailabilityOption,
  type VisibilityOption,
} from './PermissionsModalUtils'

const I18n = createI18nScope('files_v2')

type PermissionsModalBodyProps = {
  isRequestInFlight: boolean
  items: (File | Folder)[]
  error: string | null
  onDismissAlert: () => void
  availabilityOption: AvailabilityOption
  onChangeAvailabilityOption: AvailabilityOptionChangeHandler
  enableVisibility: boolean
  visibilityOption: VisibilityOption
  visibilityOptions: Record<string, VisibilityOption>
  onChangeVisibilityOption: VisibilityOptionChangeHandler
  dateRangeType: DateRangeTypeOption | null
  unlockAt: string | null
  onChangeDateRangeType: (event: React.SyntheticEvent, data: {id?: string}) => void
  unlockAtDateInputRef: (el: HTMLInputElement | null) => void
  unlockAtTimeInputRef: (el: HTMLInputElement | null) => void
  unlockAtError: FormMessage[] | undefined
  onChangeUnlockAt: (event: React.SyntheticEvent, isoValue?: string) => void
  lockAt: string | null
  lockAtDateInputRef: (el: HTMLInputElement | null) => void
  lockAtTimeInputRef: (el: HTMLInputElement | null) => void
  lockAtError: FormMessage[] | undefined
  onChangeLockAt: (event: React.SyntheticEvent, isoValue?: string) => void
}

export const PermissionsModalBody = ({
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
  dateRangeType,
  onChangeDateRangeType,
  unlockAt,
  unlockAtDateInputRef,
  unlockAtTimeInputRef,
  unlockAtError,
  onChangeUnlockAt,
  lockAt,
  lockAtDateInputRef,
  lockAtTimeInputRef,
  lockAtError,
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
          data-testid="permissions-usage-rights-alert"
        >
          {error}
        </Alert>
      )}
      <View as="div" margin="small none none none">
        <AvailabilitySelect
          availabilityOption={availabilityOption}
          onChangeAvailabilityOption={onChangeAvailabilityOption}
        />
      </View>

      {availabilityOption.id === 'date_range' && (
        <DateRangeSelect
          dateRangeType={dateRangeType}
          onChangeDateRangeType={onChangeDateRangeType}
          unlockAt={unlockAt}
          unlockAtDateInputRef={unlockAtDateInputRef}
          unlockAtTimeInputRef={unlockAtTimeInputRef}
          unlockAtError={unlockAtError}
          onChangeUnlockAt={onChangeUnlockAt}
          lockAt={lockAt}
          lockAtDateInputRef={lockAtDateInputRef}
          lockAtTimeInputRef={lockAtTimeInputRef}
          lockAtError={lockAtError}
          onChangeLockAt={onChangeLockAt}
        />
      )}

      {enableVisibility && !allFolders && (
        <View as="div" margin="small none none none">
          <VisibilitySelect
            visibilityOption={visibilityOption}
            visibilityOptions={visibilityOptions}
            availabilityOption={availabilityOption}
            onChangeVisibilityOption={onChangeVisibilityOption}
          />
        </View>
      )}
    </>
  )
}
