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

import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendar_settings_footer')

type ComponentProps = {
  readonly selectedCalendarCount: number
  readonly onApplyClicked: () => void
  readonly enableSaveButton: boolean
}

export const Footer: React.FC<ComponentProps> = ({
  selectedCalendarCount,
  onApplyClicked,
  enableSaveButton
}) => {
  return (
    <Flex alignItems="center" justifyItems="end">
      <Text>
        {I18n.t(
          {
            zero: 'No Account Calendars selected',
            one: '1 Account Calendar selected',
            other: '%{count} Account Calendars selected'
          },
          {count: selectedCalendarCount}
        )}
      </Text>
      <Button
        color="primary"
        interaction={enableSaveButton ? 'enabled' : 'disabled'}
        onClick={onApplyClicked}
        margin="small"
      >
        {I18n.t('Apply Changes')}
      </Button>
    </Flex>
  )
}
