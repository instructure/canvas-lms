/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export type Announcement = {
  id: string
  title: string
  message: string
  user_id: string
}

export type User = {
  id: string
  name: string
}

export const announcements: Announcement[] = JSON.parse(
  `
  [
    {
        "id": "1",
        "title": "Field Day Reminder!",
        "message": "\u003cp\u003ePlease remember to wear sneakers this Friday for Field Day activities!\u003c/p\u003e",
        "context_id": 1,
        "context_type": "Course",
        "user_id": "1",
        "workflow_state": "active",
        "last_reply_at": "2024-06-26T14:55:36Z",
        "created_at": "2024-06-26T14:55:36Z",
        "updated_at": "2024-06-26T14:55:36Z",
        "delayed_post_at": null,
        "posted_at": "2024-06-26T14:55:36Z",
        "assignment_id": null,
        "attachment_id": null,
        "deleted_at": null,
        "root_topic_id": null,
        "could_be_locked": false,
        "cloned_item_id": null,
        "context_code": "course_1",
        "position": 1,
        "migration_id": null,
        "old_assignment_id": null,
        "subtopics_refreshed_at": null,
        "last_assignment_id": null,
        "external_feed_id": null,
        "editor_id": null,
        "podcast_enabled": false,
        "podcast_has_student_posts": false,
        "require_initial_post": false,
        "discussion_type": "side_comment",
        "lock_at": null,
        "pinned": false,
        "locked": true,
        "group_category_id": null,
        "allow_rating": false,
        "only_graders_can_rate": false,
        "sort_by_rating": false,
        "todo_date": null,
        "is_section_specific": false,
        "root_account_id": 1,
        "anonymous_state": null,
        "is_anonymous_author": false,
        "reply_to_entry_required_count": 0,
        "unlock_at": null,
        "only_visible_to_overrides": false,
        "summary_enabled": false
    },
    {
      "id": "3",
      "title": "Course Feedback Survey",
      "message": "\u003cp\u003eWe value your feedback and invite you to participate in our course feedback survey. Your input is essential in helping us improve the course for future students.\u003c/p\u003e\u003cp\u003eThe survey is available online and can be accessed through the course website. It should take no more than 10 minutes to complete. Please submit your responses by the \u003cstrong\u003eend of the week\u003c/strong\u003e.\u003c/p\u003e",
      "context_id": "1",
      "context_type": "Course",
      "user_id": "1",
      "workflow_state": "active",
      "last_reply_at": "2024-06-28T19:09:30Z",
      "created_at": "2024-06-28T19:09:30Z",
      "updated_at": "2024-06-28T19:09:30Z",
      "delayed_post_at": null,
      "posted_at": "2024-06-28T19:09:30Z",
      "assignment_id": null,
      "attachment_id": null,
      "deleted_at": null,
      "root_topic_id": null,
      "could_be_locked": false,
      "cloned_item_id": null,
      "context_code": "course_1",
      "position": 3,
      "migration_id": null,
      "old_assignment_id": null,
      "subtopics_refreshed_at": null,
      "last_assignment_id": null,
      "external_feed_id": null,
      "editor_id": null,
      "podcast_enabled": false,
      "podcast_has_student_posts": false,
      "require_initial_post": false,
      "discussion_type": "side_comment",
      "lock_at": null,
      "pinned": false,
      "locked": true,
      "group_category_id": null,
      "allow_rating": false,
      "only_graders_can_rate": false,
      "sort_by_rating": false,
      "todo_date": null,
      "is_section_specific": false,
      "root_account_id": 1,
      "anonymous_state": null,
      "is_anonymous_author": false,
      "reply_to_entry_required_count": 0,
      "unlock_at": null,
      "only_visible_to_overrides": false,
      "summary_enabled": false
  }
]
  `
)

export const users = JSON.parse(`[
  {
      "id": "1",
      "name": "Kaiya Stanton"
    }
  ]`)
