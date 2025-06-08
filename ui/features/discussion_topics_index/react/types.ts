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

export interface Permissions {
  create?: boolean
  manage_content?: boolean
  moderate?: boolean
}

export interface DiscussionTopicMenuTools {
  base_url: string
  canvas_icon_class?: string
  icon_url?: string
  title: string
}

export interface CourseSettings {
  allow_student_discussion_editing?: boolean
  allow_student_discussion_topics?: boolean
  allow_student_forum_attachments?: boolean
  allow_student_organized_groups?: boolean
  grading_standard_enabled?: boolean
  grading_standard_id?: boolean
  hide_distribution_graphs?: boolean
  hide_final_grades?: boolean
  home_page_announcement_limit?: number
}

export interface UserSettings {
  collapse_global_nav?: boolean
  manual_mark_as_read?: boolean
}

export type ButtonText = string
