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
import { useScope as createI18nScope } from '@canvas/i18n'
import { Menu } from '@instructure/ui-menu'
import { IconSettingsLine } from '@instructure/ui-icons'
import { Button, IconButton } from '@instructure/ui-buttons'
import type { ResponsiveSizes } from 'features/course_paces/react/types'
import {actions} from './../../../actions/ui'
import { getShowWeightedAssignmentsTray } from './../../../reducers/ui'
import { connect } from 'react-redux'
import { StoreState } from '../../../types'

import type { ButtonProps } from '@instructure/ui-buttons'

const I18n = createI18nScope('course_paces_settings')

interface PassedProps {
  readonly children: (JSX.Element | undefined)[] | JSX.Element
  readonly margin?: ButtonProps['margin']
  readonly responsiveSize: ResponsiveSizes
  readonly showSettingsPopover: boolean
  readonly isBlueprintLocked?: boolean | undefined
  readonly isPrincipal: boolean
  readonly isSyncing: boolean
  readonly showBlackoutDatesModal: () => void
  readonly toggleShowSettingsPopover: (show: boolean) => void
  readonly contextType: string
  readonly menuPlacement: () => 'bottom start' | 'bottom end' | 'top start' | 'top end'
}

interface StoreProps {
  readonly weightAssignmentsOpen: boolean
}

interface DispatchProps {
  readonly showWeightedAssignmentsTray: typeof actions.showWeightedAssignmentsTray
}

type MainMenuProps = PassedProps & StoreProps & DispatchProps

const MainMenu = (props: MainMenuProps) => {
  const showWeightedAssignments = props.isPrincipal && window.ENV.FEATURES.course_pace_weighted_assignments

  const menuButton = () => {
    if (props.responsiveSize !== 'small') {
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

  const renderManageBlackoutDates = (
    isSyncing: boolean,
    showBlackoutDatesModal: () => void,
    toggleShowSettingsPopover: (show: boolean) => void,
    context_type: string,
  ) => {

    if (!props.isPrincipal) return null

    if (context_type === 'Course') {
      return (
        <Menu.Item
          type="button"
          onSelect={() => {
            toggleShowSettingsPopover(false)
            showBlackoutDatesModal()
          }}
          disabled={isSyncing}
        >
          {I18n.t('Manage Blackout Dates')}
        </Menu.Item>
      )
    }
  }

  const renderWeightedAssignmentSettings = () => {
    if (showWeightedAssignments) {

      return (
        <Menu.Item
          type="button"
          onSelect={() => {
            props.toggleShowSettingsPopover(false)
            props.showWeightedAssignmentsTray()
          }}
          data-testid="weighted-assignment-duration-option"
        >
          {I18n.t('Set Weighted Assignment Duration')}
        </Menu.Item>
      )
    }
  }

  const menuWidth = showWeightedAssignments ? '18.25rem' : '15.188rem'

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
        minWidth: menuWidth,
        maxWidth: menuWidth,
      }}
    >
      {props.children}
      {renderManageBlackoutDates(
        props.isSyncing,
        props.showBlackoutDatesModal,
        props.toggleShowSettingsPopover,
        props.contextType,
      )}
      {renderWeightedAssignmentSettings()}
    </Menu>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    weightAssignmentsOpen: getShowWeightedAssignmentsTray(state),
  }
}

export default connect(mapStateToProps, {
  showWeightedAssignmentsTray: actions.showWeightedAssignmentsTray
})(MainMenu)
