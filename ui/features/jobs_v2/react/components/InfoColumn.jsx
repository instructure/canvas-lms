/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import React, {useMemo, useCallback} from 'react'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

const I18n = useI18nScope('jobs_v2')

const SUPER_SLOW_RUN_TIME = 6000
const SLOW_RUN_TIME = 600

const SUPER_SLOW_QUEUE_TIME = 6000
const SLOW_QUEUE_TIME = 600

const SECONDS_PER_DAY = 86400

export function GroupedInfoColumnHeader({bucket}) {
  const columnTitles = useMemo(() => {
    return {
      queued: I18n.t('Max wait time'),
      running: I18n.t('Max run time'),
      future: I18n.t('Next run at'),
      failed: I18n.t('Last failed at'),
    }
  }, [])

  return <Text>{columnTitles[bucket]}</Text>
}

export function InfoColumnHeader({bucket}) {
  const columnTitles = useMemo(() => {
    return {
      queued: I18n.t('Wait time'),
      running: I18n.t('Run time'),
      future: I18n.t('Run at'),
      failed: I18n.t('Failed at'),
    }
  }, [])

  return <Text>{columnTitles[bucket]}</Text>
}

export function InfoColumn({bucket, info, timeZone}) {
  const formatDate = useDateTimeFormat('date.formats.full_compact', timeZone)

  const formatSeconds = useCallback(seconds => {
    let format
    if (seconds > SECONDS_PER_DAY * 30) {
      return I18n.t('%{num} days', {num: Math.floor(seconds / SECONDS_PER_DAY)})
    } else if (seconds > SECONDS_PER_DAY) {
      format = 'd\\dHH:mm:ss'
    } else {
      format = 'HH:mm:ss'
    }
    return new Date(null, null, null, null, null, seconds).toString(format)
  }, [])

  const columnText = useCallback(() => {
    if (bucket === 'future' || bucket === 'failed') {
      return formatDate(info)
    } else {
      return formatSeconds(info)
    }
  }, [bucket, info, formatDate, formatSeconds])

  const columnColor = useCallback(() => {
    if (bucket === 'running') {
      if (info > SUPER_SLOW_RUN_TIME) {
        return 'alert'
      } else if (info > SLOW_RUN_TIME) {
        return 'danger'
      } else {
        return 'primary'
      }
    } else if (bucket === 'queued') {
      if (info > SUPER_SLOW_QUEUE_TIME) {
        return 'alert'
      } else if (info > SLOW_QUEUE_TIME) {
        return 'danger'
      } else {
        return 'primary'
      }
    } else {
      return 'primary'
    }
  }, [bucket, info])

  return <Text color={columnColor()}>{columnText()}</Text>
}
