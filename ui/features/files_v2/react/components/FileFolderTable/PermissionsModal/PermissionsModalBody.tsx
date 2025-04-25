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
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {isFile} from '../../../../utils/fileFolderUtils'
import {type File, type Folder} from '../../../../interfaces/File'
import {AVAILABILITY_OPTIONS} from './PermissionsModalUtils'
import {type AvailabilityOption, type VisibilityOption} from './PermissionsModalUtils'

const I18n = createI18nScope('files_v2')

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
              dateInputRef={unlockAtDateInputRef}
              timeInputRef={unlockAtTimeInputRef}
              onChange={onChangeUnlockAt}
              messages={unlockAtError}
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
              dateInputRef={lockAtDateInputRef}
              timeInputRef={lockAtTimeInputRef}
              onChange={onChangeLockAt}
              messages={lockAtError}
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
