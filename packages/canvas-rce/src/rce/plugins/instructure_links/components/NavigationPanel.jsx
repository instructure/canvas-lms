/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {bool, func, string} from 'prop-types'

import React from 'react'
import LinkSet from './LinkSet'
import formatMessage from '../../../../format-message'
import AccordionSection from './AccordionSection'

function typeCollection(contextId, contextType) {
  switch (contextType) {
    case 'course':
      return {
        links: [
          {
            href: `/courses/${contextId}`,
            title: formatMessage('Home'),
          },
          {
            href: `/courses/${contextId}/announcements`,
            title: formatMessage('Announcements'),
          },
          {
            href: `/courses/${contextId}/assignments`,
            title: formatMessage('Assignments'),
          },
          {
            href: `/courses/${contextId}/discussion_topics`,
            title: formatMessage('Discussions'),
          },
          {
            href: `/courses/${contextId}/grades`,
            title: formatMessage('Grades'),
          },
          {
            href: `/courses/${contextId}/users`,
            title: formatMessage('People'),
          },
          {
            href: `/courses/${contextId}/pages`,
            title: formatMessage('Pages'),
          },
          {
            href: `/courses/${contextId}/files`,
            title: formatMessage('Files'),
          },
          {
            href: `/courses/${contextId}/assignments/syllabus`,
            title: formatMessage('Syllabus'),
          },
          // outcomes
          {
            href: `/courses/${contextId}/quizzes`,
            title: formatMessage('Quizzes'),
          },
          {
            href: `/courses/${contextId}/modules`,
            title: formatMessage('Modules'),
          },
          // conferences
          {
            href: `/courses/${contextId}/collaborations`,
            title: formatMessage('Collaborations'),
          },
          // settings
        ],
      }
    case 'group':
      return {
        links: [
          {
            href: `/groups/${contextId}/pages`,
            title: formatMessage('Wiki Home'),
          },
          {
            href: `/groups/${contextId}/discussion_topics`,
            title: formatMessage('Discussions Index'),
          },
          {
            href: `/groups/${contextId}/announcements`,
            title: formatMessage('Announcement List'),
          },
          {
            href: `/groups/${contextId}/files`,
            title: formatMessage('Files Index'),
          },
          {
            href: `/groups/${contextId}/collaborations`,
            title: formatMessage('Collaborations'),
          },
          {
            href: `/groups/${contextId}/users`,
            title: formatMessage('People'),
          },
        ],
      }
    default:
      // user, TODO
      return {
        links: [
          {
            href: `/users/${contextId}/files`,
            title: formatMessage('Files Index'),
          },
        ],
      }
  }
}
export default function NavigationPanel(props) {
  const collection = typeCollection(props.contextId, props.contextType)
  let navigationSummary = ''
  if (props.contextType === 'course') {
    navigationSummary = formatMessage('Course Navigation')
  } else if (props.contextType === 'group') {
    navigationSummary = formatMessage('Group Navigation')
  } else {
    return null
  }

  return (
    <div data-testid="instructure_links-NavigationPanel">
      <AccordionSection
        collection="navigation"
        onToggle={props.onChangeAccordion}
        expanded={props.selectedAccordionIndex === 'navigation'}
        label={navigationSummary}
      >
        <LinkSet
          type="navigation"
          collection={collection}
          onLinkClick={props.onLinkClick}
          contextType={props.contextType}
          contextId={props.contextId}
          editing={props.editing}
          onEditClick={props.onEditClick}
        />
      </AccordionSection>
    </div>
  )
}

NavigationPanel.propTypes = {
  contextType: string.isRequired,
  contextId: string.isRequired,
  onChangeAccordion: func.isRequired,
  selectedAccordionIndex: string,
  onLinkClick: func,
  editing: bool,
  onEditClick: func,
}
