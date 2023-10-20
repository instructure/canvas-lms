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
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {
  IconSettingsLine,
  IconSyllabusLine,
  IconAssignmentLine,
  IconCalendarMonthLine,
  IconDiscussionLine,
  IconModuleLine,
  IconQuizLine,
  IconQuestionLine,
  IconDocumentLine,
  IconImageSolid,
  IconLinkSolid,
} from '@instructure/ui-icons'
import sanitizeUrl from '@canvas/util/sanitizeUrl'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('link_validator')

const TYPE_INFO = {
  course_card_image: {icon: IconSettingsLine, label: I18n.t('Course Settings')},
  syllabus: {icon: IconSyllabusLine, label: I18n.t('Syllabus')},
  assignment: {icon: IconAssignmentLine, label: I18n.t('Assignment')},
  calendar_event: {icon: IconCalendarMonthLine, label: I18n.t('Event')},
  discussion_topic: {icon: IconDiscussionLine, label: I18n.t('Discussion')},
  module: {icon: IconModuleLine, label: I18n.t('Module')},
  quiz: {icon: IconQuizLine, label: I18n.t('Quiz')},
  wiki_page: {icon: IconDocumentLine, label: I18n.t('Page')},
  assessment_question: {icon: IconQuestionLine, label: I18n.t('Assessment Question')},
  quiz_question: {icon: IconQuestionLine, label: I18n.t('Quiz Question')},
}

const REASON_DESCRIPTION = {
  course_mismatch: I18n.t(
    'Links to other courses in this resource may not be accessible by the students in this course:'
  ),
  unpublished_item: I18n.t('Unpublished content referenced in this resource:'),
  missing_item: I18n.t('Non-existent content referenced in this resource:'),
  broken_link: I18n.t('External links in this resource were unreachable:'),
  broken_image: I18n.t('External images in this resource were unreachable:'),
  deleted: I18n.t('Deleted content referenced in this resource:'),
}

function simplifyReason(link) {
  switch (link.reason) {
    case 'course_mismatch':
    case 'unpublished_item':
    case 'deleted':
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
      const IconClass = error.image ? IconImageSolid : IconLinkSolid
      const link_text = getLinkText(error)
      const link = (
        <List.Item key={error.url}>
          <IconClass color="success" />
          &ensp;
          <Link href={sanitizeUrl(error.url)}>{link_text}</Link>
        </List.Item>
      )
      links.push(link)
    })

    rows.push(
      <List.Item key={reason}>
        {REASON_DESCRIPTION[reason]}
        <List isUnstyled={true} margin="none x-small small small">
          {links}
        </List>
      </List.Item>
    )
  })

  let TypeIcon, label
  const typeInfo = TYPE_INFO[props.result.type]
  if (typeInfo) {
    TypeIcon = typeInfo.icon
    label = typeInfo.label
  } else {
    TypeIcon = IconDocumentLine
    label = props.result.type
  }

  return (
    <div className="result">
      <Flex>
        <Flex.Item align="start">
          <TypeIcon color="success" size="small" />
        </Flex.Item>
        <Flex.Item margin="none none none small">
          <Heading level="h3" as="h2">
            <Link
              href={props.result.content_url}
              isWithinText={false}
              themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: '1.25rem'}}
            >
              {props.result.name}
            </Link>
          </Heading>
          <Text
            size="x-small"
            transform="uppercase"
            lineHeight="condensed"
            letterSpacing="expanded"
          >
            {label}
          </Text>
        </Flex.Item>
      </Flex>
      <List margin="none x-small small x-large">{rows}</List>
    </div>
  )
}
