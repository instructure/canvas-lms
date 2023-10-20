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
import {arrayOf, func, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useEffect, useState} from 'react'

import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconAlertsSolid,
  IconCalendarDaySolid,
  IconCalendarMonthSolid,
  IconMutedLine,
  IconNoLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = useI18nScope('notification_preferences')

const preferenceConfigs = {
  immediately: {
    icon: IconAlertsSolid,
    color: 'success',
    getScreenReaderLabel: () => I18n.t('Notify immediately'),
  },
  daily: {
    icon: IconCalendarDaySolid,
    color: 'success',
    getScreenReaderLabel: () => I18n.t('Daily summary'),
  },
  weekly: {
    icon: IconCalendarMonthSolid,
    color: 'success',
    getScreenReaderLabel: () => I18n.t('Weekly summary'),
  },
  never: {
    icon: IconMutedLine,
    getScreenReaderLabel: () => I18n.t('Notifications off'),
  },
  disabled: {
    icon: IconNoLine,
    getScreenReaderLabel: () => I18n.t('Notifications unsupported'),
  },
}

const renderPreferenceButton = preferenceConfig => (
  <Tooltip renderTip={preferenceConfig.getScreenReaderLabel()} placement="bottom">
    <IconButton
      withBackground={false}
      withBorder={false}
      renderIcon={preferenceConfig.icon}
      color={preferenceConfig.color}
      screenReaderLabel={preferenceConfig.getScreenReaderLabel()}
      aria-haspopup="true"
    />
  </Tooltip>
)

const renderPreferenceMenuItem = preferenceConfig => (
  <Flex>
    <Flex.Item margin="0 x-small 0 0" padding="0 0 xxx-small 0">
      <preferenceConfig.icon />
    </Flex.Item>
    <Flex.Item>
      <Text>{preferenceConfig.getScreenReaderLabel()}</Text>
    </Flex.Item>
  </Flex>
)

const NotificationPreferencesSetting = ({
  selectedPreference,
  preferenceOptions,
  updatePreference,
}) => {
  const [selection, setSelection] = useState(selectedPreference)

  useEffect(() => {
    setSelection(selectedPreference)
  }, [selectedPreference])

  const handleUpdate = value => {
    setSelection(value)
    updatePreference(value)
  }

  const preferenceConfig = preferenceConfigs[selection]
  return (
    <Menu trigger={renderPreferenceButton(preferenceConfig)} disabled={selection === 'disabled'}>
      {preferenceOptions.map(option => (
        <Menu.Item
          key={option}
          value={option}
          selected={option === selection}
          onSelect={(e, value) => handleUpdate(value)}
        >
          {renderPreferenceMenuItem(preferenceConfigs[option])}
        </Menu.Item>
      ))}
    </Menu>
  )
}

NotificationPreferencesSetting.propTypes = {
  selectedPreference: string,
  preferenceOptions: arrayOf(string),
  updatePreference: func,
}

export default NotificationPreferencesSetting
