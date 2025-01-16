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

import $ from 'jquery'
import 'jquery-migrate'
import SpeedGrader from '../speed_grader'
import SpeedGraderHelpers from '../speed_grader_helpers'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.ajaxJSON'

describe('SpeedGrader Comment Rendering', () => {
  let commentRenderingOptions
  const fixtures = document.createElement('div')
  fixtures.id = 'fixtures'

  const requiredDOMFixtures = `
    <div id="hide-assignment-grades-tray"></div>
    <div id="post-assignment-grades-tray"></div>
    <div id="speed_grader_assessment_audit_tray_mount_point"></div>
    <span id="speed_grader_post_grades_menu_mount_point"></span>
    <span id="speed_grader_settings_mount_point"></span>
    <div id="speed_grader_rubric_assessment_tray_wrapper"><div>
    <div id="speed_grader_assessment_audit_button_mount_point"></div>
    <div id="speed_grader_submission_comments_download_mount_point"></div>
    <div id="speed_grader_hidden_submission_pill_mount_point"></div>
    <div id="grades-loading-spinner"></div>
    <div id="grading"></div>
    <div id="settings_form">
      <select id="eg_sort_by" name="eg_sort_by">
        <option value="alphabetically"></option>
        <option value="submitted_at"></option>
        <option value="submission_status"></option>
        <option value="randomize"></option>
      </select>
      <input id="hide_student_names" type="checkbox" name="hide_student_names">
      <input id="enable_speedgrader_grade_by_question" type="checkbox" name="enable_speedgrader_grade_by_question">
      <button type="submit" class="submit_button"></button>
    </div>
  `

  const setupFixtures = (domStrings = '') => {
    fixtures.innerHTML = `${requiredDOMFixtures}${domStrings}`
    document.body.appendChild(fixtures)
    return fixtures
  }

  const teardownFixtures = () => {
    while (fixtures.firstChild) fixtures.removeChild(fixtures.firstChild)
    if (fixtures.parentNode) {
      fixtures.parentNode.removeChild(fixtures)
    }
  }

  beforeEach(() => {
    fakeENV.setup()
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      anonymous_grader_ids: ['asdfg', 'mry2b'],
    }

    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        score: 7,
        grade: 70,
        submission_comments: [
          {
            group_comment_id: null,
            publishable: false,
            anonymous: false,
            assessment_request_id: null,
            attachment_ids: '',
            author_id: 1000,
            author_name: 'An Author',
            comment: 'test',
            context_id: 1,
            context_type: 'Course',
            created_at: '2016-07-12T23:47:34Z',
            hidden: false,
            id: 11,
            posted_at: 'Jul 12 at 5:47pm',
            submission_id: 1,
            teacher_only_comment: false,
            updated_at: '2016-07-12T23:47:34Z',
          },
          {
            group_comment_id: null,
            publishable: false,
            anonymous: false,
            assessment_request_id: null,
            attachment_ids: '',
            cached_attachments: [
              {
                attachment: {
                  cloned_item_id: null,
                  content_type: 'video/mp4',
                  context_id: 1,
                  context_type: 'Assignment',
                  display_name: 'SampleVideo_1280x720_1mb (1).mp4',
                  filename: 'SampleVideo_1280x720_1mb.mp4',
                  id: 21,
                  media_entry_id: 'maybe',
                  mime_class: 'video',
                  size: 1055736,
                  workflow_state: 'processed',
                },
              },
            ],
            author_id: 1000,
            author_name: 'An Author',
            comment: 'test',
            context_id: 1,
            context_type: 'Course',
            created_at: '2016-07-13T23:47:34Z',
            hidden: false,
            id: 12,
            posted_at: 'Jul 12 at 5:47pm',
            submission_id: 1,
            teacher_only_comment: false,
            updated_at: '2016-07-13T23:47:34Z',
          },
        ],
      },
    }

    ENV.RUBRIC_ASSESSMENT = {
      assessment_type: 'grading',
      assessor_id: 1,
    }

    ENV.anonymous_identities = {
      mry2b: {id: 'mry2b', name: 'Grader 2'},
      asdfg: {id: 'asdfg', name: 'Grader 1'},
    }

    const commentBlankHtml = `
      <div class="comment">
        <span class="comment"></span>
        <button class="submit_comment_button">
          <span>Submit</span>
        </button>
        <div class="comment_citation">
          <span class="author_name"></span>
        </div>
        <a class="delete_comment_link icon-x">
          <span class="screenreader-only">Delete comment</span>
        </a>
        <div class="comment_attachments"></div>
      </div>
    `

    const commentAttachmentBlank = `
      <div class="comment_attachment">
        <a href="example.com/{{ submitter_id }}/{{ id }}/{{ comment_id }}">
          <span class="display_name">&nbsp;</span>
        </a>
      </div>
    `

    commentRenderingOptions = {
      commentBlank: $(commentBlankHtml),
      commentAttachmentBlank: $(commentAttachmentBlank),
    }

    setupFixtures()
  })

  afterEach(() => {
    teardownFixtures()
    fakeENV.teardown()
  })

  it('renders a comment with text content', () => {
    const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0]
    const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
    expect(renderedComment.find('span.comment').text()).toBe('test')
  })

  it('renders a comment with an attachment', () => {
    const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[1]
    const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
    expect(renderedComment.find('.comment_attachment a').text().trim()).toBe(
      'SampleVideo_1280x720_1mb (1).mp4',
    )
  })

  it('renders generic grader name when graders cannot view other grader names', () => {
    const studentWithAnonymousComment = {
      id: '4',
      index: 1,
      name: 'Michael B. Jordan',
      submission: {
        provisional_grades: [
          {
            anonymous_grader_id: 'mry2b',
            final: false,
            provisional_grade_id: '53',
            readonly: true,
            scorer_id: '1101',
          },
        ],
        submission_comments: [
          {
            anonymous_id: 'mry2b',
            comment: 'a comment',
            created_at: '2018-07-30T15:42:14Z',
            id: '44',
            author_id: 'mry2b',
            anonymous: true,
          },
        ],
      },
    }

    SpeedGrader.EG.currentStudent = studentWithAnonymousComment
    const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0]
    const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
    expect(renderedComment.find('.author_name').text().trim()).toBe('Grader 2')
  })

  it('should add comment text to delete link for screenreaders', () => {
    const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0]
    const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
    expect(renderedComment.find('.delete_comment_link .screenreader-only').text()).toBe(
      'Delete comment: test',
    )
  })

  it('refreshes provisional grader display names when names are stale', () => {
    const firstStudent = {
      id: '4',
      index: 1,
      name: 'Michael B. Jordan',
      submission: {
        provisional_grades: [
          {
            anonymous_grader_id: 'mry2b',
            final: false,
            provisional_grade_id: '53',
            readonly: true,
            scorer_id: '1101',
          },
        ],
        submission_comments: [
          {
            anonymous_id: 'mry2b',
            comment: 'a comment',
            created_at: '2018-07-30T15:42:14Z',
            id: '44',
            author_id: 'mry2b',
            anonymous: true,
          },
        ],
      },
    }
    const secondStudent = {
      id: '5',
      index: 2,
      name: 'Chadwick Boseman',
      submission: {
        provisional_grades: [
          {
            anonymous_grader_id: 'asdfg',
            final: false,
            provisional_grade_id: '54',
            readonly: true,
            scorer_id: '1102',
          },
        ],
        submission_comments: [
          {
            anonymous_id: 'asdfg',
            comment: 'canvas forever',
            created_at: '2018-07-30T15:43:14Z',
            id: '45',
            author_id: 'asdfg',
            anonymous: true,
          },
        ],
      },
    }

    SpeedGrader.EG.currentStudent = firstStudent
    SpeedGrader.EG.renderComment(
      SpeedGrader.EG.currentStudent.submission.submission_comments[0],
      commentRenderingOptions,
    )

    SpeedGrader.EG.currentStudent = secondStudent
    const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0]
    const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
    expect(renderedComment.find('.author_name').text().trim()).toBe('Grader 1')
  })
})
