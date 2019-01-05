/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import List, { ListItem } from '@instructure/ui-elements/lib/components/List'
import Text from '@instructure/ui-elements/lib/components/Text'
import Link from '@instructure/ui-elements/lib/components/Link'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import IconSettings from '@instructure/ui-icons/lib/Line/IconSettings'
import IconSyllabus from '@instructure/ui-icons/lib/Line/IconSyllabus'
import IconAssignment from '@instructure/ui-icons/lib/Line/IconAssignment'
import IconCalendarMonth from '@instructure/ui-icons/lib/Line/IconCalendarMonth'
import IconDiscussion from '@instructure/ui-icons/lib/Line/IconDiscussion'
import IconModule from '@instructure/ui-icons/lib/Line/IconModule'
import IconQuiz from '@instructure/ui-icons/lib/Line/IconQuiz'
import IconQuestion from '@instructure/ui-icons/lib/Line/IconQuestion'
import IconDocument from '@instructure/ui-icons/lib/Line/IconDocument'
import IconImage from '@instructure/ui-icons/lib/Solid/IconImage'
import IconLink from '@instructure/ui-icons/lib/Solid/IconLink'
import I18n from 'i18n!link_validator'

const TYPE_INFO = {
  course_card_image:    { icon: IconSettings,      label: I18n.t('Course Settings') },
  syllabus:             { icon: IconSyllabus,      label: I18n.t('Syllabus') },
  assignment:           { icon: IconAssignment,    label: I18n.t('Assignment') },
  calendar_event:       { icon: IconCalendarMonth, label: I18n.t('Event') },
  discussion_topic:     { icon: IconDiscussion,    label: I18n.t('Discussion') },
  module:               { icon: IconModule,        label: I18n.t('Module') },
  quiz:                 { icon: IconQuiz,          label: I18n.t('Quiz') },
  wiki_page:            { icon: IconDocument,      label: I18n.t('Page') },
  assessment_question:  { icon: IconQuestion,      label: I18n.t('Assessment Question') },
  quiz_question:        { icon: IconQuestion,      label: I18n.t('Quiz Question') }
}

const REASON_DESCRIPTION = {
  course_mismatch: I18n.t('Links to other courses in this resource may not be accessible by the students in this course:'),
  unpublished_item: I18n.t('Unpublished content referenced in this resource:'),
  missing_item: I18n.t('Non-existent content referenced in this resource:'),
  broken_link: I18n.t('External links in this resource were unreachable:'),
  broken_image: I18n.t('External images in this resource were unreachable:')
}

function simplifyReason(link) {
  switch(link.reason) {
    case 'course_mismatch':
    case 'unpublished_item':
    case 'missing_item':
      return link.reason
    default:
      return link.image ? 'broken_image' : 'broken_link'
  }
}

function getLinkText(link) {
  if (link.link_text) {
    return link.link_text
  }
  return link.url.substring(link.url.lastIndexOf('/') + 1)
}

export default function ValidatorResultsRow(props) {
  const invalid_links = props.result.invalid_links
  const errorsByReason = {}
  invalid_links.forEach(link => {
    const reason = simplifyReason(link)
    errorsByReason[reason] = errorsByReason[reason] || []
    errorsByReason[reason].push(link)
  })

  const rows = []
  Object.keys(errorsByReason).forEach(reason => {
    const errors = errorsByReason[reason]
    const links = []

    errors.forEach(error => {
      const IconClass = error.image ? IconImage : IconLink
      const link_text = getLinkText(error)
      const link = <ListItem key={error.url}>
          <IconClass color="success"/>
          &ensp;
          <Link href={error.url}>{link_text}</Link>
        </ListItem>
      links.push(link)
    })

    rows.push(
      <ListItem key={reason}>
        {REASON_DESCRIPTION[reason]}
        <List variant="unstyled" margin="none x-small small small">
          {links}
        </List>
      </ListItem>
    )
  })

  let TypeIcon, label
  const typeInfo = TYPE_INFO[props.result.type]
  if (typeInfo) {
    TypeIcon = typeInfo.icon
    label = typeInfo.label
  } else {
    TypeIcon = IconDocument
    label = props.result.type
  }

  return (
    <div className="result">
      <Flex>
        <FlexItem align="start">
          <TypeIcon color="success" size="small"/>
        </FlexItem>
        <FlexItem margin="none none none small">
          <Heading level="h3" as="h2">
            <Link href={props.result.content_url}>{props.result.name}</Link>
          </Heading>
          <Text size="x-small" transform="uppercase" lineHeight="condensed" letterSpacing="expanded">{label}</Text>
        </FlexItem>
      </Flex>
      <List margin="none x-small small x-large">
        {rows}
      </List>
    </div>
  )
}
