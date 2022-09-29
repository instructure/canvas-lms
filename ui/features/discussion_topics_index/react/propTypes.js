/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {shape, bool, number, string} from 'prop-types'

const propTypes = {}

propTypes.permissions = shape({
  create: bool.isRequired,
  manage_content: bool.isRequired,
  moderate: bool.isRequired,
})

propTypes.discussionTopicMenuTools = shape({
  base_url: string.isRequired,
  canvas_icon_class: string,
  icon_url: string,
  title: string.isRequired,
})

propTypes.courseSettings = shape({
  allow_student_discussion_editing: bool,
  allow_student_discussion_topics: bool,
  allow_student_forum_attachments: bool,
  allow_student_organized_groups: bool,
  grading_standard_enabled: bool,
  grading_standard_id: bool,
  hide_distribution_graphs: bool,
  hide_final_grades: bool,
  home_page_announcement_limit: number,
})

propTypes.userSettings = shape({
  collapse_global_nav: bool,
  manual_mark_as_read: bool,
})

export default propTypes
