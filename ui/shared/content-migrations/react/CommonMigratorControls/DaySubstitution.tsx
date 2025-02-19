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

import React from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {BaseButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconTrashLine, IconEndLine} from '@instructure/ui-icons'

import type { DaySub } from "./types";

const I18n = createI18nScope('content_migrations_redesign')

type WeekDaySelectOption = {
  key: string
  name: string
}

const WEEKDAYS: Array<WeekDaySelectOption> = [
  {key: 'Sun', name: I18n.t('Sunday')},
  {key: 'Mon', name: I18n.t('Monday')},
  {key: 'Tue', name: I18n.t('Tuesday')},
  {key: 'Wed', name: I18n.t('Wednesday')},
  {key: 'Thu', name: I18n.t('Thursday')},
  {key: 'Fri', name: I18n.t('Friday')},
  {key: 'Sat', name: I18n.t('Saturday')},
]

type DaySubstitutionDirection = 'to' | 'from'

type SimpleSelectOption = {
  value?: string | number
  id?: string
}

type DaySubstitutionProps = {
  key: number
  substitution: DaySub
  isMobileView: boolean
  disabled?: boolean
  onChangeSubstitution: (id: number, data: SimpleSelectOption, to_or_from: DaySubstitutionDirection) => void
  onRemoveSubstitution: (substitution: DaySub) => void
}

export default ({
  substitution,
  isMobileView,
  disabled,
  onChangeSubstitution,
  onRemoveSubstitution,
}: DaySubstitutionProps) => {

  const handleSelectChange = (
    data: SimpleSelectOption,
    to_or_from: DaySubstitutionDirection
  ) => {
    onChangeSubstitution(substitution.id, data, to_or_from)
  }

  const handleMoveFromSelectChange = (
    _e: React.SyntheticEvent<Element, Event>,
    data: SimpleSelectOption
  ) => {
    handleSelectChange(data, 'from')
  }

  const handleMoveToSelectChange = (
    _e: React.SyntheticEvent<Element, Event>,
    data: SimpleSelectOption
  ) => {
    handleSelectChange(data, 'to')
  }

  const handleRemoveButtonOnClick = () => {
    onRemoveSubstitution(substitution)
  }

  const renderWeekDaySelectOptions = (weekDays: WeekDaySelectOption[]) => {
    return weekDays.map((d, index) => (
      <SimpleSelect.Option key={d.key} id={d.key} value={index}>
        {d.name}
      </SimpleSelect.Option>
    ))
  }

  const interaction = disabled ? 'disabled' : 'enabled'

  return (
    <View as="div" margin="medium none none none" key={substitution.id}>
      <Text weight="bold">{I18n.t('Move from:')}</Text>
      <Flex as="div" direction={isMobileView ? 'column' : 'row'}>
        <SimpleSelect
          id={`day-substition-from-${substitution.id}`}
          autoFocus={true}
          interaction={interaction}
          renderLabel={<ScreenReaderContent>{I18n.t('Move from')}</ScreenReaderContent>}
          onChange={handleMoveFromSelectChange}
          width={isMobileView ? '100%' : '18.5rem'}
        >
          {renderWeekDaySelectOptions(WEEKDAYS)}
        </SimpleSelect>
        <View
          as="div"
          width={isMobileView ? '100%' : '7.5rem'}
          textAlign={isMobileView ? 'start' : 'center'}
          margin={isMobileView ? 'small 0' : '0 x-small'}
          tabIndex={-1}
        >
          {I18n.t('to')}
        </View>
        <SimpleSelect
          id={`day-substition-to-${substitution.id}`}
          interaction={interaction}
          onChange={handleMoveToSelectChange}
          renderLabel={<ScreenReaderContent>{I18n.t('Move to')}</ScreenReaderContent>}
          width={isMobileView ? '100%' : '18.5rem'}
        >
          {renderWeekDaySelectOptions(WEEKDAYS)}
        </SimpleSelect>
        <BaseButton
          id={`remove-substitution-${substitution.id}`}
          withBorder={isMobileView}
          withBackground={isMobileView}
          margin={isMobileView ? 'small none none none' : 'none none none medium'}
          onClick={handleRemoveButtonOnClick}
          textAlign="center"
          interaction={interaction}
          renderIcon={isMobileView ? IconTrashLine : IconEndLine}
        >
          <ScreenReaderContent>
            {I18n.t("Remove '%{from}' to '%{to}' from substitutes", {
              to: WEEKDAYS[substitution.to].name,
              from: WEEKDAYS[substitution.from].name,
            })}
          </ScreenReaderContent>
          {isMobileView ? I18n.t('Remove substitution') : ''}
        </BaseButton>
      </Flex>
    </View>
  )
}
