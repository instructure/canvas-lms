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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconBlueprintLine, IconBlueprintLockLine} from '@instructure/ui-icons'
import {type File, type Folder} from '../../../interfaces/File'
import {doFetchApiWithAuthCheck, UnauthorizedError} from '../../../utils/apiUtils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('files_v2')

interface BlueprintIconButtonProps {
  item: File | Folder
}

const tooltipComponent = (title: string, child: React.ReactNode) => (
  <Tooltip
    renderTip={title}
    on={['hover', 'focus']}
    themeOverride={{
      fontSize: '0.75rem',
    }}
  >
    {child}
  </Tooltip>
)

const BlueprintIconButton = ({item}: BlueprintIconButtonProps) => {
  const [isUpdating, setIsUpdating] = useState(false)
  const [isLocked, setIsLocked] = useState(item.restricted_by_master_course)

  if (!item.folder_id) return null // is a folder

  const fileName = item.display_name

  const handleOnClick = () => {
    setIsUpdating(true)
    doFetchApiWithAuthCheck({
      path: `/api/v1/courses/${ENV.COURSE_ID}/blueprint_templates/default/restrict_item`,
      method: 'PUT',
      body: {
        content_type: 'attachment',
        content_id: item.id,
        restricted: !isLocked,
      },
    })
      .then(() => setIsLocked(!isLocked))
      .catch(error => {
        if (error instanceof UnauthorizedError) {
          window.location.href = '/login'
          return
        }
        showFlashError(
          I18n.t('An error occurred changing the lock state for "%{fileName}".', {fileName}),
        )(error)
      })
      .finally(() => {
        setIsUpdating(false)
      })
  }

  const title = isLocked ? I18n.t('Locked') : I18n.t('Unlocked')
  const icon = isLocked ? <IconBlueprintLockLine /> : <IconBlueprintLine />
  if (item.is_master_course_master_content) {
    return tooltipComponent(
      title,
      <IconButton
        withBackground={false}
        withBorder={false}
        size="small"
        shape="circle"
        screenReaderLabel={
          isLocked
            ? I18n.t('%{fileName}  is Locked - Click to modify', {fileName})
            : I18n.t('%{fileName}  is Unlocked - Click to modify', {fileName})
        }
        title={title}
        onClick={handleOnClick}
        color={isLocked ? 'primary' : 'secondary'}
        interaction={isUpdating ? 'disabled' : 'enabled'}
      >
        {icon}
      </IconButton>,
    )
  }

  return tooltipComponent(title, icon)
}

export default BlueprintIconButton
