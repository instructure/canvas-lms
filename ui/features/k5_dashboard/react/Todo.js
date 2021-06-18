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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import moment from 'moment-timezone'
import I18n from 'i18n!todo'

import {AccessibleContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Badge} from '@instructure/ui-badge'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconEndSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {ignoreTodo} from '@canvas/k5/react/utils'
import tz from '@canvas/timezone'

const Todo = ({assignment, context_name, html_url, ignore, needs_grading_count, timeZone}) => {
  const [ignored, setIgnored] = useState(false)

  // Only assignments are supported (ungraded_quizzes are not)
  if (!assignment || ignored) return null
  const {due_at, name, points_possible} = assignment

  const handleIgnoreTodo = () => {
    ignoreTodo(ignore)
      .then(() => setIgnored(true))
      .catch(showFlashError(I18n.t('Failed to ignore assignment')))
  }

  let dueDate = I18n.t('No Due Date')
  if (due_at) {
    const isSameYear = moment(due_at).isSame(moment().tz(timeZone), 'year')
    dueDate = tz.format(due_at, `date.formats.${isSameYear ? 'date_at_time' : 'full'}`)
  }

  return (
    <Flex as="div" alignItems="start" margin="medium 0 0">
      <Badge
        standalone
        count={needs_grading_count}
        countUntil={100}
        margin="0 small 0 0"
        formatOutput={formattedCount => (
          <AccessibleContent
            alt={I18n.t(
              {
                one: '1 submission needs grading',
                other: '%{count} submissions need grading'
              },
              {count: needs_grading_count}
            )}
          >
            {formattedCount}
          </AccessibleContent>
        )}
        theme={{
          fontSize: '1rem',
          fontWeight: '700',
          size: '1.5rem'
        }}
      />
      <Flex as="div" direction="column" margin="0 small 0 0" width="27rem">
        <Link
          href={html_url}
          isWithinText={false}
          theme={{
            fontWeight: '700'
          }}
        >
          <Text>{I18n.t('Grade %{assignment}', {assignment: name})}</Text>
        </Link>
        <Text color="secondary" transform="uppercase">
          {context_name}
        </Text>
        <Text color="secondary">
          <View>
            {I18n.t({one: '1 point', other: '%{count} points'}, {count: points_possible})}
          </View>
          {/* The dot is tiny in Balsamiq Sans, which is why we're forcing Lato here */}
          <PresentationContent>
            <View margin="0 small" theme={{fontFamily: 'Lato, Arial, sans-serif'}}>
              •
            </View>
          </PresentationContent>
          <View>{dueDate}</View>
        </Text>
      </Flex>
      <IconButton
        screenReaderLabel={I18n.t('Ignore %{assignment} until new submission', {
          assignment: name
        })}
        withBackground={false}
        withBorder={false}
        size="small"
        onClick={handleIgnoreTodo}
      >
        <IconEndSolid color="secondary" />
      </IconButton>
    </Flex>
  )
}

Todo.propTypes = {
  assignment: PropTypes.shape({
    due_at: PropTypes.string,
    name: PropTypes.string.isRequired,
    points_possible: PropTypes.number.isRequired
  }),
  context_name: PropTypes.string.isRequired,
  html_url: PropTypes.string.isRequired,
  ignore: PropTypes.string.isRequired,
  needs_grading_count: PropTypes.number,
  timeZone: PropTypes.string.isRequired
}

export default Todo
