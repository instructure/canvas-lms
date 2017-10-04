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

import { updateSubmissionComment } from 'jsx/gradezilla/default_gradebook/apis/SubmissionCommentApi';
import { underscore } from 'convert_case';

QUnit.module('SubmissionCommentApi.updateSubmissionComment', function (hooks) {
  let server;
  const commentId = '12';
  const url = `/submission_comments/${commentId}`;
  const updatedComment = 'an updated comment!';
  const editedAt = '2015-10-12T19:25:41Z';
  const submissionComment = {
    id: commentId,
    created_at: '2015-10-09T19:25:41Z',
    comment: updatedComment,
    edited_at: editedAt
  };
  const responseBody = JSON.stringify({ submission_comment: underscore(submissionComment) });

  hooks.beforeEach(function () {
    server = sinon.fakeServer.create({ respondImmediately: true });
  });

  hooks.afterEach(function () {
    server.restore();
  });

  test('on success, returns the submission comment with the updated comment', function () {
    server.respondWith('PUT', url, [200, { 'Content-Type': 'application/json' }, responseBody]);
    return updateSubmissionComment(commentId, updatedComment).then((response) => {
      strictEqual(response.data.comment, updatedComment);
    });
  });

  test('on success, returns the submission comment with an updated editedAt', function () {
    server.respondWith('PUT', url, [200, { 'Content-Type': 'application/json' }, responseBody]);
    return updateSubmissionComment(commentId, updatedComment).then((response) => {
      strictEqual(response.data.editedAt.getTime(), new Date(editedAt).getTime());
    });
  });

  test('on failure, returns a rejected promise with the error', function () {
    server.respondWith('PUT', url, [500, { 'Content-Type': 'application/json' }, JSON.stringify({})]);
    return updateSubmissionComment(commentId, updatedComment).catch((error) => {
      strictEqual(error.response.status, 500);
    });
  });
});
