// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {Story, Meta} from '@storybook/react'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import WeekdayPicker, {WeekdayPickerProps, SelectedDaysArray} from './WeekdayPicker'
import I18n from '@canvas/i18n'

// a hack to get Chinese day abbreviations to show up in the storybook
I18n.translations['zh-Hant'] = {
  'date.datepicker.column_headings': ['星期日', '週一', '週二', '週三', '週四', '週五', '星期六'],
}

export default {
  title: 'Examples/Calendar/RecurringEvents/WeekdayPicker',
  component: WeekdayPicker,
} as Meta

const Template: Story<WeekdayPickerProps> = args => {
  const {selectedDays, locale = 'en'} = args
  const [currSelectedDays, setCurrSelectedDays] = useState<SelectedDaysArray>(() => {
    if (selectedDays && Array.isArray(selectedDays)) {
      return selectedDays
    }
    return []
  })

  const handleDaysChange = useCallback((newDays: SelectedDaysArray) => {
    setCurrSelectedDays(newDays)
  }, [])

  return (
    <div>
      <style>
        button:focus {'{'} outline: 2px solid dodgerblue; {'}'}
      </style>
      <button type="button" onClick={e => e.target.focus()}>
        tab stop before
      </button>
      <View
        as="div"
        margin="small 0"
        padding="medium 0"
        borderWidth="small 0"
        borderColor="default"
      >
        <WeekdayPicker
          locale={locale}
          selectedDays={currSelectedDays}
          onChange={handleDaysChange}
        />
      </View>
      <button type="button" onClick={e => e.target.focus()}>
        tab stop after
      </button>
      <View as="div" margin="small">
        <Text>{currSelectedDays.join(', ')}</Text>
      </View>
    </div>
  )
}

export const Default = Template.bind({})
Default.args = {}

export const InGBEnglish = Template.bind({})
InGBEnglish.args = {
  locale: 'en_GB',
}

export const InSortOfChinese = Template.bind({})
InSortOfChinese.args = {
  locale: 'zh-Hant',
}

export const WithSelectedDays = Template.bind({})
WithSelectedDays.args = {
  selectedDays: ['MO', 'WE', 'TH'],
}
