// @ts-nocheck
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

import React, {useState, useEffect} from 'react'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {coursePaceActions} from '../../../actions/course_paces'
import {getSelectedDaysToSkip} from '../../../reducers/course_paces'
import {Pill} from '@instructure/ui-pill'
import type {CoursePace, StoreState} from 'features/course_paces/react/types'
import {renderManageBlackoutDates} from './helpers'
import {WORK_WEEK_DAYS_MENU_OPTIONS} from '../../../../constants'
import MainMenu from './MainMenu'

const I18n = useI18nScope('course_paces_settings')

interface StoreProps {
  readonly excludeWeekends: boolean
}

interface SkipSelectedDaysMenuProps {
  readonly isSyncing: boolean
  readonly selectedDaysToSkip: string[]
  readonly showBlackoutDatesModal: boolean
  readonly coursePace: CoursePace
  readonly toggleSelectedDaysToSkip: typeof coursePaceActions.toggleSelectedDaysToSkip
  readonly toggleShowSettingsPopover: (show: boolean) => void
}

const SkipSelectedDaysMenu = (props: SkipSelectedDaysMenuProps & StoreProps) => {
  const [currentItemId, setCurrentItemId] = useState('mainMenu')
  const skipWeedendsSelected =
    props.selectedDaysToSkip.length === 2 &&
    props.selectedDaysToSkip.includes('sat') &&
    props.selectedDaysToSkip.includes('sun')

  const [skipWeekends, setSkipWeekends] = useState(skipWeedendsSelected)

  useEffect(() => {
    const skipWeekendsValue =
      props.selectedDaysToSkip.length === 2 &&
      props.selectedDaysToSkip.includes('sat') &&
      props.selectedDaysToSkip.includes('sun')
    setSkipWeekends(skipWeekendsValue)
  }, [props.selectedDaysToSkip])

  const toggleSkipWeekends = () => {
    const newskipWeekends = !skipWeekends
    setSkipWeekends(newskipWeekends)
    const newSelectedDaysToSkip = newskipWeekends ? ['sat', 'sun'] : []
    props.toggleSelectedDaysToSkip(newSelectedDaysToSkip)
  }

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
          themeOverride={{width: '0.75rem', heigth: '0.75rem'}}
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
        <MainMenu {...props}>
          {renderRootItemSkipSelectedDays()}
          {renderManageBlackoutDates(
            props.isSyncing,
            props.showBlackoutDatesModal,
            props.toggleShowSettingsPopover,
            props.coursePace.context_type
          )}
        </MainMenu>
      )}

      {currentItemId === 'skipSelectedDays' && (
        <MainMenu {...props}>
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
            disabled={props.isSyncing}
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
                <Menu.Item key={value} type="checkbox" value={value}>
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
