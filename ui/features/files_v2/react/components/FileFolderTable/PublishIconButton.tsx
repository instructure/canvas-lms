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
import {type File, type Folder} from '../../../interfaces/File'
import {getRestrictedText, isPublished, isRestricted, isHidden} from '../../../utils/fileUtils'
import {getName} from '../../../utils/fileFolderUtils'

const I18n = createI18nScope('files_v2')

interface PublishIconButtonProps {
  item: File | Folder
  userCanRestrictFilesForContext: boolean
  onClick: () => void
}

type PublishTooltipButtonProps = {
  icon: React.ReactNode
  screenReaderLabel: string
  tooltip: string
  permissionType: 'restricted' | 'link-only' | 'published' | 'unpublished'
  onClick: () => void
}

const PublishTooltipButton = ({
  icon,
  screenReaderLabel,
  tooltip,
  permissionType,
  onClick,
}: PublishTooltipButtonProps) => {
  return (
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
        screenReaderLabel={screenReaderLabel}
        onClick={onClick}
        data-testid={`${permissionType}-button-icon`}
      >
        {icon}
      </IconButton>
    </Tooltip>
  )
}

const PublishIconButton = ({
  item,
  userCanRestrictFilesForContext,
  onClick,
}: PublishIconButtonProps) => {
  const fileName = getName(item)
  const published = isPublished(item)
  const restricted = isRestricted(item)
  const hidden = isHidden(item)
  const screenReaderLabel = I18n.t('%{fileName} - Click to modify', {fileName})

  if (userCanRestrictFilesForContext) {
    if (published && restricted) {
      return (
        <PublishTooltipButton
          icon={<IconCalendarMonthLine />}
          tooltip={getRestrictedText(item)}
          screenReaderLabel={screenReaderLabel}
          onClick={onClick}
          permissionType="restricted"
        />
      )
    } else if (published && hidden) {
      return (
        <PublishTooltipButton
          icon={<IconOffLine />}
          tooltip={I18n.t('Only available to students with link')}
          screenReaderLabel={screenReaderLabel}
          onClick={onClick}
          permissionType="link-only"
        />
      )
    } else if (published) {
      return (
        <PublishTooltipButton
          icon={<IconPublishSolid color="success" />}
          tooltip={I18n.t('Published')}
          screenReaderLabel={screenReaderLabel}
          onClick={onClick}
          permissionType="published"
        />
      )
    } else {
      return (
        <PublishTooltipButton
          icon={<IconUnpublishedLine />}
          tooltip={I18n.t('Unpublished')}
          screenReaderLabel={screenReaderLabel}
          onClick={onClick}
          permissionType="unpublished"
        />
      )
    }
  } else if (published && restricted) {
    // if the user cannot edit files, we only show the icon, not a button
    return (
      <Tooltip
        renderTip={getRestrictedText(item)}
        on={['hover', 'focus']}
        themeOverride={{
          fontSize: '0.75rem',
        }}
      >
        <IconCalendarMonthLine
          color="warning"
          title={I18n.t('%{fileName}', {
            fileName,
          })}
          data-testid="restricted-icon"
        />
      </Tooltip>
    )
  }
  return null
}

export default PublishIconButton
