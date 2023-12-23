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

import axios from '@canvas/axios'
import * as timezone from '@canvas/datetime'
import type {SubmissionComment, SubmissionCommentData} from '../../../../../api.d'
import type {SerializedComment} from '../gradebook.d'

function deserializeComment(comment: SubmissionComment): SerializedComment {
  const baseComment = {
    id: comment.id,
    createdAt: timezone.parse(comment.created_at),
    comment: comment.comment,
    editedAt: comment.edited_at && timezone.parse(comment.edited_at),
  }

  if (!comment.author) {
    // @ts-expect-error
    return baseComment
  }

  // @ts-expect-error
  return {
    ...baseComment,
    authorId: comment.author.id,
    author: comment.author.display_name,
    authorAvatarUrl: comment.author.avatar_image_url,
    authorUrl: comment.author.html_url,
  }
}

function deserializeComments(comments: SubmissionComment[]) {
  return comments.map(deserializeComment)
}

function getSubmissionComments(courseId: string, assignmentId: string, studentId: string) {
  const commentOptions = {params: {include: 'submission_comments'}}
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`
  return axios
    .get(url, commentOptions)
    .then(response => deserializeComments(response.data.submission_comments))
}

function createSubmissionComment(
  courseId: string,
  assignmentId: string,
  studentId: string,
  commentData: SubmissionCommentData
) {
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`
  const data = {comment: commentData}
  return axios
    .put(url, data)
    .then(response => deserializeComments(response.data.submission_comments))
}

function deleteSubmissionComment(commentId: string) {
  const url = `/submission_comments/${commentId}`
  return axios.delete(url)
}

function updateSubmissionComment(commentId: string, comment: string) {
  const url = `/submission_comments/${commentId}`
  const data = {id: commentId, submission_comment: {comment}}
  return axios
    .put(url, data)
    .then(response => ({data: deserializeComment(response.data.submission_comment)}))
}

export default {
  createSubmissionComment,
  deleteSubmissionComment,
  getSubmissionComments,
  updateSubmissionComment,
}
