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

import {useScope as useI18nScope} from '@canvas/i18n'
import type {CoursePaceItem} from '../types'
import type {BlackoutDate} from '../shared/types'

const I18n = useI18nScope('course_paces_change_tracking')

export type Change<T = unknown> = {
  id: string
  oldValue?: T
  newValue: T
}

export type SummarizedChange = {
  id: string
  summary: string
}

const localizeDayCount = (days: number) =>
  I18n.t(
    {
      one: '1 day',
      other: '%{count} days',
    },
    {count: days}
  )

const localizeChangeDescription = (
  descriptiveName: string,
  formattedNewValue: string,
  formattedOldValue?: string
): string =>
  formattedOldValue
    ? I18n.t('%{descriptiveName} was changed from %{formattedOldValue} to %{formattedNewValue}.', {
        descriptiveName,
        formattedOldValue,
        formattedNewValue,
      })
    : I18n.t('%{descriptiveName} was set to %{formattedNewValue}.', {
        descriptiveName,
        formattedNewValue,
      })

const formatBooleanSettingChange = (
  change: Change<boolean>,
  descriptiveName: string = change.id
): string =>
  change.newValue
    ? I18n.t('%{descriptiveName} was turned on.', {descriptiveName})
    : I18n.t('%{descriptiveName} was turned off.', {descriptiveName})

const formatDateSettingChange = (change: Change<string>, descriptiveName: string = change.id) =>
  localizeChangeDescription(
    descriptiveName,
    I18n.l('date.formats.long', change.newValue),
    change.oldValue && I18n.l('date.formats.long', change.oldValue)
  )

const formatBlackoutDateSettingChange = (change: Change<BlackoutDate>): string => {
  if (change.newValue && !change.oldValue) {
    return I18n.t('Blackout date %{title} was added.', {title: change.newValue.event_title})
  } else if (!change.newValue && change.oldValue) {
    return I18n.t('Blackout date %{title} was deleted.', {title: change.oldValue.event_title})
  } else if (change.newValue && change.oldValue) {
    return I18n.t('Blackout date %{title} was edited.', {title: change.oldValue.event_title})
  } else {
    // something went awry
    return ''
  }
}

const formatUnknownSettingChange = (change: Change, descriptiveName: string = change.id) =>
  localizeChangeDescription(
    descriptiveName,
    JSON.stringify(change.newValue),
    change.oldValue ? JSON.stringify(change.oldValue) : undefined
  )

export const summarizeItemChanges = (itemChanges: Change<CoursePaceItem>[]): SummarizedChange[] =>
  itemChanges.map(c => ({
    id: c.id,
    summary: localizeChangeDescription(
      c.newValue.assignment_title,
      localizeDayCount(c.newValue.duration),
      c.oldValue && localizeDayCount(c.oldValue.duration)
    ),
  }))

export const summarizeSettingChanges = (settingChanges: Change[]): SummarizedChange[] => {
  const summarizedChanges: {id: string; summary: string}[] = []

  // These changes are dependent on one another, so retrieve them first
  let endDateChange, requireCompletionChanged
  for (const change of settingChanges) {
    if (change.id === 'end_date') endDateChange = change
    if (change.id === 'require_completion') requireCompletionChanged = true

    if (endDateChange && requireCompletionChanged !== undefined) break
  }

  for (const change of settingChanges) {
    let summary

    switch (change.id) {
      case 'exclude_weekends':
        summary = formatBooleanSettingChange(change as Change<boolean>, I18n.t('Skip Weekends'))
        break
      case 'require_completion':
        if (change.newValue && endDateChange) {
          summary = I18n.t('Require Completion by End Date was turned on and set to %{date}.', {
            date: I18n.l('date.formats.long', endDateChange.newValue),
          })
        } else {
          summary = formatBooleanSettingChange(
            change as Change<boolean>,
            I18n.t('Require Completion by End Date')
          )
        }
        break
      case 'end_date':
        if (!requireCompletionChanged) {
          summary = formatDateSettingChange(change as Change<string>, 'End Date')
        }
        break
      case 'blackout_date':
        summary = formatBlackoutDateSettingChange(change as Change<BlackoutDate>)
        break
      default:
        summary = formatUnknownSettingChange(change)
    }

    if (summary) {
      summarizedChanges.push({id: change.id, summary})
    }
  }

  return summarizedChanges
}

export const summarizeChanges = (
  settingChanges: Change[],
  itemChanges: Change<CoursePaceItem>[]
) => [...summarizeSettingChanges(settingChanges), ...summarizeItemChanges(itemChanges)]
