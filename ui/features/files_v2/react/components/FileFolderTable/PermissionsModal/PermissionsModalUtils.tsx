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

import {ReactElement} from 'react'
import {
  IconCalendarMonthLine,
  IconOffLine,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {type File, type Folder} from '../../../../interfaces/File'
import {getUniqueId, isFile} from '../../../../utils/fileFolderUtils'

const I18n = createI18nScope('files_v2')

export type AvailabilityOptionId = 'published' | 'unpublished' | 'link_only' | 'date_range'

export type AvailabilityOption = {
  id: AvailabilityOptionId
  label: string
  icon: ReactElement
}

export type DateRangeTypeId = 'start' | 'end' | 'range'

export type DateRangeTypeOption = {
  id: DateRangeTypeId
  label: string
}

export type VisibilityOption = {
  id: string
  label: string
}

export const AVAILABILITY_OPTIONS: Record<AvailabilityOptionId, AvailabilityOption> = {
  published: {
    id: 'published',
    label: I18n.t('Publish'),
    icon: <IconPublishSolid color="success" />,
  },
  unpublished: {
    id: 'unpublished',
    label: I18n.t('Unpublish'),
    icon: <IconUnpublishedLine />,
  },
  link_only: {
    id: 'link_only',
    label: I18n.t('Only available with link'),
    icon: <IconOffLine />,
  },
  date_range: {
    id: 'date_range',
    label: I18n.t('Schedule availability'),
    icon: <IconCalendarMonthLine />,
  },
}

export const DATE_RANGE_TYPE_OPTIONS: Record<DateRangeTypeId, DateRangeTypeOption> = {
  start: {
    id: 'start',
    label: I18n.t('Start date'),
  },
  end: {
    id: 'end',
    label: I18n.t('End date'),
  },
  range: {
    id: 'range',
    label: I18n.t('Date range'),
  },
}

export const VISIBILITY_OPTIONS: Record<string, VisibilityOption> = {
  inherit: {
    id: 'inherit',
    label: I18n.t('Inherit from Course'),
  },
  context: {
    id: 'context',
    label: I18n.t('Course Members'),
  },
  institution: {
    id: 'institution',
    label: I18n.t('Institution Members'),
  },
  public: {
    id: 'public',
    label: I18n.t('Public'),
  },
}

export const allAreEqual = (items: (File | Folder)[], attributes: string[]) =>
  items.every(item =>
    attributes.every(
      attribute =>
        items[0][attribute] === item[attribute] || (!items[0][attribute] && !item[attribute]),
    ),
  )

const allAreEqualWithPermissionsAttribute = (items: (File | Folder)[]) => {
  const attributes = ['hidden', 'locked', 'lock_at', 'unlock_at']
  return allAreEqual(items, attributes)
}

const isTofallbackToDefault = (items: (File | Folder)[]) => {
  return items.length === 0 || !allAreEqualWithPermissionsAttribute(items)
}

export const defaultAvailabilityOption = (items: (File | Folder)[]) => {
  if (isTofallbackToDefault(items)) return AVAILABILITY_OPTIONS.published

  const item = items[0]
  if (item.locked) {
    return AVAILABILITY_OPTIONS.unpublished
  } else if (item.lock_at || item.unlock_at) {
    return AVAILABILITY_OPTIONS.date_range
  } else if (item.hidden) {
    return AVAILABILITY_OPTIONS.link_only
  } else {
    return AVAILABILITY_OPTIONS.published
  }
}

export const defaultDate = (items: (File | Folder)[], key: 'unlock_at' | 'lock_at') => {
  if (isTofallbackToDefault(items)) return null
  const item = items[0]
  return item[key]
}

export const defaultDateRangeType = (items: (File | Folder)[]) => {
  const startDate = defaultDate(items, 'unlock_at')
  const endDate = defaultDate(items, 'lock_at')
  if (startDate && endDate) {
    return DATE_RANGE_TYPE_OPTIONS.range
  }
  if (startDate) {
    return DATE_RANGE_TYPE_OPTIONS.start
  }
  if (endDate) {
    return DATE_RANGE_TYPE_OPTIONS.end
  }
  return null
}

export const defaultVisibilityOption = (
  items: (File | Folder)[],
  visibilityOptions: Record<string, VisibilityOption>,
) => {
  if (items.length === 0) return visibilityOptions.inherit

  if (visibilityOptions.keep) {
    return visibilityOptions.keep
  }
  const item = items[0]
  if (isFile(item) && item.visibility_level) return visibilityOptions[item.visibility_level]
  return visibilityOptions.inherit
}

interface ParseNewRowsParams {
  items: (File | Folder)[]
  availabilityOptionId: AvailabilityOptionId
  dateRangeType: DateRangeTypeOption | null
  currentRows: (File | Folder)[]
  unlockAt: string | null
  lockAt: string | null
}

export const parseNewRows = ({
  items,
  availabilityOptionId,
  dateRangeType,
  currentRows,
  unlockAt,
  lockAt,
}: ParseNewRowsParams): (File | Folder)[] => {
  const newRows = [...currentRows]
  items.forEach(item => {
    const index = newRows.findIndex(row => getUniqueId(row) === getUniqueId(item))
    if (index !== -1) {
      newRows[index].locked = availabilityOptionId === 'unpublished'
      newRows[index].hidden = availabilityOptionId === 'link_only'

      if (availabilityOptionId === 'date_range') {
        newRows[index].unlock_at = isStartDateRequired(dateRangeType) ? unlockAt : null
        newRows[index].lock_at = isEndDateRequired(dateRangeType) ? lockAt : null
      } else {
        newRows[index].unlock_at = null
        newRows[index].lock_at = null
      }
    }
  })
  return newRows
}
export const isStartDateRequired = (dateRangeType: DateRangeTypeOption | null) =>
  ['start', 'range'].includes(dateRangeType?.id || '')

export const isEndDateRequired = (dateRangeType: DateRangeTypeOption | null) =>
  ['end', 'range'].includes(dateRangeType?.id || '')
