/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {connect} from 'react-redux'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {coursePaceActions} from '../../../actions/course_paces'
import {getExcludeWeekends} from '../../../reducers/course_paces'
import type {CoursePace, ResponsiveSizes, StoreState} from 'features/course_paces/react/types'

import type {ButtonProps} from '@instructure/ui-buttons'
import SkipSelectedDaysMenu from './SkipSelectedDaysMenu'
import MainMenu from './MainMenu'

const I18n = createI18nScope('course_paces_settings')

interface StoreProps {
  readonly excludeWeekends: boolean
}

interface PassedProps {
  readonly isSyncing: boolean
  readonly responsiveSize: ResponsiveSizes
  readonly margin?: ButtonProps['margin']
  readonly isBlueprintLocked: boolean | undefined
  readonly showSettingsPopover: boolean
  readonly coursePace: CoursePace
  readonly toggleShowSettingsPopover: (show: boolean) => void
  readonly showBlackoutDatesModal: () => void
  readonly menuPlacement: () => MenuPlacement
  readonly toggleExcludeWeekends: typeof coursePaceActions.toggleExcludeWeekends
  readonly toggleSelectedDaysToSkip: typeof coursePaceActions.toggleSelectedDaysToSkip
}

export type MenuPlacement = 'bottom start' | 'bottom end' | 'top start' | 'top end'
export type ComponentProps = StoreProps & PassedProps

export const SettingsMenu = (props: ComponentProps) => {

  return window.ENV.FEATURES.course_paces_skip_selected_days ? (
    <SkipSelectedDaysMenu
      margin={props.margin}
      isSyncing={props.isSyncing}
      responsiveSize={props.responsiveSize}
      showSettingsPopover={props.showSettingsPopover}
      isBlueprintLocked={props.isBlueprintLocked}
      menuPlacement={props.menuPlacement}
      showBlackoutDatesModal={props.showBlackoutDatesModal}
      coursePace={props.coursePace}
      toggleSelectedDaysToSkip={props.toggleSelectedDaysToSkip}
      toggleShowSettingsPopover={props.toggleShowSettingsPopover}
    />
  ) : (
    <MainMenu
      margin={props.margin}
      responsiveSize={props.responsiveSize}
      showSettingsPopover={props.showSettingsPopover}
      isBlueprintLocked={props.isBlueprintLocked}
      isPrincipal={true}
      isSyncing={props.isSyncing}
      showBlackoutDatesModal={props.showBlackoutDatesModal}
      toggleShowSettingsPopover={props.toggleShowSettingsPopover}
      contextType={props.coursePace.context_type}
      menuPlacement={props.menuPlacement}
    >
      <Menu.Item
        type="checkbox"
        selected={props.excludeWeekends}
        onSelect={props.toggleExcludeWeekends}
        disabled={props.isSyncing}
        data-testid="skip-weekends-toggle"
      >
        {I18n.t('Skip Weekends')}
      </Menu.Item>
    </MainMenu>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    excludeWeekends: getExcludeWeekends(state),
  }
}

export default connect(mapStateToProps)(SettingsMenu)
