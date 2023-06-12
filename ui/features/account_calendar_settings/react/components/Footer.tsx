// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import ConfirmationModal from './ConfirmationModal'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {useScope as useI18nScope} from '@canvas/i18n'

import {VisibilityChange} from '../types'

const I18n = useI18nScope('account_calendar_settings_footer')

type ComponentProps = {
  readonly originAccountId: number
  readonly visibilityChanges: VisibilityChange[]
  readonly onApplyClicked: () => void
  readonly enableSaveButton: boolean
  readonly showConfirmation: boolean
}

export const Footer = ({
  originAccountId,
  visibilityChanges,
  onApplyClicked,
  enableSaveButton,
  showConfirmation,
}: ComponentProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [initialEnabledCalendarsCount, setInitialEnabledCalendarsCount] = useState<
    number | undefined
  >(undefined)

  // @ts-ignore - this hook isn't ts-ified
  useFetchApi({
    path: `/api/v1/accounts/${originAccountId}/visible_calendars_count`,
    success: useCallback(response => setInitialEnabledCalendarsCount(response.count), []),
    error: useCallback(error => showFlashError(I18n.t('Unable to load calendar count'))(error), []),
  })

  const handleApply = () => {
    if (showConfirmation) {
      setIsModalOpen(true)
    } else {
      onApplyClicked()
    }
  }

  return (
    <Flex alignItems="center" justifyItems="end">
      {initialEnabledCalendarsCount !== undefined && (
        <Text data-testid="calendars-selected-text">
          {I18n.t(
            {
              zero: 'No account calendars selected',
              one: '1 Account calendar selected',
              other: '%{count} Account calendars selected',
            },
            {
              count:
                initialEnabledCalendarsCount +
                visibilityChanges.filter(c => c.visible).length -
                visibilityChanges.filter(c => !c.visible).length,
            }
          )}
        </Text>
      )}
      <Button
        color="primary"
        interaction={enableSaveButton ? 'enabled' : 'disabled'}
        onClick={handleApply}
        margin="small"
        data-testid="save-button"
      >
        {I18n.t('Apply Changes')}
      </Button>
      {showConfirmation && (
        <ConfirmationModal
          isOpen={isModalOpen}
          onCancel={() => setIsModalOpen(false)}
          onConfirm={onApplyClicked}
        />
      )}
    </Flex>
  )
}
