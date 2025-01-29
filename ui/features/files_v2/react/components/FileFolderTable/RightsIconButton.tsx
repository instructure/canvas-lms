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
  IconWarningLine,
  IconFilesCopyrightLine,
  IconFilesPublicDomainLine,
  IconFilesObtainedPermissionLine,
  IconFilesFairUseLine,
  IconFilesCreativeCommonsLine,
} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {type UsageRights} from '../../../interfaces/File'

const I18n = createI18nScope('files_v2')

interface RightsIconButtonProps {
  userCanEditFilesForContext: boolean
  usageRights: UsageRights | null
}

const getIconData = (use_justification: string) => {
  switch (use_justification) {
    case 'own_copyright':
      return {icon: <IconFilesCopyrightLine />, text: I18n.t('Own Copyright')}
    case 'public_domain':
      return {icon: <IconFilesPublicDomainLine />, text: I18n.t('Public Domain')}
    case 'used_by_permission':
      return {icon: <IconFilesObtainedPermissionLine />, text: I18n.t('Used by Permission')}
    case 'fair_use':
      return {icon: <IconFilesFairUseLine />, text: I18n.t('Fair Use')}
    case 'creative_commons':
      return {icon: <IconFilesCreativeCommonsLine />, text: I18n.t('Creative Commons')}
  }
}

const RightsIconButton = ({userCanEditFilesForContext, usageRights}: RightsIconButtonProps) => {

  const handleOnClick = () => {}

  const renderTooltipButton = ({icon, title, screenReaderLabel} : {
    icon: JSX.Element, 
    title: string, 
    screenReaderLabel?: string
  }) => {
    return (
      <Tooltip
        renderTip={title}
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
          screenReaderLabel={screenReaderLabel || title}
          aria-label={userCanEditFilesForContext ? I18n.t('Set usage rights') : I18n.t('Usage rights')}
          disabled={!userCanEditFilesForContext}
          onClick={handleOnClick}
        >
          {icon}
        </IconButton>
      </Tooltip>
    )
  }

  if (!usageRights) {
    if (!userCanEditFilesForContext) return null // not allow to edit
    return renderTooltipButton({
      icon: <IconWarningLine color="warning" />,
      title: I18n.t('Before publishing this file, you must specify usage rights')
    })
  }

  const iconData = getIconData(usageRights.use_justification)
  if (!iconData) return null // error

  return renderTooltipButton({
    icon: iconData.icon,
    title: usageRights.license_name,
    screenReaderLabel: iconData.text
  })
}

export default RightsIconButton
