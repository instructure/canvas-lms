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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Button, IconButton} from '@instructure/ui-buttons'
import type {ResponsiveSizes} from 'features/course_paces/react/types'

import type {ButtonProps} from '@instructure/ui-buttons'

const I18n = useI18nScope('course_paces_settings')

interface MainMenuProps {
  readonly children: any
  readonly margin?: ButtonProps['margin']
  readonly responsiveSize: ResponsiveSizes
  readonly showSettingsPopover: boolean
  readonly isBlueprintLocked: boolean | undefined
  readonly menuPlacement: () => 'bottom start' | 'bottom end' | 'top start' | 'top end'
  readonly toggleShowSettingsPopover: (show: boolean) => void
}

const MainMenu = (props: MainMenuProps) => {
  const menuButton = () => {
    if (window.ENV.FEATURES.course_paces_redesign && props.responsiveSize !== 'small') {
      return (
        <Button
          data-testid="course-pace-settings"
          margin={props.margin}
          renderIcon={() => <IconSettingsLine />}
        >
          {I18n.t('Settings')}
        </Button>
      )
    } else {
      return (
        <IconButton screenReaderLabel={I18n.t('Modify Settings')} margin={props.margin}>
          <IconSettingsLine />
        </IconButton>
      )
    }
  }

  return (
    <Menu
      trigger={menuButton()}
      placement={props.menuPlacement()}
      show={props.showSettingsPopover}
      onToggle={newState => props.toggleShowSettingsPopover(newState)}
      disabled={props.isBlueprintLocked}
      shouldHideOnSelect={false}
      withArrow={false}
      themeOverride={{
        minWidth: '243px',
        maxWidth: '243px',
      }}
    >
      {props.children}
    </Menu>
  )
}

export default MainMenu
