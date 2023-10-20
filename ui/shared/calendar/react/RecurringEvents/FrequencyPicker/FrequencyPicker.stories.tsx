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
import FrequencyPicker, {FrequencyPickerProps} from './FrequencyPicker'
import I18n from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import moment from 'moment'
import {FrequencyOptionValue} from '../utils'

I18n.translations.en = {
  'date.day_names': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  'date.month_names': [
    '~',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
}

I18n.translations.en_GB = {
  'date.day_names': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  'date.month_names': [
    '~',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
}

I18n.translations.zh = {
  'date.day_names': ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'],
  'date.month_names': [
    '~',
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ],
  'calendar_frequency_picker.frequency': '频率：',
  'calendar_frequency_picker.not_repeat': '不重复',
  'calendar_frequency_picker.daily': '每日',
  'calendar_frequency_picker.weekly_day': '%{day}的周报',
  'calendar_frequency_picker.monthly_last_day': '每月最后一个%{day}',
  'calendar_frequency_picker.annually': '每年的%{month}%{date}日',
  'calendar_frequency_picker.every_weekday': '每个工作日（周一至周五',
  'calendar_frequency_picker.custom': '习俗...',
  'calendar_frequency_picker.first': '首先',
  'calendar_frequency_picker.second': '第二',
  'calendar_frequency_picker.third': '第三次',
  'calendar_frequency_picker.fourth': '第四次',
  'calendar_frequency_picker.last': '最后一次',
}

export default {
  title: 'Examples/Calendar/FrequencyPicker',
  component: FrequencyPicker,
} as Meta

const Template: Story<FrequencyPickerProps> = args => {
  const {date, interaction, initialFrequency, locale, timezone, width} = args

  I18n.locale = locale
  moment.tz.setDefault(timezone)

  const [RRule, setRRule] = useState<string>(null)
  const [frequency, setFrequency] = useState<string>(initialFrequency)

  const handleFrequencyChange = useCallback(
    (newFrequency: FrequencyOptionValue, newRRule: string) => {
      setFrequency(newFrequency)
      setRRule(newRRule)
    },
    []
  )

  return (
    <div>
      <View as="div" margin="small" padding="medium" borderWidth="small 0" borderColor="default">
        <FrequencyPicker
          key={date}
          date={date}
          interaction={interaction}
          initialFrequency={frequency}
          rrule={frequency === 'saved-custom' ? RRule : undefined}
          locale={locale}
          timezone={timezone}
          width={width}
          onChange={handleFrequencyChange}
        />
      </View>
      <View as="div" margin="small">
        <div>
          <Text weight="bold">Event start:&nbsp;</Text>
          <Text>{moment.tz(date, timezone).toString()}</Text>
        </div>
        <div>
          <Text weight="bold">Generated RRule:&nbsp;</Text>
          <Text>{RRule}</Text>
        </div>
      </View>
    </div>
  )
}

export const Default = Template.bind({})
Default.args = {
  date: moment().format('YYYY-MM-DD'),
  initialFrequency: 'not-repeat',
  locale: 'en',
  timezone: moment.tz.guess(),
}

export const Disabled = Template.bind({})
Disabled.args = {
  date: undefined,
  interaction: 'disabled',
  locale: 'en',
  timezone: moment.tz.guess(),
}

export const WithInitialFrequency = Template.bind({})
WithInitialFrequency.args = {
  date: moment().format('YYYY-MM-DD'),
  initialFrequency: 'daily',
  locale: 'en',
  timezone: moment.tz.guess(),
}

export const WidthAuto = Template.bind({})
WidthAuto.args = {
  date: moment().format('YYYY-MM-DD'),
  initialFrequency: 'not-repeat',
  locale: 'en',
  timezone: moment.tz.guess(),
  width: 'auto',
}

export const InToko = Template.bind({})
InToko.args = {
  date: moment().tz('Asia/Tokyo').format('YYYY-MM-DD'),
  initialFrequency: 'not-repeat',
  locale: 'en',
  timezone: 'Asia/Tokyo',
}

export const InGBEnglish = Template.bind({})
InGBEnglish.args = {
  date: moment().format('YYYY-MM-DD'),
  initialFrequency: 'not-repeat',
  locale: 'en_GB',
  timezone: 'Europe/London',
}

export const InChinese = Template.bind({})
InChinese.args = {
  date: moment().format('YYYY-MM-DD'),
  initialFrequency: 'not-repeat',
  locale: 'zh',
  timezone: 'Asia/Hong_Kong',
}
