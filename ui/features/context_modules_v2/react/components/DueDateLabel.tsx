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

import React, {useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {ModuleItemContent} from '../utils/types'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('context_modules_v2')
export interface DueDateLabelProps {
  contentTagId: string
  content: ModuleItemContent
}

const DueDateLabel: React.FC<DueDateLabelProps> = ({contentTagId, content}) => {
  const assignedToDates = content?.assignedToDates

  const tooltipContents = useMemo(() => {
    return (
      <span data-testid="override-details">
        {assignedToDates?.map((dateHash, index) => (
          <Flex justifyItems="center" key={`${contentTagId}_${index}`}>
            <Flex.Item margin="0 small">
              <Text weight="bold">{dateHash.title || 'Unknown'}</Text>
            </Flex.Item>
            <Flex.Item>
              <FriendlyDatetime
                data-testid="due-date"
                format={I18n.t('#date.formats.date_at_time')}
                dateTime={dateHash.dueAt || null}
                alwaysUseSpecifiedFormat={true}
              />
            </Flex.Item>
          </Flex>
        ))}
      </span>
    )
  }, [assignedToDates, contentTagId])

  if (assignedToDates?.length === 1) {
    const singleDate = assignedToDates[0]
    return (
      <Text size="x-small">
        <FriendlyDatetime
          data-testid="due-date"
          format={I18n.t('#date.formats.medium')}
          dateTime={singleDate.dueAt || null}
          alwaysUseSpecifiedFormat={true}
        />
      </Text>
    )
  } else if (assignedToDates && assignedToDates.length > 1) {
    return (
      <Tooltip renderTip={tooltipContents} on={['hover', 'focus']}>
        <Link href={`/courses/${ENV.course_id}/modules/items/${contentTagId}`} isWithinText={false}>
          <Text weight="normal" size="x-small">
            {I18n.t('Multiple Due Dates')}
          </Text>
        </Link>
      </Tooltip>
    )
  } else {
    return null
  }
}

export default DueDateLabel
