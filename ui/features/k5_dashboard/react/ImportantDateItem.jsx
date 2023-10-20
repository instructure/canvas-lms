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

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  IconCalendarMonthLine,
  IconDiscussionLine,
  IconQuizLine,
  IconAssignmentLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {TruncateText} from '@instructure/ui-truncate-text'

import {getK5ThemeVars} from '@canvas/k5/react/k5-theme'

const k5ThemeVariables = getK5ThemeVars()

const I18n = useI18nScope('important_date_item')

const itemTypes = [
  {
    type: 'event',
    icon: <IconCalendarMonthLine />,
    label: I18n.t('Calendar Event'),
  },
  {
    type: 'discussion_topic',
    icon: <IconDiscussionLine />,
    label: I18n.t('Discussion'),
  },
  {
    type: 'online_quiz',
    icon: <IconQuizLine />,
    label: I18n.t('Quiz'),
  },
  {
    type: 'assignment',
    icon: <IconAssignmentLine />,
    label: I18n.t('Assignment'),
  },
]

const ItemIcon = ({type, color}) => {
  let itemDetails = itemTypes.find(i => i.type === type)
  if (!itemDetails) {
    itemDetails = itemTypes.find(i => i.type === 'assignment')
  }
  return (
    <AccessibleContent alt={itemDetails.label}>
      <span style={{color}} data-testid="date-icon-wrapper">
        {itemDetails.icon}
      </span>
    </AccessibleContent>
  )
}

const ImportantDateItem = ({title, context, color, type, url}) => (
  <View
    as="div"
    borderWidth="small"
    borderRadius="medium"
    margin="x-small 0"
    padding="x-small small"
    background="primary"
  >
    <Text data-testid="important-date-subject" as="div" size="x-small">
      {context}
    </Text>
    <TruncateText maxLines={2}>
      <Text as="div" weight="bold">
        <ItemIcon type={type} color={color} />
        &nbsp;
        <Link
          data-testid="important-date-link"
          href={url}
          isWithinText={false}
          themeOverride={{
            color: k5ThemeVariables.colors.textDarkest,
            hoverColor: k5ThemeVariables.colors.textDarkest,
            fontWeight: 700,
          }}
        >
          {title}
        </Link>
      </Text>
    </TruncateText>
  </View>
)

export const ImportantDateItemShape = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  context: PropTypes.string.isRequired,
  color: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
}

ImportantDateItem.propTypes = {
  ...ImportantDateItemShape,
}

export default ImportantDateItem
