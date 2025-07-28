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

import React, {useEffect, useMemo, useState} from 'react'
import {connect} from 'react-redux'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {coursePaceActions} from '../../../actions/course_paces'
import {getSelectedDaysToSkip} from '../../../reducers/course_paces'
import {Pill} from '@instructure/ui-pill'
import type {CoursePace, ResponsiveSizes, StoreState} from 'features/course_paces/react/types'
import {WORK_WEEK_DAYS_MENU_OPTIONS, WEEK_DAYS_VALUES} from '../../../../constants'
import MainMenu from './MainMenu'
import type {MenuPlacement} from './SettingsMenu'
import {ButtonProps} from '@instructure/ui-buttons'

const I18n = createI18nScope('course_paces_settings')

interface StoreProps {
  readonly selectedDaysToSkip: string[]
}

interface SkipSelectedDaysMenuProps {
  readonly margin?: ButtonProps['margin']
  readonly isSyncing: boolean
  readonly responsiveSize: ResponsiveSizes
  readonly showSettingsPopover: boolean
  readonly isBlueprintLocked?: boolean
  readonly menuPlacement: () => MenuPlacement
  readonly selectedDaysToSkip: string[]
  readonly showBlackoutDatesModal: () => void
  readonly coursePace: CoursePace
  readonly toggleSelectedDaysToSkip: typeof coursePaceActions.toggleSelectedDaysToSkip
  readonly toggleShowSettingsPopover: (show: boolean) => void
}

const SkipSelectedDaysMenu = (props: SkipSelectedDaysMenuProps & StoreProps) => {
  const [currentItemId, setCurrentItemId] = useState('mainMenu')
  const skipWeekendsSelected =
    props.selectedDaysToSkip.length === 2 &&
    props.selectedDaysToSkip.includes('sat') &&
    props.selectedDaysToSkip.includes('sun')

  const [skipWeekends, setSkipWeekends] = useState(skipWeekendsSelected)

  const toggleSkipWeekends = () => {
    const newSelectedDaysToSkip = props.selectedDaysToSkip.filter(value =>
      WEEK_DAYS_VALUES.includes(value),
    )

    if (!skipWeekends) {
      newSelectedDaysToSkip.push('sat', 'sun')
    }

    setSkipWeekends(!skipWeekends)
    props.toggleSelectedDaysToSkip(newSelectedDaysToSkip)
  }

  useEffect(() => {
    if (props.selectedDaysToSkip.includes('sat') && props.selectedDaysToSkip.includes('sun')) {
      setSkipWeekends(true)
    } else {
      setSkipWeekends(false)
    }
  }, [props.selectedDaysToSkip])

  const disableLastDay = useMemo(() => {
    return props.selectedDaysToSkip.length === 6
  }, [props.selectedDaysToSkip.length])

  const disableWeekends = useMemo(() => {
    return props.selectedDaysToSkip.filter(day => WEEK_DAYS_VALUES.includes(day)).length === 5
  }, [props.selectedDaysToSkip])

  const backButton = (
    <Menu.Item
      as="div"
      data-testid="back-button"
      onSelect={() => {
        setCurrentItemId('mainMenu')
      }}
    >
      <Flex as="div" justifyItems="start">
        <View margin="0 small 0 0">
          <IconArrowOpenStartLine />
        </View>
        {I18n.t('Back')}
      </Flex>
    </Menu.Item>
  )

  const skipSelectedDaysMenuHeader = (
    <Flex as="section" alignItems="end" margin="0" wrap="wrap">
      <Text weight="bold" size="medium" color="primary">
        Skip Selected Days
      </Text>
      <br />
      <Text weight="normal" size="small" color="secondary">
        Any selected days will be skipped in the course pace.
      </Text>
    </Flex>
  )

  const renderRootItemSkipSelectedDays = () => {
    const selectedItemsCount = props.selectedDaysToSkip.length
    const pillComponent =
      selectedItemsCount > 0 ? (
        <Pill
          themeOverride={{height: '1.563rem', maxWidth: '1.95rem'}}
          margin="xxx-small"
          data-testid="selected_days_counter"
        >
          {selectedItemsCount}
        </Pill>
      ) : null
    return (
      <Menu.Item
        type="button"
        data-testid="skip-selected-days"
        onSelect={() => {
          setCurrentItemId('skipSelectedDays')
        }}
      >
        <Flex as="div" justifyItems="space-between">
          Skip Selected Days
          {pillComponent} <IconArrowOpenEndLine />
        </Flex>
      </Menu.Item>
    )
  }

  return (
    <>
      {currentItemId === 'mainMenu' && (
        <MainMenu
          margin={props.margin}
          responsiveSize={props.responsiveSize}
          showSettingsPopover={props.showSettingsPopover}
          isBlueprintLocked={props.isBlueprintLocked}
          isSyncing={props.isSyncing}
          showBlackoutDatesModal={props.showBlackoutDatesModal}
          toggleShowSettingsPopover={props.toggleShowSettingsPopover}
          menuPlacement={props.menuPlacement}
          isPrincipal={true}
          contextType={props.coursePace.context_type}
        >
          {renderRootItemSkipSelectedDays()}
        </MainMenu>
      )}

      {currentItemId === 'skipSelectedDays' && (
        <MainMenu
          margin={props.margin}
          responsiveSize={props.responsiveSize}
          showSettingsPopover={props.showSettingsPopover}
          isBlueprintLocked={props.isBlueprintLocked}
          isSyncing={props.isSyncing}
          showBlackoutDatesModal={props.showBlackoutDatesModal}
          toggleShowSettingsPopover={props.toggleShowSettingsPopover}
          menuPlacement={props.menuPlacement}
          isPrincipal={false}
          contextType={props.coursePace.context_type}
        >
          {backButton}
          <Menu.Group label={skipSelectedDaysMenuHeader} allowMultiple={false}>
            <Menu.Separator
              themeOverride={{
                background: '#8D959F',
              }}
            />
          </Menu.Group>
          <Menu.Item
            type="checkbox"
            selected={skipWeekends}
            onSelect={toggleSkipWeekends}
            disabled={props.isSyncing || disableWeekends}
            data-testid="skip-weekends-toggle"
          >
            Weekends
          </Menu.Item>
          <Menu.Separator
            themeOverride={{
              background: '#D7DADE',
            }}
          />
          <Menu.Group
            allowMultiple={true}
            label=""
            disabled={props.isSyncing}
            selected={props.selectedDaysToSkip}
            onSelect={(_, selectedDaysToSkipNewValue) => {
              props.toggleSelectedDaysToSkip(selectedDaysToSkipNewValue)
            }}
          >
            {WORK_WEEK_DAYS_MENU_OPTIONS.map(({value, label}, _) => {
              return (
                <Menu.Item
                  key={value}
                  type="checkbox"
                  value={value}
                  disabled={!props.selectedDaysToSkip.includes(value) && disableLastDay}
                >
                  {label}
                </Menu.Item>
              )
            })}
          </Menu.Group>
        </MainMenu>
      )}
    </>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    selectedDaysToSkip: getSelectedDaysToSkip(state),
  }
}

export default connect(mapStateToProps)(SkipSelectedDaysMenu)
