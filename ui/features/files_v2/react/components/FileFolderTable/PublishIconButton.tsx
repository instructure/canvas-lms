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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconPublishSolid,
  IconUnpublishedLine,
  IconCalendarMonthLine,
  IconOffLine,
} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {datetimeString} from '@canvas/datetime/date-functions'
import {type File, type Folder} from '../../../interfaces/File'

const I18n = createI18nScope('files_v2')

interface PublishIconButtonProps {
  item: File | Folder
  userCanEditFilesForContext: boolean
}

interface RenderButtonProps {
  icon: React.ReactNode
  srLabel: string
  tooltip: string
}

const PublishIconButton = ({item, userCanEditFilesForContext}: PublishIconButtonProps) => {
  const fileName = 'name' in item ? item.name : item.display_name
  const published = !item.locked
  const restricted = !!item.lock_at || !!item.unlock_at
  const hidden = !!item.hidden

  const getRestrictedText = () => {
    if (item.unlock_at && item.lock_at) {
      return I18n.t('Available from %{from_date} until %{until_date}', {
        from_date: datetimeString(item.unlock_at),
        until_date: datetimeString(item.lock_at),
      })
    } else if (item.unlock_at) {
      return I18n.t('Available from %{from_date}', {
        from_date: datetimeString(item.unlock_at),
      })
    } else if (item.lock_at) {
      return I18n.t('Available until %{until_date}', {
        until_date: datetimeString(item.lock_at),
      })
    }
  }

  const renderButton = ({icon, srLabel, tooltip}: RenderButtonProps) => (
    <Tooltip
      renderTip={tooltip}
      on={['hover', 'focus']}
      themeOverride={{
        fontSize: '0.75rem',
      }}
    >
      <IconButton
        withBackground={false}
        withBorder={false}
        size="small"
        shape="circle"
        screenReaderLabel={srLabel}
      >
        {icon}
      </IconButton>
    </Tooltip>
  )
  if (userCanEditFilesForContext) {
    if (published && restricted) {
      return renderButton({
        icon: <IconCalendarMonthLine />,
        tooltip: getRestrictedText(),
        srLabel: I18n.t('%{fileName} is %{restricted} - Click to modify', {
          fileName,
          restricted: getRestrictedText(),
        }),
      })
    } else if (published && hidden) {
      return renderButton({
        icon: <IconOffLine />,
        tooltip: I18n.t('Only available to students with link'),
        srLabel: I18n.t(
          '%{fileName} is only available to students with the link - Click to modify',
          {
            fileName,
          }
        ),
      })
    } else if (published) {
      return renderButton({
        icon: <IconPublishSolid color="success" />,
        tooltip: I18n.t('Published'),
        srLabel: I18n.t('%{fileName} is Published - Click to modify', {fileName}),
      })
    } else {
      return renderButton({
        icon: <IconUnpublishedLine />,
        tooltip: I18n.t('Unpublished'),
        srLabel: I18n.t('%{fileName} is Unpublished - Click to modify', {fileName}),
      })
    }
  } else if (published && restricted) {
    return renderButton({
      icon: <IconCalendarMonthLine color="warning" />,
      tooltip: getRestrictedText(),
      srLabel: I18n.t('%{fileName} is %{restricted}', {
        fileName,
        restricted: getRestrictedText(),
      }),
    })
  }
  return null
}

export default PublishIconButton
