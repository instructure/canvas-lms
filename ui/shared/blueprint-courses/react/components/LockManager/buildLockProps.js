/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const buildProps = options =>
  Object.assign(
    {
      assignment: {
        toggleWrapperSelector: {
          show: '.assignment-buttons',
          edit: '.header-bar .header-bar-right .header-group-left',
        }[options.page],
        itemIdPath: {
          show: 'ASSIGNMENT_ID',
          edit: 'ASSIGNMENT.id',
        }[options.page],
      },
      quiz: {
        toggleWrapperSelector: {
          show: '.header-group-left',
          edit: '.header-bar .header-bar-right .header-group-left',
        }[options.page],
        toggleWrapperChildIndex: {
          edit: 2,
        }[options.page],
        itemIdPath: 'QUIZ.id',
      },
      discussion_topic: {
        toggleWrapperSelector: {
          show: '.form-inline .pull-right',
          edit: '.discussion-edit-header .text-right',
        }[options.page],
        itemIdPath: {
          show: 'DISCUSSION.TOPIC.ID',
          edit: 'DISCUSSION_TOPIC.ATTRIBUTES.id',
        }[options.page],
      },
      wiki_page: {
        toggleWrapperSelector: {
          show: '.blueprint-label',
        }[options.page],
        itemIdPath: 'WIKI_PAGE.page_id',
      },
      course_pace: {
        toggleWrapperSelector: {
          show: '.blueprint-label',
        }[options.page],
        itemIdPath: 'COURSE_PACE_ID',
      },
    }[options.itemType],
    options
  )

export default buildProps
