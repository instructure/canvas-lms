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
import React from 'react'
import {string, oneOf} from 'prop-types'
import '@canvas/content-locks/jquery/lock_reason'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'

import locked1SVG from '../images/Locked1.svg'

const I18n = useI18nScope('assignments_2')

export default function DateLocked(props) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item>
        <img alt={I18n.t('Assignment locked until future date')} src={locked1SVG} />
      </Flex.Item>
      <Flex.Item>
        <Flex margin="small" direction="column" alignItems="center" justifyContent="center">
          <Flex.Item>
            <Heading size="large" data-testid="assignments-2-date-locked" margin="small">
              {INST.lockExplanation({unlock_at: props.date}, props.type)}
            </Heading>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

DateLocked.propTypes = {
  date: string.isRequired,
  type: oneOf(['assignment', 'quiz', 'topic', 'file', 'page']),
}
