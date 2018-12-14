/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery';
import ReactDOM from 'react-dom';

import SpeedGrader from 'speed_grader';
import SpeedGraderHelpers from 'speed_grader_helpers';

import _ from 'underscore';
import JQuerySelectorCache from 'jsx/shared/helpers/JQuerySelectorCache';
import fakeENV from 'helpers/fakeENV';
import natcompare from 'compiled/util/natcompare';
import numberHelper from 'jsx/shared/helpers/numberHelper';
import userSettings from 'compiled/userSettings';
import htmlEscape from 'str/htmlEscape';

const {unescape} = htmlEscape;

import 'jquery.ajaxJSON';

const fixtures = document.getElementById('fixtures')
const setupCurrentStudent = () => SpeedGrader.EG.handleStudentChanged()
const requiredDOMFixtures = `
  <div id="speed_grader_assessment_audit_tray_mount_point"></div>
  <span id="speed_grader_settings_mount_point"></span>
  <div id="speed_grader_assessment_audit_button_mount_point"></div>
  <div id="speed_grader_submission_comments_download_mount_point"></div>
`;

let $div
let disableWhileLoadingStub
let rubricAssessmentDataStub

function setupFixtures (domStrings = '') {
  fixtures.innerHTML = `
    ${requiredDOMFixtures}
    ${domStrings}
  `;
  return fixtures;
}

function teardownFixtures() {
  // fast remove
  while (fixtures.firstChild) fixtures.removeChild(fixtures.firstChild);
}

QUnit.module('SpeedGrader#showDiscussion', {
  setup () {
    const commentBlankHtml = `
      <div id="comments">
      </div>
      <div id="comment_blank">
        <a class="play_comment_link"></a>
        <div class="comment">
          <div class="comment_flex">
            <span class="comment"></span>
          </div>
        </div>
      </div>
    `;

    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    setupFixtures(commentBlankHtml);
    sandbox.stub($, 'ajaxJSON');
    sandbox.spy($.fn, 'append');
    this.originalWindowJSONData = window.jsonData;
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10
    };
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        score: 7,
        grade: 70,
        submission_comments: [{
          group_comment_id: null,
          publishable: false,
          anonymous: false,
          assessment_request_id: null,
          attachment_ids: '',
          author_id: 1000,
          author_name: 'An Author',
          comment: 'a comment!',
          context_id: 1,
          context_type: 'Course',
          created_at: '2016-07-12T23:47:34Z',
          hidden: false,
          id: 11,
          media_comment_id: 3,
          media_comment_type: 'video',
          posted_at: 'Jul 12 at 5:47pm',
          submission_id: 1,
          teacher_only_comment: false,
          updated_at: '2016-07-12T23:47:34Z'
        }]
      }
    };
    ENV.SUBMISSION = {
      grading_role: 'teacher'
    };
    ENV.RUBRIC_ASSESSMENT = {
      assessment_type: 'grading',
      assessor_id: 1
    };

    sinon.stub($, 'getJSON')
    sinon.stub(SpeedGrader.EG, 'domReady')
    SpeedGrader.setup()
  },

  teardown () {
    SpeedGrader.EG.domReady.restore()
    $.getJSON.restore()
    SpeedGrader.EG.currentStudent = this.originalStudent;
    window.jsonData = this.originalWindowJSONData;
    teardownFixtures();
    fakeENV.teardown();
  }
});

test('showDiscussion should not show private comments for a group assignment', () => {
  window.jsonData.GROUP_GRADING_MODE = true;
  SpeedGrader.EG.currentStudent.submission.submission_comments[0].group_comment_id = null;
  SpeedGrader.EG.showDiscussion();
  sinon.assert.notCalled($.fn.append);
});

test('showDiscussion should show group comments for group assignments', () => {
  window.jsonData.GROUP_GRADING_MODE = true;
  SpeedGrader.EG.currentStudent.submission.submission_comments[0].group_comment_id = 'hippo';
  SpeedGrader.EG.showDiscussion();
  strictEqual(document.querySelector('.comment').innerText, 'a comment!')
});

test('showDiscussion should show private comments for non group assignments', () => {
  window.jsonData.GROUP_GRADING_MODE = false;
  SpeedGrader.EG.currentStudent.submission.submission_comments[0].group_comment_id = null;
  SpeedGrader.EG.showDiscussion();
  sinon.assert.calledTwice($.fn.append);
});

test('thumbnails of media comments have screenreader text', () => {
  const originalKalturaSettings = INST.kalturaSettings
  INST.kalturaSettings = { resource_domain: "example.com", partner_id: "asdf" }
  sinon.stub(_, 'defer').callsFake((func, elem, size, keepOriginalText) => {
    func(elem, size, keepOriginalText)
  })
  SpeedGrader.EG.showDiscussion()
  const screenreaderText = document.querySelector(".play_comment_link .screenreader-only").innerText
  strictEqual(screenreaderText, "Play media comment by An Author from Jul 12, 2016 at 11:47pm.")
  INST.kalturaSettings = originalKalturaSettings
})

QUnit.module('SpeedGrader#refreshSubmissionsToView', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    setupFixtures('<span id="multiple_submissions"></span>')
    sandbox.stub($, 'ajaxJSON');
    sandbox.spy($.fn, 'append');
    this.originalWindowJSONData = window.jsonData;
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
      anonymize_students: false
    };
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        score: 7,
        grade: 70,
        submission_history: [
          {
            submission_type: 'basic_lti_launch',
            external_tool_url: 'foo',
            submitted_at: new Date('Jan 1, 2010').toISOString()
          },
          {
            submission_type: 'basic_lti_launch',
            external_tool_url: 'bar',
            submitted_at: new Date('Feb 1, 2010').toISOString()
          }
        ]
      }
    };
    sinon.stub($, 'getJSON')
    sinon.stub(SpeedGrader.EG, 'domReady')
  },

  teardown () {
    SpeedGrader.EG.domReady.restore()
    $.getJSON.restore()
    window.jsonData = this.originalWindowJSONData;
    SpeedGrader.EG.currentStudent = this.originalStudent;
    teardownFixtures()
    fakeENV.teardown();
  }
})

test('can handle non-nested submission history', () => {
  SpeedGrader.setup()
  SpeedGrader.EG.refreshSubmissionsToView();
  ok(true, 'should not throw an exception');
})

test('includes submission time for submissions when not anonymizing', () => {
  SpeedGrader.setup()
  SpeedGrader.EG.refreshSubmissionsToView()

  const submissionDropdown = document.getElementById('multiple_submissions')
  ok(submissionDropdown.innerHTML.includes('Jan 1, 2010'))
})

test('includes submission time for submissions when the user is an admin', () => {
  ENV.current_user_roles = ['admin']
  window.jsonData.anonymize_students = true
  SpeedGrader.setup()

  SpeedGrader.EG.refreshSubmissionsToView()

  const submissionDropdown = document.getElementById('multiple_submissions')
  ok(submissionDropdown.innerHTML.includes('Jan 1, 2010'))
})

test('omits submission time for submissions when anonymizing and not an admin', () => {
  ENV.current_user_roles = ['teacher']
  SpeedGrader.setup()

  window.jsonData.anonymize_students = true
  SpeedGrader.EG.refreshSubmissionsToView()

  const submissionDropdown = document.getElementById('multiple_submissions')
  notOk(submissionDropdown.innerHTML.includes('Jan 1, 2010'))
})

QUnit.module('#showSubmissionDetails', function(hooks) {
  let originalWindowJSONData
  let originalStudent

  hooks.beforeEach(function() {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    sinon.stub(SpeedGrader.EG, 'handleSubmissionSelectionChange')
    originalWindowJSONData = window.jsonData
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10
    }
    originalStudent = SpeedGrader.EG.currentStudent
    SpeedGrader.EG.currentStudent = {
      id: 4,
      submission_state: 'not_graded',
      submission: { score: 7, grade: 70, submission_history: [] }
    }
    setupFixtures('<div id="submission_details">Submission Details</div>');
    sinon.stub($, 'getJSON')
    sinon.stub($, 'ajaxJSON')
    sinon.stub(SpeedGrader.EG, 'domReady')
    SpeedGrader.setup()
  })

  hooks.afterEach(function() {
    SpeedGrader.EG.domReady.restore()
    $.ajaxJSON.restore()
    $.getJSON.restore()
    teardownFixtures()
    window.jsonData = originalWindowJSONData
    SpeedGrader.EG.currentStudent = originalStudent
    SpeedGrader.EG.handleSubmissionSelectionChange.restore()
    fakeENV.teardown()
  })

  test('shows submission details', function() {
    SpeedGrader.EG.showSubmissionDetails()
    strictEqual($('#submission_details').is(':visible'), true)
  })

  test('hides submission details', function() {
    SpeedGrader.EG.currentStudent.submission = { workflow_state: 'unsubmitted' }
    SpeedGrader.EG.showSubmissionDetails()
    strictEqual($('#submission_details').is(':visible'), false)
  })
})

QUnit.module('SpeedGrader#refreshGrades', {
  setup () {
    fakeENV.setup();
    sandbox.spy($.fn, 'append');
    this.originalWindowJSONData = window.jsonData;
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10
    };
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'graded',
      submission: {
        score: 7,
        grade: 70
      }
    };
    sinon.stub($, 'getJSON');
  },

  teardown () {
    window.jsonData = this.originalWindowJSONData;
    SpeedGrader.EG.currentStudent = this.originalStudent;
    fakeENV.teardown();
    $.getJSON.restore();
  }
})

test('makes request to API', () => {
  SpeedGrader.EG.refreshGrades();
  ok($.getJSON.calledWithMatch('submission_history'));
})

let commentRenderingOptions;
QUnit.module('SpeedGrader#renderComment', {
  setup () {
    fakeENV.setup();
    this.originalWindowJSONData = window.jsonData;
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      anonymous_grader_ids: ['asdfg', 'mry2b']
    };
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        score: 7,
        grade: 70,
        submission_comments: [{
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
          updated_at: '2016-07-12T23:47:34Z'
        }, {
          group_comment_id: null,
          publishable: false,
          anonymous: false,
          assessment_request_id: null,
          attachment_ids: '',
          cached_attachments: [{
            attachment: {
              cloned_item_id: null,
              content_type: 'video/mp4',
              context_id: 1,
              context_type: 'Assignment',
              could_be_locked: null,
              created_at: '2017-01-23T22:23:11Z',
              deleted_at: null,
              display_name: 'SampleVideo_1280x720_1mb (1).mp4',
              encoding: null,
              file_state: 'available',
              filename: 'SampleVideo_1280x720_1mb.mp4',
              folder_id: null,
              id: 21,
              lock_at: null,
              locked: false,
              md5: 'd55bddf8d62910879ed9f605522149a8',
              media_entry_id: 'maybe',
              migration_id: null,
              modified_at: '2017-01-23T22:23:11Z',
              namespace: '_localstorage_/account_1',
              need_notify: null,
              position: null,
              replacement_attachment_id: null,
              root_attachment_id: 19,
              size: 1055736,
              unlock_at: null,
              updated_at: '2017-01-23T22:23:11Z',
              upload_error_message: null,
              usage_rights_id: null,
              user_id: 1,
              uuid: 'zR4YRxttAe8Aw53vmcOmUWCGq8g443Mqb8dr7IsJ',
              viewed_at: null,
              workflow_state: 'processed'
            }
          }],
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
          updated_at: '2016-07-13T23:47:34Z'
        }]
      }
    };
    ENV.RUBRIC_ASSESSMENT = {
      assessment_type: 'grading',
      assessor_id: 1
    };

    ENV.anonymous_identities = {
      mry2b: { id: 'mry2b', name: 'Grader 2' },
      asdfg: { id: 'asdfg', name: 'Grader 1' }
    };

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
    `;

    const commentAttachmentBlank = `
      <div class="comment_attachment">
        <a href="example.com/{{ submitter_id }}/{{ id }}/{{ comment_id }}"><span class="display_name">&nbsp;</span></a>
      </div>
    `;

    commentRenderingOptions = { commentBlank: $(commentBlankHtml), commentAttachmentBlank: $(commentAttachmentBlank) };
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    window.jsonData = this.originalWindowJSONData;
    fakeENV.teardown();
  }
});

test('renderComment renders a comment', () => {
  const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
  const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
  const commentText = renderedComment.find('span.comment').text();

  equal(commentText, 'test');
});

test('renderComment renders a comment with an attachment', () => {
  const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[1];
  const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
  const commentText = renderedComment.find('.comment_attachment a').text();

  equal(commentText, 'SampleVideo_1280x720_1mb (1).mp4');
});

test('renderComment should add the comment text to the delete link for screenreaders', () => {
  const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
  const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
  const deleteLinkScreenreaderText = renderedComment.find('.delete_comment_link .screenreader-only').text();

  equal(deleteLinkScreenreaderText, 'Delete comment: test');
});

test('renders a generic grader name when graders cannot view other grader names', () => {
  SpeedGrader.EG.currentStudent = {
    id: '4',
    index: 1,
    name: 'Michael B. Jordan',
    submission: {
      provisional_grades: [
        {
          anonymous_grader_id: 'mry2b',
          final: false,
          provisional_grade_id: '53',
          readonly: true
        }
      ],
      submission_comments: [
        {
          anonymous_id: 'mry2b',
          comment: 'a comment',
          created_at: '2018-07-30T15:42:14Z',
          id: '44'
        }
      ]
    }
  };
  const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
  const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
  const authorName = renderedComment.find('.author_name').text();
  strictEqual(authorName, 'Grader 2');
});

test('refreshes provisional grader display names when names are stale after switching students', () => {
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
          readonly: true
        }
      ],
      submission_comments: [
        {
          anonymous_id: 'mry2b',
          comment: 'a comment',
          created_at: '2018-07-30T15:42:14Z',
          id: '44'
        }
      ]
    }
  };
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
          readonly: true
        }
      ],
      submission_comments: [
        {
          anonymous_id: 'asdfg',
          comment: 'canvas forever',
          created_at: '2018-07-30T15:43:14Z',
          id: '45'
        }
      ]
    }
  };

  SpeedGrader.EG.currentStudent = firstStudent;
  SpeedGrader.EG.renderComment(SpeedGrader.EG.currentStudent.submission.submission_comments[0], commentRenderingOptions);

  SpeedGrader.EG.currentStudent = secondStudent;
  const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0]
  const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
  const authorName = renderedComment.find('.author_name').text();
  strictEqual(authorName, 'Grader 1');
});

QUnit.module('SpeedGrader#showGrade', {
  setup () {
    fakeENV.setup();
    sandbox.stub($, 'ajaxJSON');
    sandbox.spy($.fn, 'append');
    this.originalWindowJSONData = window.jsonData;
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
      studentsWithSubmissions: []
    };
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        score: 7,
        grade: 'complete',
        entered_grade: 'A',
        submission_comments: []
      }
    };
    ENV.SUBMISSION = {
      grading_role: 'teacher'
    };
    ENV.RUBRIC_ASSESSMENT = {
      assessment_type: 'grading',
      assessor_id: 1
    };
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    window.jsonData = this.originalWindowJSONData;
    fakeENV.teardown();
  }
});

test('uses submission#grade for pass_fail assignments', function () {
  sandbox.stub(SpeedGrader.EG, 'updateStatsInHeader');
  const $grade = sandbox.stub($.fn, 'val');
  SpeedGrader.EG.showGrade();
  ok($grade.calledWith('complete'));
});

test('uses submission#entered_grade for other types of assignments', function () {
  sandbox.stub(SpeedGrader.EG, 'updateStatsInHeader');
  const $grade = sandbox.stub($.fn, 'val');
  SpeedGrader.EG.currentStudent.submission.grade = 'B';
  SpeedGrader.EG.showGrade();
  ok($grade.calledWith('A'));
});

test('Does not error out if a user has no submission', function () {
  sandbox.stub(SpeedGrader.EG, 'updateStatsInHeader');

  SpeedGrader.EG.currentStudent.submission_state = 'unsubmitted';
  delete SpeedGrader.EG.currentStudent.submission;

  SpeedGrader.EG.showGrade();
  ok(true);
});

QUnit.module('SpeedGrader#handleGradeSubmit', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    sandbox.stub($, 'ajaxJSON');
    sandbox.spy($.fn, 'append');
    this.originalWindowJSONData = window.jsonData;
    setupFixtures(`
      <div id="iframe_holder"></div>
      <div id="multiple_submissions"></div>
      <a class="update_submission_grade_url" href="my_url.com" title="POST"></a>
    `);
    SpeedGrader.setup()
    window.jsonData = {
      gradingPeriods: {},
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
      anonymize_students: false,
      submissions: [],
      context: {
        students: [
          {
            id: 4,
            name: 'Guy B. Studying'
          }
        ],
        enrollments: [
          {
            user_id: 4,
            workflow_state: 'active',
            course_section_id: 1
          }
        ],
        active_course_sections: [1]
      },
      studentMap : {
        4 : SpeedGrader.EG.currentStudent
      }
    };
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        grading_period_id: 8,
        score: 7,
        grade: 70,
        submission_comments: [{
          group_comment_id: null,
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
          updated_at: '2016-07-12T23:47:34Z'
        }],
        submission_history: [{}]
      }
    };
    ENV.SUBMISSION = {
      grading_role: 'teacher'
    };
    ENV.RUBRIC_ASSESSMENT = {
      assessment_type: 'grading',
      assessor_id: 1
    };

    sinon.stub(SpeedGraderHelpers, 'reloadPage');

  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    teardownFixtures()
    window.jsonData = this.originalWindowJSONData;
    SpeedGrader.teardown()
    window.location.hash = ''
    fakeENV.teardown();
    SpeedGraderHelpers.reloadPage.restore();
  }
});

test('hasWarning and flashWarning are called', function () {
  sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
  SpeedGrader.EG.jsonReady()
  const flashWarningStub = sandbox.stub($, 'flashWarning');
  sandbox.stub(SpeedGraderHelpers, 'determineGradeToSubmit').returns('15');
  sandbox.stub(SpeedGrader.EG, 'setOrUpdateSubmission');
  sandbox.stub(SpeedGrader.EG, 'refreshSubmissionsToView');
  sandbox.stub(SpeedGrader.EG, 'updateSelectMenuStatus');
  sandbox.stub(SpeedGrader.EG, 'showGrade');
  SpeedGrader.EG.handleGradeSubmit(10, false);
  const [,,, callback] = $.ajaxJSON.getCall(2).args;
  const submissions = [{
    submission: { user_id: 1, score: 15, excused: false }
  }];
  callback(submissions);
  ok(flashWarningStub.calledOnce);
  SpeedGrader.EG.handleFragmentChanged.restore()
});

test('handleGradeSubmit should submit score if using existing score', () => {
  sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
  SpeedGrader.EG.jsonReady()
  SpeedGrader.EG.handleGradeSubmit(null, true);
  equal($.ajaxJSON.getCall(2).args[0], 'my_url.com');
  equal($.ajaxJSON.getCall(2).args[1], 'POST');
  const [,, formData] = $.ajaxJSON.getCall(2).args;
  equal(formData['submission[score]'], '7');
  equal(formData['submission[grade]'], undefined);
  equal(formData['submission[user_id]'], 4);
  SpeedGrader.EG.handleFragmentChanged.restore()
});

test('handleGradeSubmit should submit grade if not using existing score', function() {
  sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
  SpeedGrader.EG.jsonReady()
  sandbox.stub(SpeedGraderHelpers, 'determineGradeToSubmit').returns('56');
  SpeedGrader.EG.handleGradeSubmit(null, false);
  equal($.ajaxJSON.getCall(2).args[0], 'my_url.com');
  equal($.ajaxJSON.getCall(2).args[1], 'POST');
  const [,, formData] = $.ajaxJSON.getCall(2).args;
  equal(formData['submission[score]'], undefined);
  equal(formData['submission[grade]'], '56');
  equal(formData['submission[user_id]'], 4);
  SpeedGraderHelpers.determineGradeToSubmit.restore();
  SpeedGrader.EG.handleFragmentChanged.restore()
});

test('unexcuses the submission if the grade is blank and the assignment is complete/incomplete', function () {
  sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
  SpeedGrader.EG.jsonReady()
  sandbox.stub(SpeedGraderHelpers, 'determineGradeToSubmit').returns('');
  window.jsonData.grading_type = 'pass_fail';
  SpeedGrader.EG.currentStudent.submission.excused = true;
  SpeedGrader.EG.handleGradeSubmit(null, false);
  const [,, formData] = $.ajaxJSON.getCall(2).args;
  strictEqual(formData['submission[excuse]'], false);
  SpeedGraderHelpers.determineGradeToSubmit.restore();
  SpeedGrader.EG.handleFragmentChanged.restore()
});

QUnit.module('attachmentIframeContents', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    setupFixtures();
    sinon.stub($, 'ajaxJSON');
    SpeedGrader.setup()
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = { id: 4, submission: { user_id: 4 } };
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    SpeedGrader.teardown()
    fakeENV.teardown();
    $.ajaxJSON.restore()
    teardownFixtures()
    fakeENV.teardown();
  }
});

test('returns an image tag if the attachment is of type "image"', () => {
  const attachment = { id: 1, mime_class: 'image' };
  const contents = SpeedGrader.EG.attachmentIframeContents(attachment);
  strictEqual(/^<img/.test(contents.string), true);
});

test('returns an iframe tag if the attachment is not of type "image"', () => {
  const attachment = { id: 1, mime_class: 'text/plain' };
  const contents = SpeedGrader.EG.attachmentIframeContents(attachment);
  strictEqual(/^<iframe/.test(contents.string), true);
});

QUnit.module('emptyIframeHolder', {
  setup() {
    fakeENV.setup();
    sandbox.stub($, 'ajaxJSON');
    $div = $("<div id='iframe_holder'>not empty</div>")
    setupFixtures($div);
  },

  teardown() {
    fakeENV.teardown();
    teardownFixtures()
  }
});

test('clears the contents of the iframe_holder', () => {
  SpeedGrader.EG.emptyIframeHolder($div);
  ok($div.is(':empty'));
});

QUnit.module('renderLtiLaunch', {
  setup() {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    setupFixtures('<div id="iframe_holder">not empty</div>');
    $div = $(fixtures).find('#iframe_holder')
    sinon.stub($, 'getJSON')
    sinon.stub($, 'ajaxJSON')
    sinon.stub(SpeedGrader.EG, 'domReady')
    SpeedGrader.setup()
  },

  teardown() {
    SpeedGrader.EG.domReady.restore()
    $.ajaxJSON.restore()
    $.getJSON.restore()
    fakeENV.teardown();
    teardownFixtures()
  }
});

test('contains iframe with the escaped student submission url', () => {
  const retrieveUrl = '/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
  const url = 'www.example.com/lti/launch/user/4'
  const buildIframeStub = sinon.stub(SpeedGraderHelpers, 'buildIframe')
  SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, url)
  const [srcUrl] = buildIframeStub.firstCall.args
  ok(unescape(srcUrl).indexOf(retrieveUrl) > -1)
  ok(unescape(srcUrl).indexOf(encodeURIComponent(url)) > -1)
  buildIframeStub.restore()
})

test('can be fullscreened', () => {
  const retrieveUrl = 'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
  const url = 'www.example.com/lti/launch/user/4'
  const buildIframeStub = sinon.stub(SpeedGraderHelpers, 'buildIframe')
  SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, url)
  const [,{allowfullscreen}] = buildIframeStub.firstCall.args
  strictEqual(allowfullscreen, true)
  buildIframeStub.restore()
})

QUnit.module('speed_grader#getGradeToShow');

test('returns an empty string for "entered" if submission is null', () => {
  const grade = SpeedGrader.EG.getGradeToShow(null, 'some_role');
  equal(grade.entered, '');
});

test('returns an empty string for "entered" if the submission is undefined', () => {
  const grade = SpeedGrader.EG.getGradeToShow(undefined, 'some_role');
  equal(grade.entered, '');
});

test('returns an empty string for "entered" if a submission has no excused or grade', () => {
  const grade = SpeedGrader.EG.getGradeToShow({}, 'some_role');
  equal(grade.entered, '');
});

test('returns excused for "entered" if excused is true', () => {
  const grade = SpeedGrader.EG.getGradeToShow({ excused: true }, 'some_role');
  equal(grade.entered, 'EX');
});

test('returns excused for "entered" if excused is true and user is moderator', () => {
  const grade = SpeedGrader.EG.getGradeToShow({ excused: true }, 'moderator');
  equal(grade.entered, 'EX');
});

test('returns excused for "entered" if excused is true and user is provisional grader', () => {
  const grade = SpeedGrader.EG.getGradeToShow({ excused: true }, 'provisional_grader');
  equal(grade.entered, 'EX');
});

test('returns negated points_deducted for "pointsDeducted"', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    points_deducted: 123
  }, 'some_role');
  equal(grade.pointsDeducted, '-123');
});

test('returns values based on grades if submission has no excused and grade is not a float', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    grade: 'some_grade',
    entered_grade: 'entered_grade'
  }, 'some_role');
  equal(grade.entered, 'entered_grade');
  equal(grade.adjusted, 'some_grade');
});

test('returns values based on scores if user is a moderator', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    grade: 15,
    score: 25,
    entered_score: 30
  }, 'moderator');
  equal(grade.entered, '30');
  equal(grade.adjusted, '25');
});

test('returns values based on scores if user is a provisional grader', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    grade: 15,
    score: 25,
    entered_score: 30,
    points_deducted: 5
  }, 'provisional_grader');
  equal(grade.entered, '30');
  equal(grade.adjusted, '25');
  equal(grade.pointsDeducted, '-5');
});

test('returns values based on grades if user is neither a moderator or provisional grader', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    grade: 15,
    score: 25,
    entered_grade: 30,
    points_deducted: 15
  }, 'some_role');
  equal(grade.entered, '30');
  equal(grade.adjusted, '15');
  equal(grade.pointsDeducted, '-15');
});

test('returns values based on grades if user is moderator but score is null', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    grade: 15,
    entered_grade: 20,
    points_deducted: 5
  }, 'moderator');
  equal(grade.entered, '20');
  equal(grade.adjusted, '15');
  equal(grade.pointsDeducted, '-5');
});

test('returns values based on grades if user is provisional grader but score is null', () => {
  const grade = SpeedGrader.EG.getGradeToShow({
    grade: 15,
    entered_grade: 20,
    points_deducted: 5
  }, 'provisional_grader');
  equal(grade.entered, '20');
  equal(grade.adjusted, '15');
  equal(grade.pointsDeducted, '-5');
});

QUnit.module('speed_grader#getStudentNameAndGrade', {
  setup () {
    this.originalStudent = SpeedGrader.EG.currentStudent;
    this.originalWindowJSONData = window.jsonData;

    window.jsonData = {};
    window.jsonData.studentsWithSubmissions = [
      {
        index: 0,
        id: 4,
        name: 'Guy B. Studying',
        submission_state: 'not_graded'
      },
      {
        index: 1,
        id: 12,
        name: 'Sil E. Bus',
        submission_state: 'graded',
      }
    ];

    SpeedGrader.EG.currentStudent = window.jsonData.studentsWithSubmissions[0];
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    window.jsonData = this.originalWindowJSONData;
  }
});

test('returns name and status', () => {
  const result = SpeedGrader.EG.getStudentNameAndGrade();
  equal(result, 'Guy B. Studying - not graded');
});

test('hides name if shouldHideStudentNames is true', function() {
  sandbox.stub(userSettings, 'get').returns(true);
  const result = SpeedGrader.EG.getStudentNameAndGrade();
  equal(result, 'Student 1 - not graded');
});

test("returns name and status for non-current student", () => {
  const student = window.jsonData.studentsWithSubmissions[1];
  const result = SpeedGrader.EG.getStudentNameAndGrade(student);
  equal(result, 'Sil E. Bus - graded');
});

test("hides non-current student name if shouldHideStudentNames is true", function () {
  sandbox.stub(userSettings, 'get').returns(true);
  const student = window.jsonData.studentsWithSubmissions[1];
  const result = SpeedGrader.EG.getStudentNameAndGrade(student);
  equal(result, 'Student 2 - graded');
});

QUnit.module('handleSubmissionSelectionChange', (hooks) => {
  let closedGradingPeriodNotice
  let getFromCache
  let originalWindowJSONData
  let originalStudent
  let courses
  let assignments
  let submissions
  let params
  let finishSetup

  hooks.beforeEach(() => {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      current_user_roles: ['teacher'],
      grading_role: 'grader',
      help_url: 'helpUrl',
      show_help_menu_item: false
    })
    sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
    originalWindowJSONData = window.jsonData
    originalStudent = SpeedGrader.EG.currentStudent
    courses = `/courses/${ENV.course_id}`;
    assignments = `/assignments/${ENV.assignment_id}`;
    submissions = `/submissions/{{submissionId}}`;
    params = `?download={{attachmentId}}`;
    setupFixtures(`
      <div id="iframe_holder"></div>
      <div id="react_pill_container"></div>
      <div id='grade_container'>
        <input type='text' id='grading-box-extended' />
      </div>
      <div id="submission_file_hidden">
        <a
          class="display_name"
          href="${courses}${assignments}${submissions}${params}"
        </a>
      </div>
      <div id="submission_files_list">
        <a class="display_name"></a>
      </div>
      <div id='submission_attachment_viewed_at_container'>
      </div>
    `);
    sinon.stub($, 'ajaxJSON');

    // Defer the rest of the setup until the tests themselves so we can edit
    // environment variables if needed
    finishSetup = () => {
      SpeedGrader.setup()
      SpeedGrader.EG.currentStudent = {
        id: 4,
        name: "Guy B. Studying",
        enrollments: [{
          workflow_state: 'active'
        }],
        submission_state: 'not_graded',
        submission: {
          currentSelectedIndex: 1,
          score: 7,
          grade: 70,
          grading_period_id: 8,
          submission_type: 'basic_lti_launch',
          workflow_state: 'submitted',
          submission_history: [
            {
              submission: {
                user_id: 4,
                submission_type: 'basic_lti_launch',
                external_tool_url: 'foo'
              }
            },
            {
              submission: {
                user_id: 4,
                submission_type: 'basic_lti_launch',
                external_tool_url: 'bar',
                versioned_attachments: [
                  {
                    attachment: { viewed_at: new Date('Jan 1, 2011').toISOString() }
                  }
                ]
              }
            }
          ]
        }
      }

      window.jsonData = {
        id: 27,
        context: {
          active_course_sections: [],
          enrollments: [
            {
              user_id: "4",
              course_section_id: 1
            }
          ],
          students: [
            {
              index: 0,
              id: 4,
              name: 'Guy B. Studying',
              submission_state: 'not_graded'
            }
          ]
        },
        gradingPeriods: {
          7: { id: 7, is_closed: false },
          8: { id: 8, is_closed: true }
        },
        GROUP_GRADING_MODE: false,
        points_possible: 10,
        studentMap : {
          4 : SpeedGrader.EG.currentStudent
        },
        studentsWithSubmissions: [],
        submissions: []
      }

      SpeedGrader.EG.jsonReady()

      closedGradingPeriodNotice = { showIf: sinon.stub() }
      getFromCache = sinon.stub(JQuerySelectorCache.prototype, 'get')
      getFromCache.withArgs('#closed_gp_notice').returns(closedGradingPeriodNotice)
    }
  })

  hooks.afterEach(() => {
    getFromCache.restore()
    window.jsonData = originalWindowJSONData
    SpeedGrader.EG.currentStudent = originalStudent
    $.ajaxJSON.restore()
    SpeedGrader.teardown()
    window.location.hash = ''
    SpeedGrader.EG.handleFragmentChanged.restore()
    fakeENV.teardown()
    teardownFixtures()
  })

  test('should use submission history lti launch url', () => {
    finishSetup()
    const renderLtiLaunch = sinon.stub(SpeedGrader.EG, 'renderLtiLaunch')
    SpeedGrader.EG.handleSubmissionSelectionChange()
    ok(renderLtiLaunch.calledWith(sinon.match.any, sinon.match.any, "bar"))
    renderLtiLaunch.restore()
  })

  test('shows a "closed grading period" notice if the submission is in a closed period', () => {
    finishSetup()
    SpeedGrader.EG.handleSubmissionSelectionChange()
    ok(closedGradingPeriodNotice.showIf.calledWithExactly(true))
  })

  test('does not show a "closed grading period" notice if the submission is not in a closed period', () => {
    finishSetup()
    SpeedGrader.EG.currentStudent.submission.grading_period_id = null
    SpeedGrader.EG.handleSubmissionSelectionChange()
    notOk(closedGradingPeriodNotice.showIf.calledWithExactly(true))
  })

  test('includes last-viewed date for attachments if not anonymizing students', () => {
    finishSetup()
    SpeedGrader.EG.handleSubmissionSelectionChange()

    const viewedAtHTML = document.getElementById('submission_attachment_viewed_at_container').innerHTML

    ok(viewedAtHTML.includes('Jan 1, 2011'))
  })

  test('includes last-viewed date for attachments if viewing as an admin', () => {
    ENV.current_user_roles = ['admin']
    finishSetup()
    window.jsonData.anonymize_students = true
    SpeedGrader.EG.handleSubmissionSelectionChange()

    const viewedAtHTML = document.getElementById('submission_attachment_viewed_at_container').innerHTML

    ok(viewedAtHTML.includes('Jan 1, 2011'))
  })

  test('omits last-viewed date and relevant text if anonymizing students and not viewing as an admin', () => {
    finishSetup()
    window.jsonData.anonymize_students = true
    SpeedGrader.EG.handleSubmissionSelectionChange()

    const viewedAtHTML = document.getElementById('submission_attachment_viewed_at_container').innerHTML

    notOk(viewedAtHTML.includes('Jan 1, 2011'))
  })

  QUnit.skip('disables the complete/incomplete select when grading period is closed', () => {
    finishSetup()
    // the select box is not powered by isClosedForSubmission, it's powered by isConcluded
    SpeedGrader.EG.currentStudent.submission.grading_period_id = 8
    SpeedGrader.EG.handleSubmissionSelectionChange()
    const select = document.getElementById('grading-box-extended')
    ok(select.hasAttribute('disabled'))
  })

  QUnit.skip('does not disable the complete/incomplete select when grading period is open', () => {
    finishSetup()
    // the select box is not powered by isClosedForSubmission, it's powered by isConcluded
    SpeedGrader.EG.currentStudent.submission.grading_period_id = 7
    SpeedGrader.EG.handleSubmissionSelectionChange()
    const select = document.getElementById('grading-box-extended')
    notOk(select.hasAttribute('disabled'))
  })

  test('submission files list template is populated with anonymous submission data', () => {
    finishSetup()
    SpeedGrader.EG.currentStudent.submission.currentSelectedIndex = 0
    SpeedGrader.EG.currentStudent.submission.submission_history[0].submission.versioned_attachments = [{
      attachment: {
        id: 1,
        display_name: 'submission.txt'
      }
    }]
    SpeedGrader.EG.handleSubmissionSelectionChange();
    const {pathname} = new URL(document.querySelector('#submission_files_list a').href);
    const expectedPathname = `${courses}${assignments}/submissions/${SpeedGrader.EG.currentStudent.id}`;
    equal(pathname, expectedPathname);
  })
})

QUnit.module('SpeedGrader#isGradingTypePercent', {
  setup () {
    fakeENV.setup();
  },
  teardown () {
    fakeENV.teardown();
  }
});

test('should return true when grading type is percent', () => {
  ENV.grading_type = 'percent';
  const result = SpeedGrader.EG.isGradingTypePercent();
  ok(result);
});

test('should return false when grading type is not percent', () => {
  ENV.grading_type = 'foo';
  const result = SpeedGrader.EG.isGradingTypePercent();
  notOk(result);
});

QUnit.module('SpeedGrader#shouldParseGrade', {
  setup () {
    fakeENV.setup();
  },
  teardown () {
    fakeENV.teardown();
  }
});

test('should return true when grading type is percent', () => {
  ENV.grading_type = 'percent';
  const result = SpeedGrader.EG.shouldParseGrade();
  ok(result);
});

test('should return true when grading type is points', () => {
  ENV.grading_type = 'points';
  const result = SpeedGrader.EG.shouldParseGrade();
  ok(result);
});

test('should return false when grading type is neither percent nor points', () => {
  ENV.grading_type = 'foo';
  const result = SpeedGrader.EG.shouldParseGrade();
  notOk(result);
});

QUnit.module('SpeedGrader#formatGradeForSubmission', {
  setup () {
    fakeENV.setup();
    sandbox.stub(numberHelper, 'parse').returns(42);
  },

  teardown () {
    fakeENV.teardown();
  }
});

test('returns empty string if input is empty string', () => {
  strictEqual(SpeedGrader.EG.formatGradeForSubmission(''), '');
});

test('should call numberHelper#parse if grading type is points', () => {
  ENV.grading_type = 'points';
  const result = SpeedGrader.EG.formatGradeForSubmission('1,000');
  equal(numberHelper.parse.callCount, 1);
  strictEqual(result, '42');
});

test('should call numberHelper#parse if grading type is a percentage', () => {
  ENV.grading_type = 'percent';
  const result = SpeedGrader.EG.formatGradeForSubmission('75%');
  equal(numberHelper.parse.callCount, 1);
  strictEqual(result, '42%')
});

test('should not call numberHelper#parse if grading type is neither points nor percentage', () => {
  ENV.grading_type = 'foo';
  const result = SpeedGrader.EG.formatGradeForSubmission('A');
  ok(numberHelper.parse.notCalled);
  equal(result, 'A');
});

QUnit.module('SpeedGrader', suiteHooks => {
  let $container

  suiteHooks.beforeEach(() => {
    setupFixtures(`
      <div id="combo_box_container"></div>
      <div id="iframe_holder"></div>
    `);

    sandbox.stub($, 'ajaxJSON')
    fakeENV.setup({
      RUBRIC_ASSESSMENT: {},
      assignment_id: '2301',
      course_id: '1201',
      help_url: '',
      show_help_menu_item: false
    })

    sandbox.stub(userSettings, 'get')
    sandbox.stub(SpeedGrader.EG, 'handleFragmentChanged')
  })

  suiteHooks.afterEach(() => {
    window.location.hash = ''
    fakeENV.teardown()
    teardownFixtures();
  })

  QUnit.module('Student Order', hooks => {
    hooks.beforeEach(() => {
      SpeedGrader.setup()

      window.jsonData = {
        GROUP_GRADING_MODE: false,
        anonymize_students: false,
        gradingPeriods: {},
        id: 27,
        points_possible: 10,
        submissions: []
      }

      userSettings.get.withArgs('eg_sort_by').returns('alphabetically')
    })

    hooks.afterEach(() => {
      SpeedGrader.teardown()
    })

    QUnit.module('when students are not anonymous', contextHooks => {
      contextHooks.beforeEach(() => {
        window.jsonData.context = {
          active_course_sections: ['2001'],
          enrollments: [
            {course_section_id: '2001', user_id: '1101', workflow_state: 'active'},
            {course_section_id: '2001', user_id: '1102', workflow_state: 'active'},
            {course_section_id: '2001', user_id: '1103', workflow_state: 'active'},
            {course_section_id: '2001', user_id: '1104', workflow_state: 'active'}
          ],
          students: [
            {id: '1101', sortable_name: 'Jones, Adam'},
            {id: '1102', sortable_name: 'Ford, Betty'},
            {id: '1103', sortable_name: 'Xi, Charlie'},
            {id: '1104', sortable_name: 'Smith, Dana'}
          ]
        }

        window.jsonData.submissions = [
          {
            grade: null,
            grade_matches_current_submission: false,
            id: '2501',
            score: null,
            submitted_at: '2015-05-05T12:00:00Z',
            user_id: '1101',
            workflow_state: 'submitted'
          },

          {
            grade: null,
            grade_matches_current_submission: false,
            id: '2502',
            score: null,
            submitted_at: null,
            user_id: '1102',
            workflow_state: 'unsubmitted'
          },

          {
            grade: 'F',
            grade_matches_current_submission: false,
            id: '2503',
            score: 0,
            submitted_at: '2015-05-06T12:00:00Z',
            user_id: '1103',
            workflow_state: 'resubmitted'
          },

          {
            grade: 'A',
            grade_matches_current_submission: true,
            id: '2504',
            score: 10,
            submitted_at: '2015-05-04T12:00:00Z',
            user_id: '1104',
            workflow_state: 'graded'
          }
        ]
      })

      test('preserves student order (from server) when sorting alphabetically', () => {
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.id)
        deepEqual(ids, ['1101', '1102', '1103', '1104'])
      })

      test('preserves student order (from server) when no sorting preference is set', () => {
        userSettings.get.withArgs('eg_sort_by').returns(undefined)
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.id)
        deepEqual(ids, ['1101', '1102', '1103', '1104'])
      })

      test('sorts students by submission "submitted_at" when sorting by submission date', () => {
        userSettings.get.withArgs('eg_sort_by').returns('submitted_at')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.id)
        deepEqual(ids, ['1104', '1101', '1103', '1102'])
      })

      test('sorts students by sortable_name when submission "submitted_at" dates match', () => {
        window.jsonData.submissions[0].submitted_at = window.jsonData.submissions[1].submitted_at
        userSettings.get.withArgs('eg_sort_by').returns('submitted_at')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.id)
        deepEqual(ids, ['1104', '1103', '1102', '1101'])
      })

      test('sorts students by submission status', () => {
        userSettings.get.withArgs('eg_sort_by').returns('submission_status')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.id)
        deepEqual(ids, ['1101', '1103', '1102', '1104'])
      })

      test('sorts students by sortable_name when submission statuses match', () => {
        Object.assign(window.jsonData.submissions[1], {grade: null, score: null, workflow_state: 'submitted'})
        userSettings.get.withArgs('eg_sort_by').returns('submission_status')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.id)
        deepEqual(ids, ['1102', '1101', '1103', '1104'])
      })
    })

    QUnit.module('when students are anonymous', contextHooks => {
      const alpha = {anonymous_id: '00000'}
      const beta  = {anonymous_id: '99999'}
      const gamma = {anonymous_id: 'aaaaa'}
      const delta = {anonymous_id: 'zzzzz'}

      contextHooks.beforeEach(() => {
        window.jsonData.anonymize_students = true
        window.jsonData.context = {
          active_course_sections: ['2001'],
          enrollments: [
            {course_section_id: '2001', workflow_state: 'active', ...alpha},
            {course_section_id: '2001', workflow_state: 'active', ...beta},
            {course_section_id: '2001', workflow_state: 'active', ...gamma},
            {course_section_id: '2001', workflow_state: 'active', ...delta}
          ],
          students: [beta, alpha, gamma, delta]
        }

        window.jsonData.submissions = [{
          grade: null,
          grade_matches_current_submission: false,
          id: '2501',
          score: null,
          submitted_at: '2015-05-05T12:00:00Z',
          workflow_state: 'submitted',
          ...beta,
        }, {
          grade: null,
          grade_matches_current_submission: false,
          id: '2502',
          score: null,
          submitted_at: null,
          workflow_state: 'unsubmitted',
          ...alpha
        }, {
          grade: 'F',
          grade_matches_current_submission: false,
          id: '2503',
          score: 0,
          submitted_at: '2015-05-06T12:00:00Z',
          workflow_state: 'resubmitted',
          ...delta
        }, {
          grade: 'A',
          grade_matches_current_submission: true,
          id: '2504',
          score: 10,
          submitted_at: '2015-05-04T12:00:00Z',
          workflow_state: 'graded',
          ...gamma
        }]
      })

      test('sorts students by anonymous_id when sorting alphabetically', () => {
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
        const expectedIds = [alpha, beta, gamma, delta].map(student => student.anonymous_id)
        deepEqual(ids, expectedIds)
      })

      test('sorts students by anonymous_id when no sorting preference is set', () => {
        userSettings.get.withArgs('eg_sort_by').returns(undefined)
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
        const expectedIds = [alpha, beta, gamma, delta].map(student => student.anonymous_id)
        deepEqual(ids, expectedIds)
      })

      test('sorts students by submission "submitted_at" when sorting by submission date', () => {
        userSettings.get.withArgs('eg_sort_by').returns('submitted_at')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
        const expectedIds = [gamma, beta, delta, alpha].map(student => student.anonymous_id)
        deepEqual(ids, expectedIds)
      })

      test('sorts students by anonymous_id when submission "submitted_at" dates match', () => {
        window.jsonData.submissions[0].submitted_at = window.jsonData.submissions[1].submitted_at
        userSettings.get.withArgs('eg_sort_by').returns('submitted_at')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
        const expectedIds = [gamma, delta, alpha, beta].map(student => student.anonymous_id)
        deepEqual(ids, expectedIds)
      })

      test('sorts students by submission status', () => {
        userSettings.get.withArgs('eg_sort_by').returns('submission_status')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
        const expectedIds = [beta, delta, alpha, gamma].map(student => student.anonymous_id)
        deepEqual(ids, expectedIds)
      })

      test('sorts students by anonymous_id when submission statuses match', () => {
        Object.assign(window.jsonData.submissions[1], {grade: null, score: null, workflow_state: 'submitted'})
        userSettings.get.withArgs('eg_sort_by').returns('submission_status')
        SpeedGrader.EG.jsonReady()
        const ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
        const expectedIds = [alpha, beta, delta, gamma].map(student => student.anonymous_id)
        deepEqual(ids, expectedIds)
      })
    })
  })

  QUnit.module('"Assessment Audit" button', hooks => {
    hooks.beforeEach(() => {
      ENV.can_view_audit_trail = true
    })

    hooks.afterEach(() => {
      SpeedGrader.teardown()
    })

    function setUpSpeedGrader() {
      SpeedGrader.EG.currentStudent = {
        id: '1101',
        name: 'Adam Jones',
        submission_state: 'graded',
        submission: {
          grade: 'A',
          id: '2501',
          score: 9.1,
          submission_comments: []
        }
      }

      SpeedGrader.setup()

      window.jsonData = {
        GROUP_GRADING_MODE: false,
        anonymize_students: false,
        grades_published_at: '2015-05-04T12:00:00.000Z',
        gradingPeriods: {},
        id: 27,
        points_possible: 10,
        submissions: []
      }
    }

    function getAssessmentAuditButton() {
      return [...fixtures.querySelectorAll('button')].find($button => (
        $button.textContent === 'Assessment audit'
      ))
    }

    test('is present when the current user can view the audit trail', () => {
      setUpSpeedGrader()
      ok(getAssessmentAuditButton())
    })

    test('is not present when the current user cannot view the audit trail', () => {
      ENV.can_view_audit_trail = false
      setUpSpeedGrader()
      notOk(getAssessmentAuditButton())
    })

    test('opens the "Assessment Audit" tray when clicked', () => {
      setUpSpeedGrader()
      sandbox.stub(SpeedGrader.EG.assessmentAuditTray, 'show')
      getAssessmentAuditButton().click()
      strictEqual(SpeedGrader.EG.assessmentAuditTray.show.callCount, 1)
    })

    QUnit.module('when opening the "Assessment Audit" tray', contextHooks => {
      let context

      contextHooks.beforeEach(() => {
        setUpSpeedGrader()
        sandbox.stub(SpeedGrader.EG.assessmentAuditTray, 'show')
        getAssessmentAuditButton().click()
        context = SpeedGrader.EG.assessmentAuditTray.show.lastCall.args[0]
      })

      test('includes .assignment.gradesPublishedAt in the context', () => {
        equal(context.assignment.gradesPublishedAt, '2015-05-04T12:00:00.000Z')
      })

      test('includes .assignment.id in the context', () => {
        strictEqual(context.assignment.id, '2301')
      })

      test('includes .assignment.pointsPossible in the context', () => {
        strictEqual(context.assignment.pointsPossible, 10)
      })

      test('includes .courseId in the context', () => {
        strictEqual(context.courseId, '1201')
      })

      test('includes .submission.id in the context', () => {
        strictEqual(context.submission.id, '2501')
      })

      test('includes .submission.score in the context', () => {
        strictEqual(context.submission.score, 9.1)
      })
    })
  })
})

QUnit.module('SpeedGrader - gateway timeout', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    this.server = sinon.fakeServer.create({ respondImmediately: true });
    this.server.respondWith(
      'GET',
      `${window.location.pathname}.json${window.location.search}`,
      [504, { 'Content-Type': 'application/json' }, '']
    );
    setupFixtures('<div id="speed_grader_timeout_alert"></div>');
  },
  teardown () {
    teardownFixtures()
    this.server.restore();
    fakeENV.teardown();
  }
});

test('shows an error when the gateway times out', function () {
  sandbox.stub(SpeedGrader.EG, 'domReady');
  ENV.assignment_title = 'Assignment Title';
  SpeedGrader.setup();
  const message = 'Something went wrong. Please try refreshing the page. If the problem persists, there may be too many records on "Assignment Title" to load SpeedGrader.';
  strictEqual($('#speed_grader_timeout_alert').text(), message);
});

QUnit.module('SpeedGrader - clicking save rubric button', function(hooks) {
  let disableWhileLoadingStub;
  const assignment = {}
  const student = {
    id: '1',
    submission_history: [],
  }
  const enrollment = { user_id: student.id, course_section_id: '1'}
  const submissionComment = {
    created_at: (new Date).toISOString(),
    publishable: false,
    comment: 'a comment',
    author_id: 1,
    author_name: 'an author'
  }
  const submission = {
    id: '3',
    user_id: '1',
    grade_matches_current_submission: true,
    workflow_state: 'active',
    submitted_at: (new Date).toISOString(),
    grade: 'A',
    assignment_id: '456',
    submission_comments: [submissionComment],
    submission_history: []
  }
  const windowJsonData = {
    ...assignment,
    context_id: '123',
    context: {
      students: [student],
      enrollments: [enrollment],
      active_course_sections: [],
      rep_for_student: {}
    },
    submissions: [submission],
    gradingPeriods: []
  }

  hooks.beforeEach(function () {
    sinon.stub($, 'ajaxJSON');
    sinon.stub($.fn, 'ready')
    disableWhileLoadingStub = sinon.stub($.fn, 'disableWhileLoading');
    fakeENV.setup({
      assignment_id: '27',
      course_id: '3',
      help_url: '',
      show_help_menu_item: false,
      RUBRIC_ASSESSMENT: {},
      force_anonymous_grading: false
    });
    setupFixtures(`
      <button class="save_rubric_button"></button>
      <div id="speed_grader_comment_textarea_mount_point"></div>
    `);
    SpeedGrader.setup()
    window.jsonData = windowJsonData
    SpeedGrader.EG.jsonReady()
    setupCurrentStudent()
    window.jsonData.anonymize_students = false
  });

  hooks.afterEach(function() {
    teardownFixtures()
    fakeENV.teardown();
    disableWhileLoadingStub.restore();
    SpeedGrader.teardown()
    window.location.hash = ''
    $.ajaxJSON.restore();
    $.fn.ready.restore()
  });

  test('disables the button', function () {
    SpeedGrader.EG.domReady();
    $('.save_rubric_button').trigger('click');
    strictEqual(disableWhileLoadingStub.callCount, 1);
  });

  test('sends the user ID in rubric_assessment[user_id] if the assignment is not anonymous', () => {
    SpeedGrader.EG.domReady();
    sinon.stub(window.rubricAssessment, 'assessmentData').returns({ 'rubric_assessment[user_id]': '1234' });
    $('.save_rubric_button').trigger('click');

    const [, , data] = $.ajaxJSON.lastCall.args;
    strictEqual(data['rubric_assessment[user_id]'], '1234');
    window.rubricAssessment.assessmentData.restore();
  })
});

QUnit.module('SpeedGrader - clicking save rubric button for an anonymous assignment', (hooks) => {
  const originalWindowJsonData = window.jsonData
  const originalSpeedGraderEGCurrentStudent = SpeedGrader.EG.currentStudent

  hooks.beforeEach(() => {
    sinon.stub($, 'ajaxJSON');
    disableWhileLoadingStub = sinon.stub($.fn, 'disableWhileLoading');
    fakeENV.setup({
      assignment_id: '27',
      course_id: '3',
      help_url: '',
      show_help_menu_item: false,
      SUBMISSION: {grading_role: 'teacher'},
      RUBRIC_ASSESSMENT: {
        assessment_type: 'grading',
        assessor_id: 1
      }
    });

    sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
    rubricAssessmentDataStub = sinon.stub(window.rubricAssessment, 'assessmentData').returns({ 'rubric_assessment[user_id]': 'abcde' });

    setupFixtures(`
      <button class="save_rubric_button"></button>
      <div id="speed_grader_comment_textarea_mount_point"></div>
      <select id="rubric_assessments_select"></select>
      <div id="rubric_assessments_list"></div>
    `);
    SpeedGrader.setup()
    SpeedGrader.EG.currentStudent = {
      anonymous_id: 'a1b2c',
      rubric_assessments: [],
      submission_state: 'not_graded',
      submission: {
        grading_period_id: 8,
        score: 7,
        grade: 70,
        submission_comments: [],
        submission_history: [{}]
      }
    };
    window.jsonData = {
      gradingPeriods: {},
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
      anonymize_students: true,
      submissions: [],
      context: {
        students: [
          {
            anonymous_id: 'a1b2c',
            name: 'P. Sextus Rubricius'
          }
        ],
        enrollments: [
          {
            anonymous_id: 'a1b2c',
            workflow_state: 'active',
            course_section_id: 1
          }
        ],
        active_course_sections: [1]
      },
      studentMap: {
        a1b2c: SpeedGrader.EG.currentStudent
      }
    }

    SpeedGrader.EG.jsonReady();
  })

  hooks.afterEach(() => {
    window.jsonData = originalWindowJsonData
    SpeedGrader.EG.currentStudent = originalSpeedGraderEGCurrentStudent
    teardownFixtures()
    rubricAssessmentDataStub.restore();
    SpeedGrader.EG.handleFragmentChanged.restore();
    fakeENV.teardown();
    disableWhileLoadingStub.restore();
    $.ajaxJSON.restore();
    SpeedGrader.teardown()
    window.location.hash = ''
  })

  test('sends the anonymous submission ID in rubric_assessment[anonymous_id] if the assignment is anonymous', () => {
    $('.save_rubric_button').trigger('click');

    const [, , data] = $.ajaxJSON.lastCall.args;
    strictEqual(data['rubric_assessment[anonymous_id]'], 'abcde');
  })

  test('omits rubric_assessment[user_id] if the assignment is anonymous', () => {
    $('.save_rubric_button').trigger('click');

    const [, , data] = $.ajaxJSON.lastCall.args;
    notOk('rubric_assessment[user_id]' in data)
  })

  test('calls showRubric with no arguments upon receiving a successful response', () => {
    const fakeResponse = {
      artifact: {user_id: 4},
      related_group_submissions_and_assessments: []
    }
    $.ajaxJSON.yields(fakeResponse)
    sinon.spy(SpeedGrader.EG, 'showRubric')

    $('.save_rubric_button').trigger('click')

    strictEqual(SpeedGrader.EG.showRubric.firstCall.args.length, 0)

    SpeedGrader.EG.showRubric.restore()
    $.ajaxJSON.reset()
  })
})

QUnit.module('SpeedGrader - no gateway timeout', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    this.server = sinon.fakeServer.create({ respondImmediately: true });
    this.server.respondWith(
      'GET',
      `${window.location.pathname}.json${window.location.search}`,
      [200, { 'Content-Type': 'application/json' }, '{ hello: "world"}']
    );
    setupFixtures('<div id="speed_grader_timeout_alert"></div>');
  },

  teardown () {
    teardownFixtures()
    this.server.restore();
    fakeENV.teardown();
  }
});

test('does not show an error when the gateway times out', function () {
  const domReadyStub = sinon.stub(SpeedGrader.EG, 'domReady');
  ENV.assignment_title = 'Assignment Title';
  SpeedGrader.setup();
  strictEqual($('#speed_grader_timeout_alert').text(), '');
  domReadyStub.restore()
});

QUnit.module('SpeedGrader', function(suiteHooks) {
  suiteHooks.beforeEach(() => {
    fakeENV.setup({
      assignment_id: '2',
      course_id: '7',
      help_url: 'example.com/foo',
      settings_url: 'example.com/settings',
      show_help_menu_item: false
    })
    sinon.stub($, 'getJSON')
    sinon.stub($, 'ajaxJSON')
    setupFixtures();
  })

  suiteHooks.afterEach(() => {
    $.getJSON.restore()
    $.ajaxJSON.restore()
    teardownFixtures()
    fakeENV.teardown()
  })

  QUnit.module('#refreshFullRubric', function(hooks) {
    let speedGraderCurrentStudent;
    let jsonData;
    const rubricHTML = `
      <select id="rubric_assessments_select">
        <option value="3">an assessor</option>
      </select>
      <div id="rubric_full"></div>
    `;

    hooks.beforeEach(function () {
      setupFixtures(rubricHTML);
      fakeENV.setup({ ...window.ENV, RUBRIC_ASSESSMENT: { assessment_type: 'peer_review' }});
      ({jsonData} = window);
      speedGraderCurrentStudent = SpeedGrader.EG.currentStudent;
      window.jsonData = { rubric_association: {} };
      SpeedGrader.EG.currentStudent = {
        rubric_assessments: [{ id: '3', assessor_id: '5', data: [{ points: 2, criterion_id: '9'}] }]
      }
      const getFromCache = sinon.stub(JQuerySelectorCache.prototype, 'get');
      getFromCache.withArgs('#rubric_full').returns($('#rubric_full'));
      getFromCache.withArgs('#rubric_assessments_select').returns($('#rubric_assessments_select'));
      sinon.stub(window.rubricAssessment, 'populateRubric');
    });

    hooks.afterEach(function() {
      window.rubricAssessment.populateRubric.restore();
      JQuerySelectorCache.prototype.get.restore();
      SpeedGrader.EG.currentStudent = speedGraderCurrentStudent;
      window.jsonData = jsonData;
      teardownFixtures()
    });

    QUnit.module('when the assessment is a grading assessment and the user is a grader', function(contextHooks) {
      contextHooks.beforeEach(function() {
        SpeedGrader.EG.currentStudent.rubric_assessments[0].assessment_type = 'grading'
        fakeENV.setup({ ...window.ENV, current_user_id: '7', RUBRIC_ASSESSMENT: { assessment_type: 'grading' }})
      })

      contextHooks.afterEach(function() {
        delete SpeedGrader.EG.currentStudent.rubric_assessments[0].assessment_type
      })

      test('populates the rubric with data even if the user is not the selected assessor', function() {
        SpeedGrader.EG.refreshFullRubric();
        const {data} = window.rubricAssessment.populateRubric.getCall(0).args[1];
        propEqual(data, [{ points: 2, criterion_id: '9' }]);
      })

      test('populates the rubric with data if the user is the selected assessor', function() {
        SpeedGrader.EG.refreshFullRubric()
        const {data} = window.rubricAssessment.populateRubric.getCall(0).args[1]
        propEqual(data, [{ points: 2, criterion_id: '9' }])
      })
    })

    QUnit.module('when the assessment is not a peer review assessment', function() {
      test('populates the rubric without data if the user is not the selected assessor', function () {
        SpeedGrader.EG.refreshFullRubric();
        const {data} = window.rubricAssessment.populateRubric.getCall(0).args[1];
        propEqual(data, []);
      });

      test('populates the rubric with data if the user is the selected assessor', function () {
        ENV.current_user_id = '5'
        SpeedGrader.EG.refreshFullRubric();
        const {data} = window.rubricAssessment.populateRubric.getCall(0).args[1];
        propEqual(data, [{ points: 2, criterion_id: '9' }]);
      });
    })
  });

  QUnit.module('#renderCommentTextArea', function(hooks) {
    hooks.beforeEach(function() {
      setupFixtures('<div id="speed_grader_comment_textarea_mount_point"/>')
    })

    hooks.afterEach(function() {
      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('mounts the comment text area when there is an element to mount it in', function() {
      ENV.can_comment_on_submission = true
      SpeedGrader.setup()

      notStrictEqual(document.getElementById('speed_grader_comment_textarea_mount_point').children.length, 0)
    })

    test('does not mount the comment text area when there is no element to mount it in', function() {
      ENV.can_comment_on_submission = false
      SpeedGrader.setup()

      strictEqual(document.getElementById('speed_grader_comment_textarea_mount_point').children.length, 0)
    })
  })

  QUnit.module('#setup', function(hooks) {
    hooks.beforeEach(function() {
      fakeENV.setup({
        ...window.ENV,
        assignment_id: '17',
        course_id: '29',
        grading_role: 'moderator',
        help_url: 'example.com/support',
        show_help_menu_item: false
      })

      setupFixtures();
    })

    hooks.afterEach(function() {
      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('populates the settings mount point', () => {
      SpeedGrader.setup()
      const mountPoint = document.getElementById('speed_grader_settings_mount_point')
      strictEqual(mountPoint.textContent, 'SpeedGrader Settings')
    })
  })

  QUnit.module('#renderSubmissionPreview', hooks => {
    const assignment = {}
    const student = {
      id: '1',
      submission_history: [],
    }
    const enrollment = { user_id: student.id, course_section_id: '1'}
    const submissionComment = {
      created_at: (new Date).toISOString(),
      publishable: false,
      comment: 'a comment',
      author_id: 1,
      author_name: 'an author'
    }
    const submission = {
      id: '3',
      user_id: '1',
      grade_matches_current_submission: true,
      workflow_state: 'active',
      submitted_at: (new Date).toISOString(),
      grade: 'A',
      assignment_id: '456',
      submission_comments: [submissionComment]
    }
    const windowJsonData = {
      ...assignment,
      context_id: '123',
      context: {
        students: [student],
        enrollments: [enrollment],
        active_course_sections: [],
        rep_for_student: {}
      },
      submissions: [submission],
      gradingPeriods: []
    }

    let jsonData;
    let commentToRender

    const commentBlankHtml = `
      <div class="comment">
        <span class="comment"></span>
        <button class="submit_comment_button">
          <span>Submit</span>
        </button>
        <a class="delete_comment_link icon-x">
          <span class="screenreader-only">Delete comment</span>
        </a>
        <div class="comment_attachments"></div>
      </div>
    `;

    const commentAttachmentBlank = `
      <div class="comment_attachment">
        <a href="example.com/{{ submitter_id }}/{{ id }}/{{ comment_id }}"><span class="display_name">&nbsp;</span></a>
      </div>
    `;

    hooks.beforeEach(() => {
      ({jsonData} = window)
      fakeENV.setup({
        ...ENV,
        assignment_id: '17',
        course_id: '29',
        grading_role: 'moderator',
        help_url: 'example.com/support',
        show_help_menu_item: false,
        current_user_id: '1',
        RUBRIC_ASSESSMENT: {}
      })

      setupFixtures(`
        <div id="combo_box_container"></div>
        <div id="iframe_holder"></div>
      `);
      SpeedGrader.setup()
      window.jsonData = windowJsonData
      SpeedGrader.EG.jsonReady()
      setupCurrentStudent()
      commentToRender = {...submissionComment}
      commentToRender.draft = true

      commentRenderingOptions = { commentBlank: $(commentBlankHtml), commentAttachmentBlank: $(commentAttachmentBlank) };
    })

    hooks.afterEach(() => {
      teardownFixtures()
      delete SpeedGrader.EG.currentStudent
      window.jsonData = jsonData
      SpeedGrader.teardown()
      window.location.hash = ''
      document.querySelector('.ui-selectmenu-menu').remove()
    })

    test("the iframe src points to a user's submission", () => {
      SpeedGrader.EG.renderSubmissionPreview('div')
      const iframeSrc = document.getElementById('speedgrader_iframe').getAttribute('src')
      const {pathname, search} = new URL(iframeSrc, 'https://someUrl/')
      const {context_id: course_id} = window.jsonData
      const {assignment_id, user_id} = submission
      strictEqual(
        `${pathname}${search}`,
        `/courses/${course_id}/assignments/${assignment_id}/submissions/${user_id}?preview=true`
      )
    })

    test('renderComment adds the comment text to the submit button for draft comments', () => {
      const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
      const submitLinkScreenreaderText = renderedComment.find('.submit_comment_button').attr('aria-label')

      equal(submitLinkScreenreaderText, 'Submit comment: a comment')
    })

    test('renderComment displays the submit button for draft comments that are publishable', () => {
      commentToRender.publishable = true
      const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
      const button = renderedComment.find('.submit_comment_button')
      notStrictEqual(button.css('display'), 'none')
    });

    test('renderComment hides the submit button for draft comments that are not publishable', () => {
      commentToRender.publishable = false
      const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions)
      const button = renderedComment.find('.submit_comment_button')
      strictEqual(button.css('display'), 'none')
    });
  })

  QUnit.module('#addCommentSubmissionHandler', hooks => {
    const originalJsonData = window.jsonData
    const alphaIdPair = {id: '1'}
    const omegaIdPair = {id: '9'}
    const alphaAnonymousIdPair = {anonymous_id: '00000'}
    const omegaAnonymousIdPair = {anonymous_id: 'ZZZZZ'}

    const baseAssignment = {}
    const assignment = {
      ...baseAssignment,
      ...alphaIdPair,
      anonymize_students: false,
      muted: false
    }
    const anonymousAssignment = {
      ...baseAssignment,
      ...alphaAnonymousIdPair,
      anonymize_students: true,
      muted: true
    }
    const alphaStudent = {
      ...alphaIdPair,
      submission_history: [],
      rubric_assessments: []
    }
    const alphaAnonymousStudent = {
      ...alphaAnonymousIdPair,
      submission_history: [],
      rubric_assessments: []
    }
    const omegaStudent = {...omegaIdPair}
    const omegaAnonymousStudent = {...omegaAnonymousIdPair}
    const sortedPair = [alphaStudent, omegaStudent]
    const sortedAnonymousPair = [alphaAnonymousStudent, omegaAnonymousStudent]
    const alphaEnrollment = {user_id: alphaIdPair.id, course_section_id: '1'}
    const omegaEnrollment = {user_id: omegaIdPair.id, course_section_id: '1'}
    const alphaAnonymousEnrollment = {...alphaAnonymousIdPair, course_section_id: '1'}
    const omegaAnonymousEnrollment = {...omegaAnonymousIdPair, course_section_id: '1'}
    const alphaSubmissionComment = {
      ...alphaIdPair,
      created_at: (new Date).toISOString(),
      publishable: false,
      comment: 'a comment'
    };
    const alphaAnonymousSubmissionComment = {
      ...alphaAnonymousIdPair,
      created_at: (new Date).toISOString(),
      publishable: false,
      comment: 'a comment'
    };
    const alphaSubmission = {
      ...alphaIdPair,
      user_id: alphaStudent.id,
      grade_matches_current_submission: true,
      workflow_state: 'active',
      submitted_at: (new Date).toISOString(),
      updated_at: (new Date).toISOString(),
      grade: 'A',
      assignment_id: '456',
      versioned_attachments: [{
        attachment: {
          id: 1,
          display_name: 'submission.txt'
        }
      }],
      submission_comments: [alphaSubmissionComment]
    }
    alphaSubmission.submission_history = [{...alphaSubmission}]
    const omegaSubmission = {
      ...alphaSubmission,
      ...omegaIdPair,
      user_id: omegaStudent.id
    }
    omegaSubmission.submission_history = [{...omegaSubmission}]
    const alphaAnonymousSubmission = {
      ...alphaAnonymousIdPair,
      grade_matches_current_submission: true,
      workflow_state: 'active',
      submitted_at: (new Date).toISOString(),
      updated_at: (new Date).toISOString(),
      grade: 'A',
      assignment_id: '456',
      versioned_attachments: [{
        attachment: {
          id: 1,
          display_name: 'submission.txt'
        }
      }],
      submission_comments: [alphaAnonymousSubmissionComment]
    }
    const omegaAnonymousSubmission = {
      ...alphaAnonymousSubmission,
      ...omegaAnonymousIdPair
    }
    omegaAnonymousSubmission.submission_history = [{...omegaAnonymousSubmission}]
    const anonymousWindowJsonData = {
      ...anonymousAssignment,
      context_id: '123',
      context: {
        students: sortedAnonymousPair,
        enrollments: [alphaAnonymousEnrollment, omegaAnonymousEnrollment],
        active_course_sections: [],
        rep_for_student: {}
      },
      submissions: [alphaAnonymousSubmission, omegaAnonymousSubmission],
      gradingPeriods: []
    }
    const windowJsonData = {
      ...assignment,
      context_id: '123',
      context: {
        students: sortedPair,
        enrollments: [alphaEnrollment, omegaEnrollment],
        active_course_sections: [],
        rep_for_student: {}
      },
      submissions: [alphaSubmission, omegaSubmission],
      gradingPeriods: []
    }
    let commentElement
    let originalWorkflowState

    QUnit.module('Anonymous Disabled', anonymousDisabledHooks => {
      anonymousDisabledHooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })

        setupFixtures(`
          <div id="combo_box_container"></div>
          <div id="react_pill_container"></div>
          <div class="comment" id="comment_fixture" style="display: none;">
            <button class="submit_comment_button"/></button>
          </div>
        `);
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
        // use a different ID in test because the app code detaches the element from the DOM
        // which we can't directly test
        commentElement = $('#comment_fixture')
      })

      anonymousDisabledHooks.afterEach(() => {
        delete SpeedGrader.EG.currentStudent
        window.jsonData = originalJsonData
        SpeedGrader.teardown()
        teardownFixtures()
        fakeENV.teardown()
        window.location.hash = ''
      })

      QUnit.module('download submission comments link', hooks => {
        hooks.beforeEach(() => {
          SpeedGrader.EG.handleSubmissionSelectionChange()
        })

        test('when students are not anonymized a link is shown', () => {
          const node = document.getElementById('speed_grader_submission_comments_download_mount_point').
            querySelector('a');
          strictEqual(new URL(node.href).pathname, `/submissions/${alphaSubmission.id}/comments.pdf`)
        });
      });

      QUnit.module('given a non-concluded enrollment', () => {
        test('button is shown when comment is publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: true})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, ''))
        })

        test('button is hidden when comment is not publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: false})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, 'none'))
        })
      })

      QUnit.module('given a concluded enrollment', concludedHooks => {
        concludedHooks.beforeEach(() => {
          originalWorkflowState = window.jsonData.studentMap[alphaStudent.id].enrollments[0].workflow_state
          window.jsonData.studentMap[alphaStudent.id].enrollments[0].workflow_state = 'completed'
        })

        concludedHooks.afterEach(() => {
          window.jsonData.studentMap[alphaStudent.id].enrollments[0].workflow_state = originalWorkflowState
        })

        test('button is hidden when comment is publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: true})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, 'none'))
        })

        test('button is hidden when comment is not publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: false})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, 'none'))
        })
      })
    })

    QUnit.module('Anonymous Enabled', () => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })

        setupFixtures(`
          <div class="comment" id="comment_fixture" style="display: none;">
            <button class="submit_comment_button"/></button>
          </div>
        `);
        SpeedGrader.setup()
        window.jsonData = anonymousWindowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
        // use a different ID in test because the app code detaches the element from the DOM
        // which we can't directly test
        commentElement = $('#comment_fixture')
      })

      hooks.afterEach(() => {
        delete SpeedGrader.EG.currentStudent
        window.jsonData = originalJsonData
        SpeedGrader.teardown()
        teardownFixtures()
        fakeENV.teardown()
        window.location.hash = ''
      })

      QUnit.module('given a non-concluded enrollment', () => {
        test('button is shown when comment is publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: true})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, ''))
        })

        test('button is hidden when comment is not publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: false})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, 'none'))
        })
      })

      QUnit.module('given a concluded enrollment', concludedHooks => {
        concludedHooks.beforeEach(() => {
          originalWorkflowState = window.jsonData.studentMap[alphaAnonymousStudent.anonymous_id].enrollments[0].workflow_state
          window.jsonData.studentMap[alphaAnonymousStudent.anonymous_id].enrollments[0].workflow_state = 'completed'
        })

        concludedHooks.afterEach(() => {
          window.jsonData.studentMap[alphaAnonymousStudent.anonymous_id].enrollments[0].workflow_state = originalWorkflowState
        })

        test('button is hidden when comment is publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: true})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, 'none'))
        })

        test('button is hidden when comment is not publishable', () => {
          SpeedGrader.EG.addCommentSubmissionHandler(commentElement, {publishable: false})
          const submitButtons = document.querySelectorAll('.submit_comment_button')
          submitButtons.forEach(submitButton => strictEqual(submitButton.style.display, 'none'))
        })
      })
    })
  })

  QUnit.module('Anonymous Assignments', anonymousHooks => {
    const assignment = {anonymize_students: true}
    const originalJsonData = window.jsonData
    const alpha = {anonymous_id: '00000'}
    const omega = {anonymous_id: 'zzzzz'}
    const alphaStudent = {
      ...alpha,
      submission_history: [],
      rubric_assessments: []
    }
    const omegaStudent = {...omega}
    const studentAnonymousIds = [alphaStudent.anonymous_id, omegaStudent.anonymous_id]
    const sortedPair = [alphaStudent, omegaStudent]
    const unsortedPair = [omegaStudent, alphaStudent]
    const alphaEnrollment = {...alpha, course_section_id: '1'}
    const omegaEnrollment = {...omega, course_section_id: '1'}
    const alphaSubmissionComment = {
      created_at: (new Date).toISOString(),
      publishable: false,
      comment: 'a comment',
      ...alpha
    };
    const omegaSubmissionComment = {
      created_at: (new Date). toISOString(),
      publishable: false,
      comment: 'another comment',
      ...omega
    };
    const alphaSubmission = {
      ...alpha,
      grade_matches_current_submission: true,
      workflow_state: 'active',
      submitted_at: (new Date).toISOString(),
      updated_at: (new Date).toISOString(),
      grade: 'A',
      assignment_id: '456',
      versioned_attachments: [{
        attachment: {
          id: 1,
          display_name: 'submission.txt'
        }
      }],
      submission_comments: [alphaSubmissionComment, omegaSubmissionComment]
    }
    alphaSubmission.submission_history = [{...alphaSubmission}]
    const omegaSubmission = {
      ...alphaSubmission,
      ...omega,
    }
    omegaSubmission.submission_history = [{...omegaSubmission}]
    const windowJsonData = {
      ...assignment,
      context_id: '123',
      context: {
        students: sortedPair,
        enrollments: [alphaEnrollment, omegaEnrollment],
        active_course_sections: [],
        rep_for_student: {}
      },
      submissions: [alphaSubmission, omegaSubmission],
      gradingPeriods: []
    }

    anonymousHooks.beforeEach(() => {
      fakeENV.setup({...window.ENV, force_anonymous_grading: true})
      window.jsonData = windowJsonData
    })

    anonymousHooks.afterEach(() => {
      window.location.hash = ''
      window.jsonData = originalJsonData
    })

    QUnit.module('download submission comments', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })

        setupFixtures(`
          <div id="react_pill_container"></div>
        `);

        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
        SpeedGrader.EG.handleSubmissionSelectionChange()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        fakeENV.teardown()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('when students are anonymized no link is shown', () => {
        strictEqual(document.getElementById('speed_grader_submission_comments_download_mount_point').children.length, 0);
      });
    });

    QUnit.module('renderComment', hooks => {
      const commentBlankHtml = `
        <div class="comment">
          <div class="comment_flex">
            <div class="comment_citation">
              <span class="author_name"></span>
            </div>
          </div>
          <span class="comment"></span>
          <button class="submit_comment_button">
            <span>Submit</span>
          </button>
          <a class="delete_comment_link icon-x">
            <span class="screenreader-only">Delete comment</span>
          </a>
          <div class="comment_attachments"></div>
          <a href="#" class="play_comment_link media-comment" style="display:none;" aria-label="Play media comment">
            click to view
          </a>
        </div>
      `;

      const commentAttachmentBlank = `
        <div class="comment_attachment">
          <a href="example.com/{{ submitter_id }}/{{ id }}/{{ comment_id }}"><span class="display_name">&nbsp;</span></a>
        </div>
      `;

      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })

        commentRenderingOptions = {
          commentBlank: $(commentBlankHtml),
          commentAttachmentBlank: $(commentAttachmentBlank),
          hideStudentNames: true
        };

        setupFixtures(`<div id="right_side"></div>`);
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        fakeENV.teardown()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('renderComment adds the comment text to the submit button for draft comments', () => {
        const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
        SpeedGrader.EG.currentStudent.submission.provisional_grades = [{
          anonymous_grader_id: commentToRender.anonymous_id
        }]
        commentToRender.draft = true;
        const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
        const submitLinkScreenreaderText = renderedComment.find('.submit_comment_button').attr('aria-label');

        equal(submitLinkScreenreaderText, 'Submit comment: a comment');
      });

      test('renderComment displays the submit button for draft comments that are publishable', () => {
        const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
        SpeedGrader.EG.currentStudent.submission.provisional_grades = [{
          anonymous_grader_id: commentToRender.anonymous_id
        }]
        commentToRender.draft = true;
        commentToRender.publishable = true;
        const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
        const button = renderedComment.find('.submit_comment_button')
        notStrictEqual(button.css('display'), 'none')
      });

      test('renderComment hides the submit button for draft comments that are not publishable', () => {
        const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
        SpeedGrader.EG.currentStudent.submission.provisional_grades = [{
          anonymous_grader_id: commentToRender.anonymous_id
        }]
        commentToRender.draft = true;
        commentToRender.publishable = false;
        const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
        const button = renderedComment.find('.submit_comment_button')
        strictEqual(button.css('display'), 'none')
      });

      test('renderComment uses an anonymous name', () => {
        const firstStudentComment = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
        const renderedFirst = SpeedGrader.EG.renderComment(firstStudentComment, commentRenderingOptions);
        strictEqual(renderedFirst.find('.author_name').text(), 'Student 1');
      });

      test('renderComment uses a second anonymous student name', () => {
        const secondStudentComment = SpeedGrader.EG.currentStudent.submission.submission_comments[1];
        const renderedSecond = SpeedGrader.EG.renderComment(secondStudentComment, commentRenderingOptions);
        strictEqual(renderedSecond.find('.author_name').text(), 'Student 2');
      });

      QUnit.module('comment with a media object attached', mediaCommentHooks => {
        let studentComment

        mediaCommentHooks.beforeEach(() => {
          studentComment = SpeedGrader.EG.currentStudent.submission.submission_comments[1]
          studentComment.media_comment_id = 1
          studentComment.media_comment_type = 'video'

          sandbox.stub($.fn, 'mediaComment')
        })

        mediaCommentHooks.afterEach(() => {
          $.fn.mediaComment.restore()

          delete studentComment.media_comment_id
          delete studentComment.media_comment_type
        })

        test('shows the play_comment_link element when rendered', () => {
          const renderedComment = SpeedGrader.EG.renderComment(studentComment, commentRenderingOptions)
          renderedComment.appendTo('#right_side')

          ok(renderedComment.find('.play_comment_link').is(':visible'))
        })

        test('passes the clicked element to the comment dialog when clicked', () => {
          const renderedComment = SpeedGrader.EG.renderComment(studentComment, commentRenderingOptions)
          renderedComment.appendTo('#right_side')
          renderedComment.find('.play_comment_link').click()

          const playCommentLink = $(renderedComment).find('.play_comment_link').get(0)
          const [,,,openingElement] = $.fn.mediaComment.firstCall.args
          strictEqual(openingElement, playCommentLink)
        })
      })
    })

    QUnit.module('#jsonReady', contextHooks => {
      contextHooks.beforeEach(() => {
        sinon.stub(SpeedGrader.EG, 'goToStudent')
      })

      contextHooks.afterEach(() => {
        SpeedGrader.EG.goToStudent.restore()
      })

      // part of jsonReady is a bunch of mutations on jsonData global so
      // to these next few tests are here adequately unit test them
      QUnit.module('jsonData Global', () => {
        test('studentEnrollmentMap is keyed by anonymous id', () => {
          SpeedGrader.EG.jsonReady()
          const studentEnrollmentMapKeys = Object.keys(window.jsonData.studentEnrollmentMap)
          deepEqual(studentEnrollmentMapKeys, studentAnonymousIds)
        })

        test('studentSectionIdsMap is keyed by anonymous id', () => {
          SpeedGrader.EG.jsonReady()
          const studentSectionIdsMapKeys = Object.keys(window.jsonData.studentSectionIdsMap)
          deepEqual(studentSectionIdsMapKeys, studentAnonymousIds)
        })

        test('submissionMap is keyed by anonymous id', () => {
          SpeedGrader.EG.jsonReady()
          const submissionsMapKeys = Object.keys(window.jsonData.submissionsMap)
          deepEqual(submissionsMapKeys, studentAnonymousIds)
        })

        test('studentMap is keyed by anonymous id', () => {
          SpeedGrader.EG.jsonReady()
          const studentMapKeys = Object.keys(window.jsonData.studentMap)
          deepEqual(studentMapKeys, studentAnonymousIds)
        })

        test('studentsWithSubmission.enrollments is present', () => {
          SpeedGrader.EG.jsonReady()
          const reducer = (acc, student) => acc.concat(student.enrollments)
          const enrollments = Object.values(window.jsonData.studentsWithSubmissions).reduce(reducer, [])
          deepEqual(enrollments, [alphaEnrollment, omegaEnrollment])
        })

        test('studentsWithSubmission.section_ids is present', () => {
          SpeedGrader.EG.jsonReady()
          const reducer = (acc, student) => acc.concat(student.section_ids)
          const section_ids = Object.values(window.jsonData.studentsWithSubmissions).reduce(reducer, [])
          const expectedCourseSectionIds = [alphaEnrollment, omegaEnrollment].map(e => e.course_section_id)
          deepEqual(section_ids, expectedCourseSectionIds)
        })

        test('studentsWithSubmission.submission is present', () => {
          SpeedGrader.EG.jsonReady()
          const reducer = (acc, student) => acc.concat(student.submission)
          const submissions = Object.values(window.jsonData.studentsWithSubmissions).reduce(reducer, [])
          deepEqual(submissions, [alphaSubmission, omegaSubmission])
        })

        test('studentsWithSubmission.studentMap is keyed by anonymous id', () => {
          SpeedGrader.EG.jsonReady()
          const reducer = (acc, student) => acc.concat(student.submission)
          const submissions = Object.values(window.jsonData.studentsWithSubmissions).reduce(reducer, [])
          deepEqual(submissions, [alphaSubmission, omegaSubmission])
        })

        test('studentsWithSubmissions is sorted by anonymous ids', () => {
          window.jsonData.context.students = unsortedPair
          SpeedGrader.EG.jsonReady()
          const anonymous_ids = window.jsonData.studentsWithSubmissions.map(student => student.anonymous_id)
          deepEqual(anonymous_ids, [alpha.anonymous_id, omega.anonymous_id])
        })
      })

      QUnit.module('initDropdown', hooks => {
        hooks.beforeEach(() => {
          setupFixtures('<div id="combo_box_container"></div>');
        })

        hooks.afterEach(() => {
          teardownFixtures()
          document.querySelector('.ui-selectmenu-menu').remove()
        })

        test('Students are listed anonymously', () => {
          SpeedGrader.EG.jsonReady()
          const entries = []
          fixtures.querySelectorAll('option').forEach(el => entries.push(el.innerText.trim()))
          deepEqual(entries, ['Student 1 – graded', 'Student 2 – graded'])
        })

        test('Students are sorted by anonymous id when out of order in the select menu', () => {
          window.jsonData.context.students = unsortedPair
          SpeedGrader.EG.jsonReady()
          const anonymousIds = Object.values(fixtures.querySelectorAll('option')).map(el => el.value)
          deepEqual(anonymousIds, studentAnonymousIds)
        })

        test('Students are sorted by anonymous id when in order in the select menu', () => {
          SpeedGrader.EG.jsonReady()
          const anonymousIds = Object.values(fixtures.querySelectorAll('option')).map(el => el.value)
          deepEqual(anonymousIds, studentAnonymousIds)
        })
      })
    })

    QUnit.module('#skipRelativeToCurrentIndex', hooks => {
      hooks.beforeEach(function() {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures();
        sinon.stub(SpeedGrader.EG, 'handleFragmentChanged');
        sinon.stub(SpeedGrader.EG, 'goToStudent')
        SpeedGrader.setup()
        window.jsonData = windowJsonData // setup() resets jsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(function() {
        teardownFixtures()
        SpeedGrader.teardown()
        window.location.hash = ''
        SpeedGrader.EG.goToStudent.restore()
        SpeedGrader.EG.handleFragmentChanged.restore()
        window.jsonData = originalJsonData
      })

      test('goToStudent is called with next student anonymous_id', () => {
        SpeedGrader.EG.skipRelativeToCurrentIndex(1)
        deepEqual(SpeedGrader.EG.goToStudent.firstCall.args, [alphaStudent.anonymous_id])
      })

      test('goToStudent loops back around to previous student anonymous_id', () => {
        SpeedGrader.EG.skipRelativeToCurrentIndex(-1)
        deepEqual(SpeedGrader.EG.goToStudent.firstCall.args, [alphaStudent.anonymous_id])
      })

      test('goToStudent is called with the current (first) student anonymous_id', () => {
        SpeedGrader.EG.skipRelativeToCurrentIndex(0)
        deepEqual(SpeedGrader.EG.goToStudent.firstCall.args, [omegaStudent.anonymous_id])
      })
    })

    QUnit.module('#handleFragmentChanged', hooks => {
      hooks.beforeEach(function() {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures();
        sinon.stub(SpeedGrader.EG, 'goToStudent')
        SpeedGrader.setup()
        sinon.stub(SpeedGrader.EG, 'handleFragmentChanged');
        window.jsonData = windowJsonData // setup() resets jsonData
        SpeedGrader.EG.jsonReady()
        document.location.hash = `#${encodeURIComponent(JSON.stringify(omegaStudent))}`
        SpeedGrader.EG.handleFragmentChanged.restore()
      })

      hooks.afterEach(function() {
        teardownFixtures()
        SpeedGrader.teardown()
        window.location.hash = ''
        SpeedGrader.EG.goToStudent.restore()
        window.jsonData = originalJsonData
      })

      test('goToStudent is called with student anonymous_id', () => {
        SpeedGrader.EG.handleFragmentChanged()
        deepEqual(SpeedGrader.EG.goToStudent.firstCall.args, [omegaStudent.anonymous_id])
      })

      test('goToStudent is called with the first available student if the requested student does not exist in studentMap', () => {
        delete window.jsonData.studentMap[omegaStudent.anonymous_id]
        SpeedGrader.EG.handleFragmentChanged()
        deepEqual(SpeedGrader.EG.goToStudent.firstCall.args, [alphaStudent.anonymous_id])
      })

      test('goToStudent is never called with rep_for_student id', () => {
        window.jsonData.context.rep_for_student = {[omegaStudent.anonymous_id]: {}}
        SpeedGrader.EG.handleFragmentChanged()
        deepEqual(SpeedGrader.EG.goToStudent.firstCall.args, [omegaStudent.anonymous_id])
      })
    })

    QUnit.module('#goToStudent', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures(`
          <img id="avatar_image" alt="" />
          <div id="combo_box_container"></div>
        `);
      })

      hooks.afterEach(() => {
        SpeedGrader.teardown()
        window.location.hash = ''
        teardownFixtures()
        window.jsonData = originalJsonData
        document.querySelector('.ui-selectmenu-menu').remove()
      })

      test('default avatar image is hidden', () => {
        const handleStudentChanged = sinon.stub(SpeedGrader.EG, 'handleStudentChanged')
        SpeedGrader.setup()
        window.jsonData = windowJsonData // setup() resets jsonData
        SpeedGrader.EG.jsonReady()

        SpeedGrader.EG.goToStudent(omegaStudent.anonymous_id)
        const avatarImageStyles = document.getElementById('avatar_image').style
        strictEqual(avatarImageStyles.display, 'none')
        handleStudentChanged.restore()
      })

      test('selectmenu gets updated with the student anonymous id', () => {
        const handleStudentChanged = sinon.stub(SpeedGrader.EG, 'handleStudentChanged')
        SpeedGrader.setup()
        window.jsonData = windowJsonData // setup() resets jsonData
        SpeedGrader.EG.jsonReady()

        SpeedGrader.EG.goToStudent(omegaStudent.anonymous_id)
        const selectMenuVal = document.getElementById('students_selectmenu').value
        strictEqual(selectMenuVal, omegaStudent.anonymous_id)
        handleStudentChanged.restore()
      })

      test('select menu onChange fires', () => {
        SpeedGrader.setup()
        window.jsonData = windowJsonData // setup() resets jsonData
        sinon.stub(SpeedGrader.EG, 'handleStudentChanged')
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.handleStudentChanged.restore()

        const handleStudentChanged = sinon.stub(SpeedGrader.EG, 'handleStudentChanged')
        SpeedGrader.EG.goToStudent(omegaStudent.anonymous_id)
        strictEqual(handleStudentChanged.callCount, 1)
        handleStudentChanged.restore()
      })
    })

    QUnit.module('#handleStudentChanged', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures();
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('updates the location hash with the anonymous id object', () => {
        setupCurrentStudent()
        deepEqual(JSON.parse(decodeURIComponent(document.location.hash.substr(1))), alpha)
      })

      test('url fetches the anonymous_provisional_grades', () => {
        SpeedGrader.EG.currentStudent = {
          ...alphaStudent,
          submission: alphaSubmission
        };
        setupCurrentStudent();
        const [url] = $.getJSON.firstCall.args;
        const {course_id: courseId, assignment_id: assignmentId} = ENV;
        const params = `anonymous_id=${alphaStudent.anonymous_id}&last_updated_at=${alphaSubmission.updated_at}`;
        strictEqual(url, `/api/v1/courses/${courseId}/assignments/${assignmentId}/anonymous_provisional_grades/status?${params}`);
      });
    })

    QUnit.module('#handleSubmissionSelectionChange', hooks => {
      let courses
      let assignments
      let submissions
      let params

      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        courses = `/courses/${ENV.course_id}`;
        assignments = `/assignments/${ENV.assignment_id}`;
        submissions = `/anonymous_submissions/{{anonymousId}}`;
        params = `?download={{attachmentId}}`;
        setupFixtures(`
          <div id="react_pill_container"></div>
          <div id="full_width_container"></div>
          <div id="submission_file_hidden">
            <a
              class="display_name"
              href="${courses}${assignments}${submissions}${params}"
            </a>
          </div>
          <div id="submission_files_list">
            <a class="display_name"></a>
          </div>
          <select id="submission_to_view"><option selected="selected" value="${alphaStudent.anonymous_id}"></option></select>
        `);
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(() => {
        SpeedGrader.teardown()
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
      })

      test('inactive enrollments notice works with anonymous ids', () => {
        SpeedGrader.EG.currentStudent = alphaStudent
        window.jsonData.context.enrollments[0].workflow_state = 'inactive'
        SpeedGrader.EG.handleSubmissionSelectionChange()
        const {classList} = document.getElementById('full_width_container')
        strictEqual(classList.contains('with_enrollment_notice'), true)
      })

      test('removes existing event listeners for resubmit button', () => {
        const spy = sinon.spy($.prototype, "off")
        SpeedGrader.EG.currentStudent = alphaStudent
        window.jsonData.context.enrollments[0].workflow_state = 'inactive'
        SpeedGrader.EG.currentStudent.submission.has_originality_score = true
        SpeedGrader.EG.handleSubmissionSelectionChange()
        ok(spy.called)
      })

      test('isStudentConcluded is called with anonymous id', () => {
        SpeedGrader.EG.currentStudent = alphaStudent
        const isStudentConcluded = sinon.stub(SpeedGrader.EG, 'isStudentConcluded')
        SpeedGrader.EG.handleSubmissionSelectionChange()
        deepEqual(isStudentConcluded.firstCall.args, [alpha.anonymous_id])
        isStudentConcluded.restore()
      })

      test('submission files list template is populated with anonymous submission data', () => {
        SpeedGrader.EG.currentStudent = alphaStudent;
        SpeedGrader.EG.handleSubmissionSelectionChange();
        const {pathname} = new URL(document.querySelector('#submission_files_list a').href);
        const expectedPathname = `${courses}${assignments}/anonymous_submissions/${alphaSubmission.anonymous_id}`;
        equal(pathname, expectedPathname);
      })
    })

    QUnit.module('#initRubricStuff', hooks => {
      const rubricUrl = '/someRubricUrl';

      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        });
        setupFixtures(`
          <div id="rubric_holder">
            <div class="rubric"></div>
            <div class='update_rubric_assessment_url' href=${rubricUrl}></div>
            <button class='save_rubric_button'></button>
          </div>
        `);
        sinon.stub(SpeedGrader.EG, 'showSubmission');
        sinon.stub($.fn, 'ready');
        SpeedGrader.setup();
        window.jsonData = windowJsonData;
        SpeedGrader.EG.jsonReady();
        $.fn.ready.restore();
      });

      hooks.afterEach(() => {
        SpeedGrader.teardown()
        window.location.hash = ''
        window.jsonData = originalJsonData;
        SpeedGrader.EG.showSubmission.restore();
        teardownFixtures();
      });

      test('sets graded_anonymously to true for the rubric ajax request', () => {
        SpeedGrader.EG.domReady();
        const save_rubric_button = document.querySelector('.save_rubric_button');
        save_rubric_button.click();
        const {graded_anonymously} = $.ajaxJSON.getCalls().find(call => call.args[0] === rubricUrl).args[2];
        strictEqual(graded_anonymously, true);
      });
    });

    QUnit.module('#setOrUpdateSubmission', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        });
        setupFixtures();
        sinon.stub($.fn, 'ready');
        SpeedGrader.setup();
        window.jsonData = windowJsonData;
        SpeedGrader.EG.jsonReady();
        $.fn.ready.restore();
      });

      hooks.afterEach(() => {
        SpeedGrader.teardown()
        window.location.hash = ''
        window.jsonData = originalJsonData;
        teardownFixtures();
      });

      test('fetches student via anonymous_id', () => {
        const {submission} = SpeedGrader.EG.setOrUpdateSubmission(alphaSubmission);
        deepEqual(submission, alphaSubmission);
      });
    });

    QUnit.module('#renderAttachment', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures();
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(() => {
        SpeedGrader.teardown()
        window.location.hash = ''
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
      })

      // it is difficult to test that a bound function is passed the correct parameters without
      // fully simulating SpeedGrader so instead let's ensure that both ajax_valid() is true
      // and currentStudent was not undefined
      test('ajax_valid returns', () => {
        const loadDocPreview = sinon.stub($.fn, 'loadDocPreview')
        SpeedGrader.EG.currentStudent = alphaStudent
        const attachment = {content_type: 'application/rtf'}
        SpeedGrader.EG.renderAttachment(attachment)
        strictEqual(loadDocPreview.firstCall.args[0].ajax_valid(), true)
        loadDocPreview.restore()
      })

      test('currentStudent is present', () => {
        SpeedGrader.EG.currentStudent = alphaStudent
        const attachment = {content_type: 'application/rtf'}
        SpeedGrader.EG.renderAttachment(attachment)
        strictEqual(SpeedGrader.EG.currentStudent.anonymous_id, alphaStudent.anonymous_id)
      })

      test('calls loadDocPreview for canvadoc documents with iframe_min_height set to 0', () => {
        const loadDocPreview = sinon.stub($.fn, 'loadDocPreview')
        SpeedGrader.EG.currentStudent = alphaStudent
        const attachment = {content_type: 'application/pdf', canvadoc_url: 'fake_url'}

        SpeedGrader.EG.renderAttachment(attachment)

        const [documentParams] = loadDocPreview.firstCall.args
        strictEqual(documentParams.iframe_min_height, 0)
        loadDocPreview.restore()
      })
    })

    QUnit.module('#showRubric', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })
        setupFixtures();
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('assessment_user_id is set via anonymous id', () => {
        SpeedGrader.EG.showRubric()
        strictEqual(ENV.RUBRIC_ASSESSMENT.assessment_user_id, alphaStudent.anonymous_id)
      })

      test('calls populateNewRubricSummary with editingData set to a non-null value by default', () => {
        sinon.spy(window.rubricAssessment, 'populateNewRubricSummary')
        SpeedGrader.EG.showRubric()

        const [, , , editingData] = window.rubricAssessment.populateNewRubricSummary.firstCall.args
        notStrictEqual(editingData, null)
        window.rubricAssessment.populateNewRubricSummary.restore()
      })

      test('calls populateNewRubricSummary with null editingData when validateEnteredData is false', () => {
        sinon.spy(window.rubricAssessment, 'populateNewRubricSummary')
        SpeedGrader.EG.showRubric({validateEnteredData: false})

        const [, , , editingData] = window.rubricAssessment.populateNewRubricSummary.firstCall.args
        strictEqual(editingData, null)
        window.rubricAssessment.populateNewRubricSummary.restore()
      })
    })

    QUnit.module('#renderCommentAttachment', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })
        setupFixtures('<div id="comment_attachment_blank"><a id="submitter_id" href="{{submitter_id}}" /></a></div>');
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('attachmentElement has submitter_id set to anonymous id', () => {
        const el = SpeedGrader.EG.renderCommentAttachment({id: '1'}, {})
        strictEqual(el.find('a').attr('href'), alphaStudent.anonymous_id)
      })
    })

    QUnit.module('#addCommentDeletionHandler', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false,
          RUBRIC_ASSESSMENT: {}
        })
        setupFixtures();
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('calls isStudentConcluded with student looked up by anonymous id', () => {
        const isStudentConcluded = sinon.stub(SpeedGrader.EG, 'isStudentConcluded')
        SpeedGrader.EG.addCommentDeletionHandler($(), {})
        deepEqual(isStudentConcluded.firstCall.args, [alphaStudent.anonymous_id])
        isStudentConcluded.restore()
      })
    })

    QUnit.module('#addSubmissionComment', hooks => {
      const assignmentURL = '/courses/1/assignments/1'

      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures(`
          <a id="assignment_url" href=${assignmentURL}>Assignment 1<a>
          <textarea id="speed_grader_comment_textarea_mount_point">hi hi</textarea>
        `);
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        // when the textarea is present, setupCurrentStudent invokes addSubmissionComment,
        // however that's what we're testing so let's short circuit that here
        const addSubmissionComment = sinon.stub(SpeedGrader.EG, 'addSubmissionComment')
        setupCurrentStudent()
        addSubmissionComment.restore()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('calls ajaxJSON with anonymous submission url with anonymous id', () => {
        SpeedGrader.EG.addSubmissionComment('draft comment')
        const addSubmissionCommentAjaxJSON = $.ajaxJSON.getCalls().find(call =>
          call.args[0] === `${assignmentURL}/anonymous_submissions/${alphaStudent.anonymous_id}`
        )
        notStrictEqual(addSubmissionCommentAjaxJSON, undefined)
      })

      test('calls ajaxJSON with with anonymous id in data', () => {
        SpeedGrader.EG.addSubmissionComment('draft comment')
        const addSubmissionCommentAjaxJSON = $.ajaxJSON.getCalls().find(call =>
          call.args[0] === `${assignmentURL}/anonymous_submissions/${alphaStudent.anonymous_id}`
        )
        const [,,formData] = addSubmissionCommentAjaxJSON.args
        strictEqual(formData['submission[anonymous_id]'], alphaStudent.anonymous_id)
      })

      test('calls handleGradingError if an error is encountered', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON').callsFake((_url, _method, _form, _success, error) => {
          error()
        })
        const handleGradingError = sinon.stub(SpeedGrader.EG, 'handleGradingError')
        const revertFromFormSubmit = sinon.stub(SpeedGrader.EG, 'revertFromFormSubmit')

        SpeedGrader.EG.addSubmissionComment('terrible failure')
        strictEqual(handleGradingError.callCount, 1)

        revertFromFormSubmit.restore()
        handleGradingError.restore()
      })

      test('calls revertFromFormSubmit to clear the comment if an error is encountered', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON').callsFake((_url, _method, _form, _success, error) => {
          error()
        })
        const revertFromFormSubmit = sinon.stub(SpeedGrader.EG, 'revertFromFormSubmit')

        SpeedGrader.EG.addSubmissionComment('terrible failure')
        const [params] = revertFromFormSubmit.firstCall.args
        deepEqual(params, {errorSubmitting: true})

        revertFromFormSubmit.restore()
      })
    })

    QUnit.module('#handleGradeSubmit', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })
        setupFixtures(`
          <div id="grade_container">
            <input />
          </div>
        `);
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('calls isStudentConcluded with student looked up by anonymous id', () => {
        const isStudentConcluded = sinon.spy(SpeedGrader.EG, 'isStudentConcluded')
        SpeedGrader.EG.handleGradeSubmit({}, false)
        deepEqual(isStudentConcluded.firstCall.args, [alphaStudent.anonymous_id])
        isStudentConcluded.restore()
      })

      test('calls ajaxJSON with anonymous id in data', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON')
        SpeedGrader.EG.handleGradeSubmit({}, false)
        const [,,formData] = $.ajaxJSON.firstCall.args
        strictEqual(formData['submission[anonymous_id]'], alphaStudent.anonymous_id)
      })

      test('calls handleGradingError if an error is encountered', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON').callsFake((_url, _method, _form, _success, error) => { error() })
        const handleGradingError = sinon.stub(SpeedGrader.EG, 'handleGradingError')

        SpeedGrader.EG.handleGradeSubmit({}, false)
        strictEqual(handleGradingError.callCount, 1)

        handleGradingError.restore()
      })

      test('clears the grade input on an error if the user is not a moderator', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON').callsFake((_url, _method, _form, _success, error) => { error() })
        const handleGradingError = sinon.stub(SpeedGrader.EG, 'handleGradingError')
        const showGrade = sinon.stub(SpeedGrader.EG, 'showGrade')
        ENV.grading_role = 'provisional_grader'

        SpeedGrader.EG.handleGradeSubmit({}, false)
        strictEqual(showGrade.callCount, 1)

        showGrade.restore()
        handleGradingError.restore()
      })

      test('clears the grade input on an error if moderating but no provisional grade was chosen', () => {
        const unselectedGrade = { grade: 1, selected: false }
        SpeedGrader.EG.currentStudent.submission.provisional_grades = [unselectedGrade]
        SpeedGrader.EG.setupProvisionalGraderDisplayNames()

        $.ajaxJSON.callsFake((_url, _method, _form, _success, error) => { error() })
        const handleGradingError = sinon.stub(SpeedGrader.EG, 'handleGradingError')
        const showGrade = sinon.stub(SpeedGrader.EG, 'showGrade')

        ENV.grading_role = 'moderator'
        SpeedGrader.EG.handleGradeSubmit({}, false)
        strictEqual(showGrade.callCount, 1)

        showGrade.restore()
        handleGradingError.restore()
      })


      test('reverts the provisional grade fields on an error if moderating and a provisional grade was chosen', () => {
        const fakeGrade = { grade: 1, selected: true }
        SpeedGrader.EG.currentStudent.submission.provisional_grades = [fakeGrade]
        SpeedGrader.EG.setupProvisionalGraderDisplayNames()

        $.ajaxJSON.callsFake((_url, _method, _form, _success, error) => { error() })
        const handleGradingError = sinon.stub(SpeedGrader.EG, 'handleGradingError')
        const setActiveProvisionalGradeFields = sinon.stub(SpeedGrader.EG, 'setActiveProvisionalGradeFields')

        ENV.grading_role = 'moderator'
        SpeedGrader.EG.handleGradeSubmit({}, false)

        const [params] = setActiveProvisionalGradeFields.firstCall.args
        strictEqual(params.grade, fakeGrade)

        setActiveProvisionalGradeFields.restore()
        handleGradingError.restore()
      })

      test('submission is always marked as graded anonymously', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON')
        SpeedGrader.EG.handleGradeSubmit({}, false);
        const [,,formData] = $.ajaxJSON.firstCall.args;
        strictEqual(formData['submission[graded_anonymously]'], true);
      });
    })

    QUnit.module('#updateSelectMenuStatus', hooks => {
      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })

        setupFixtures('<div id="combo_box_container"></div>');
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
        document.querySelector('.ui-selectmenu-menu').remove()
      })

      test('calls updateSelectMenuStatus with "anonymous_id"', assert => {
        const done = assert.async()
        SpeedGrader.EG.updateSelectMenuStatus({...alphaStudent, submission_state: 'not_graded'})
        setTimeout(() => { // the select menu has some sort of time dependent behavior
          deepEqual(document.querySelector('#combo_box_container option').innerText, 'Student 1 - not graded')
          done()
        }, 10)
      })
    })

    QUnit.module('#renderSubmissionPreview', hooks => {
      const {context_id: course_id} = windowJsonData
      const {assignment_id} = alphaSubmission
      const {anonymous_id} = alphaStudent

      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })

        setupFixtures('<div id="iframe_holder">not empty</div>');
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test("the iframe src points to a user's submission by anonymous_id", () => {
        SpeedGrader.EG.renderSubmissionPreview('div')
        const iframeSrc = document.getElementById('speedgrader_iframe').getAttribute('src')
        const {pathname, search} = new URL(iframeSrc, 'https://someUrl/')
        strictEqual(
          `${pathname}${search}`,
          `/courses/${course_id}/assignments/${assignment_id}/anonymous_submissions/${anonymous_id}?preview=true&hide_student_name=1`
        )
      })
    })

    QUnit.module('#attachmentIframeContents', hooks => {
      const {context_id: course_id} = windowJsonData
      const {assignment_id} = alphaSubmission
      const {anonymous_id} = alphaStudent

      hooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          assignment_id: '17',
          course_id: '29',
          grading_role: 'moderator',
          help_url: 'example.com/support',
          show_help_menu_item: false
        })

        setupFixtures(`
          <div id="submission_file_hidden">
            <a
              class="display_name"
              href="/courses/${course_id}/assignments/${assignment_id}/submissions/{{anonymousId}}?download={{attachmentId}}">
            </a>
          </div>
        `);
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        teardownFixtures()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        SpeedGrader.teardown()
        window.location.hash = ''
      })

      test('attachment src points to the submission download url', () => {
        const attachment = {id: '101112'}
        const divContents = SpeedGrader.EG.attachmentIframeContents(attachment, 'div')
        const div = document.createElement('div')
        div.innerHTML = divContents

        strictEqual(
          div.children[0].getAttribute('src'),
          `/courses/${course_id}/assignments/${assignment_id}/submissions/${anonymous_id}?download=101112`
        )
      })
    })
  })

  QUnit.module('#showSubmission', (hooks) => {
    hooks.beforeEach(() => {
      sinon.stub(SpeedGrader.EG, 'showGrade')
      sinon.stub(SpeedGrader.EG, 'showDiscussion')
      sinon.stub(SpeedGrader.EG, 'showRubric')
      sinon.stub(SpeedGrader.EG, 'updateStatsInHeader')
      sinon.stub(SpeedGrader.EG, 'showSubmissionDetails')
      sinon.stub(SpeedGrader.EG, 'refreshFullRubric')
    })

    hooks.afterEach(() => {
      SpeedGrader.EG.showGrade.restore()
      SpeedGrader.EG.showDiscussion.restore()
      SpeedGrader.EG.showRubric.restore()
      SpeedGrader.EG.updateStatsInHeader.restore()
      SpeedGrader.EG.showSubmissionDetails.restore()
      SpeedGrader.EG.refreshFullRubric.restore()
    })

    test('calls showRubric with validateEnteredData set to false', () => {
      SpeedGrader.EG.showSubmission()

      const [params] = SpeedGrader.EG.showRubric.firstCall.args
      strictEqual(params.validateEnteredData, false)
    })
  })

  QUnit.module('#removeModerationBarAndShowSubmission', function(hooks) {
    hooks.beforeEach(() => {
      setupFixtures(`
        <div id="full_width_container" class="with_moderation_tabs"></div>
        <div id="moderation_bar"></div>
        <form id="add_a_comment" style="display:none;"></form>
      `);
      sinon.stub(SpeedGrader.EG, 'domReady')
      sinon.stub(SpeedGrader.EG, 'showSubmission')
      SpeedGrader.setup()
    })

    hooks.afterEach(() => {
      SpeedGrader.EG.showSubmission.restore()
      SpeedGrader.EG.domReady.restore()
      teardownFixtures()
    })

    test('removes the "with_moderation_tabs" class from the container', () => {
      SpeedGrader.EG.removeModerationBarAndShowSubmission()
      const containerClasses = document.getElementById('full_width_container').className
      strictEqual(containerClasses.includes('with_moderation_tabs'), false)
    })

    test('hides the moderation bar', () => {
      SpeedGrader.EG.removeModerationBarAndShowSubmission()
      const moderationBar = document.getElementById('moderation_bar')
      strictEqual(moderationBar.style.display, 'none')
    })

    test('calls showSubmission', () => {
      SpeedGrader.EG.removeModerationBarAndShowSubmission()
      strictEqual(SpeedGrader.EG.showSubmission.callCount, 1)
    })

    test('reveals the comment form', () => {
      SpeedGrader.EG.removeModerationBarAndShowSubmission()
      const addCommentForm = document.getElementById('add_a_comment')
      strictEqual(addCommentForm.style.display, '')
    })
  })

  QUnit.module('#handleGradingError', (hooks) => {
    hooks.beforeEach(() => {
      sinon.stub($, 'flashError')
    })

    hooks.afterEach(() => {
      $.flashError.restore()
    })

    test('shows an error message in a flash dialog', () => {
      SpeedGrader.EG.handleGradingError({})
      strictEqual($.flashError.callCount, 1)
    })

    test('shows a specific error message if given a MAX_GRADERS_REACHED error code', () => {
      const maxGradersError = {base: 'too many graders', error_code: 'MAX_GRADERS_REACHED'}
      SpeedGrader.EG.handleGradingError({errors: maxGradersError})

      const [errorMessage] = $.flashError.firstCall.args
      strictEqual(errorMessage, 'The maximum number of graders has been reached for this assignment.')
    })

    test('forbears from showing an error message if given a PROVISIONAL_GRADE_INVALID_SCORE error code', () => {
      const maxGradersError = {base: 'bad grade', error_code: 'PROVISIONAL_GRADE_INVALID_SCORE'}
      SpeedGrader.EG.handleGradingError({errors: maxGradersError})

      strictEqual($.flashError.callCount, 0)
    })

    test('shows a generic error message if not given a MAX_GRADERS_REACHED error code', () => {
      SpeedGrader.EG.handleGradingError({})

      const [errorMessage] = $.flashError.firstCall.args
      strictEqual(errorMessage, 'An error occurred updating this assignment.')
    })

    test('warns the user that a selected grade cannot be altered', () => {
      SpeedGrader.EG.handleGradingError({errors: {error_code: 'PROVISIONAL_GRADE_MODIFY_SELECTED'}})
      const [errorMessage] = $.flashError.firstCall.args
      strictEqual(errorMessage, 'The grade you entered has been selected and can no longer be changed.')
    })
  })

  QUnit.module('#renderProvisionalGradeSelector', function(hooks) {
    const EG = SpeedGrader.EG
    let submission

    hooks.beforeEach(() => {
      ENV.grading_type = 'gpa_scale'
      setupFixtures(`
        <div id='grading_details_mount_point'></div>
        <div id='grading_box_selected_grader'></div>
        <input type='text' id='grade' />
      `);

      SpeedGrader.setup()
      EG.currentStudent = {
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, grade: '1', scorer_name: 'Gradual'},
            {provisional_grade_id: '2', readonly: true, grade: '2', scorer_name: 'Gradus'},
          ]
        }
      }
      EG.setupProvisionalGraderDisplayNames()

      submission = EG.currentStudent.submission

      sinon.stub(EG, 'setupProvisionalGraderDisplayNames')
      sinon.stub(ReactDOM, 'render')
      sinon.stub(ReactDOM, 'unmountComponentAtNode')
    })

    hooks.afterEach(() => {
      ReactDOM.unmountComponentAtNode.restore()
      ReactDOM.render.restore()
      EG.setupProvisionalGraderDisplayNames.restore()

      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('displays the component if at least one provisional grade is present', () => {
      EG.renderProvisionalGradeSelector()
      strictEqual(ReactDOM.render.callCount, 1)
    })

    test('unmounts the component if no provisional grades are present', () => {
      submission.provisional_grades = []
      EG.renderProvisionalGradeSelector()
      strictEqual(ReactDOM.unmountComponentAtNode.callCount, 1)
    })

    test('passes jsonData.points_possible to the component as pointsPossible', () => {
      window.jsonData.points_possible = 12
      EG.renderProvisionalGradeSelector()

      const [SpeedGraderProvisionalGradeSelector] = ReactDOM.render.firstCall.args
      strictEqual(SpeedGraderProvisionalGradeSelector.props.pointsPossible, 12)
    })

    test('passes the assignment grading type to the component as gradingType', () => {
      EG.renderProvisionalGradeSelector()

      const [SpeedGraderProvisionalGradeSelector] = ReactDOM.render.firstCall.args
      strictEqual(SpeedGraderProvisionalGradeSelector.props.gradingType, 'gpa_scale')
    })

    test('passes the list of provisional grades to the component', () => {
      EG.renderProvisionalGradeSelector()

      const [SpeedGraderProvisionalGradeSelector] = ReactDOM.render.firstCall.args
      deepEqual(
        SpeedGraderProvisionalGradeSelector.props.provisionalGrades,
        submission.provisional_grades
      )
    })

    test('passes the hash of grader display names to the component', () => {
      EG.renderProvisionalGradeSelector()

      const [SpeedGraderProvisionalGradeSelector] = ReactDOM.render.firstCall.args
      deepEqual(
        SpeedGraderProvisionalGradeSelector.props.provisionalGraderDisplayNames,
        {1: 'Gradual', 2: 'Gradus'}
      )
    })

    test('calls setupProvisionalGraderDisplayNames if showingNewStudent is true', () => {
      SpeedGrader.EG.renderProvisionalGradeSelector({showingNewStudent: true})
      strictEqual(SpeedGrader.EG.setupProvisionalGraderDisplayNames.callCount, 1)
    })

    test('does not call setupProvisionalGraderDisplayNames if showingNewStudent is not true', () => {
      SpeedGrader.EG.renderProvisionalGradeSelector()
      strictEqual(SpeedGrader.EG.setupProvisionalGraderDisplayNames.callCount, 0)
    })
  })

  QUnit.module('#handleProvisionalGradeSelected', function(hooks) {
    const EG = SpeedGrader.EG
    let submission

    hooks.beforeEach(() => {
      setupFixtures(`
        <div id='grading_details_mount_point'></div>
        <div id='grading_box_selected_grader'></div>
        <input type='text' id='grade' />
      `);

      SpeedGrader.setup()
      EG.currentStudent = {
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, scorer_name: 'Gradual', grade: 11},
            {provisional_grade_id: '2', readonly: true, scorer_name: 'Gradus', grade: 22},
          ]
        }
      }
      EG.setupProvisionalGraderDisplayNames()

      submission = EG.currentStudent.submission
      sinon.stub(EG, 'submitSelectedProvisionalGrade')
      sinon.stub(EG, 'setActiveProvisionalGradeFields')
      sinon.stub(EG, 'renderProvisionalGradeSelector')
    })

    hooks.afterEach(() => {
      EG.renderProvisionalGradeSelector.restore()
      EG.setActiveProvisionalGradeFields.restore()
      EG.submitSelectedProvisionalGrade.restore()

      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('calls submitSelectedProvisionalGrade with the grade ID when selectedGrade is passed', () => {
      EG.handleProvisionalGradeSelected({selectedGrade: submission.provisional_grades[0]})

      const [selectedGradeId] = EG.submitSelectedProvisionalGrade.firstCall.args
      strictEqual(selectedGradeId, '1')
    })

    test('calls setActiveProvisionalGradeFields with the selected grade when selectedGrade is passed', () => {
      EG.handleProvisionalGradeSelected({selectedGrade: submission.provisional_grades[0]})

      const {grade} = EG.setActiveProvisionalGradeFields.firstCall.args[0]
      strictEqual(grade.provisional_grade_id, '1')
    })

    test('calls setActiveProvisionalGradeFields with the selected label when selectedGrade is passed', () => {
      EG.handleProvisionalGradeSelected({selectedGrade: submission.provisional_grades[0]})

      const {label} = EG.setActiveProvisionalGradeFields.firstCall.args[0]
      strictEqual(label, 'Gradual')
    })

    test('calls setActiveProvisionalGradeFields with the label "Custom" when isNewGrade is passed', () => {
      EG.handleProvisionalGradeSelected({isNewGrade: true})

      const {label} = EG.setActiveProvisionalGradeFields.firstCall.args[0]
      strictEqual(label, 'Custom')
    })

    test('calls renderProvisionalGradeSelector when isNewGrade is passed', () => {
      EG.handleProvisionalGradeSelected({isNewGrade: true})
      strictEqual(EG.renderProvisionalGradeSelector.callCount, 1)
    })

    test('unselects existing grades when isNewGrade is passed', () => {
      EG.handleProvisionalGradeSelected({isNewGrade: true})
      strictEqual(submission.provisional_grades.some(grade => grade.selected), false)
    })
  })

  QUnit.module('#setActiveProvisionalGradeFields', (hooks) => {
    const EG = SpeedGrader.EG

    hooks.beforeEach(() => {
      // A lot of these are polluting the space prior to execution, make sure things are clean
      $('.score').remove();
      setupFixtures(`
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
          <div class="score"></div>
        </div>
      `);

      SpeedGrader.setup()
      EG.currentStudent = {
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, scorer_name: 'Gradual', grade: 11},
            {provisional_grade_id: '2', readonly: true, scorer_name: 'Gradus', grade: 22},
          ]
        }
      }
      EG.setupProvisionalGraderDisplayNames()
    })

    hooks.afterEach(() => {
      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('sets the selected grader text to the passed-in label', () => {
      EG.setActiveProvisionalGradeFields({label: 'fred'})
      strictEqual($('#grading-box-selected-grader').text(), 'fred')
    })

    test('sets the selected grader text to empty if no label is passed', () => {
      EG.setActiveProvisionalGradeFields()
      strictEqual($('#grading-box-selected-grader').text(), '')
    })

    test('sets the grade input value to the passed-in grade', () => {
      EG.setActiveProvisionalGradeFields({grade: {grade: 500}})
      strictEqual($('#grading-box-extended').val(), '500')
    })

    test('does not set the grade input value if no grade is passed', () => {
      $('#grading-box-extended').val(234)
      EG.setActiveProvisionalGradeFields()
      strictEqual($('#grading-box-extended').val(), '234')
    })

    test('sets the score field to the score of the passed-in grade', () => {
      EG.setActiveProvisionalGradeFields({grade: {score: 10}})
      strictEqual($('.score').text(), '10')
    })

    test('does not set the score field if no grade is passed', () => {
      $('.score').text('234')
      EG.setActiveProvisionalGradeFields()
      strictEqual($('.score').text(), '234')
    })

    QUnit.module('when the current submission is excused', excusedHooks => {
      let fakeGrade

      excusedHooks.beforeEach(() => {
        EG.currentStudent.submission.excused = true
        fakeGrade = {grade: {score: 100, readonly: false}}
      })

      test('sets the grade field to EX if passed an editable grade', () => {
        EG.setActiveProvisionalGradeFields(fakeGrade)
        strictEqual($('#grading-box-extended').val(), 'EX')
      })

      test('sets the score field to empty if passed an editable grade', () => {
        EG.setActiveProvisionalGradeFields(fakeGrade)
        strictEqual($('.score').text(), '')
      })
    })
  })

  QUnit.module('#fetchProvisionalGrades', (hooks) => {
    const EG = SpeedGrader.EG

    hooks.beforeEach(() => {
      ENV.grading_role = 'moderator'

      setupFixtures(`
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `);

      SpeedGrader.setup()
      EG.currentStudent = {
        anonymous_id: 'abcde',
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, scorer_name: 'Gradual', grade: 11},
            {provisional_grade_id: '2', readonly: true, scorer_name: 'Gradus', grade: 22},
          ],
          updated_at: 'never'
        }
      }
      EG.setupProvisionalGraderDisplayNames()
      ENV.provisional_status_url = 'some_url_or_other'

      sinon.stub(EG, 'onProvisionalGradesFetched')
      $.getJSON.callsFake((url, params, success) => {
        success({needs_provisional_grade: true})
      })
    })

    hooks.afterEach(() => {
      EG.onProvisionalGradesFetched.restore()
      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('calls onProvisionalGradesFetched upon fetching data', () => {
      EG.fetchProvisionalGrades()

      const [data] = EG.onProvisionalGradesFetched.firstCall.args
      deepEqual(data, {needs_provisional_grade: true})
    })

    QUnit.module('provisional status URL', () => {
      test('includes the ID of the current student', () => {
        EG.fetchProvisionalGrades()

        const [url] = $.getJSON.firstCall.args
        strictEqual(url.includes('anonymous_id=abcde'), true)
      })

      test('includes the last_updated_at parameter if the user is a moderator', () => {
        EG.fetchProvisionalGrades()

        const [url] = $.getJSON.firstCall.args
        strictEqual(url.includes('last_updated_at=never'), true)
      })

      test('omits the last_updated_at parameter if the user is not a moderator', () => {
        ENV.grading_role = 'provisional_grader'
        EG.fetchProvisionalGrades()

        const [url] = $.getJSON.firstCall.args
        strictEqual(url.includes('last_updated_at=never'), false)
      })
    })
  })

  QUnit.module('#onProvisionalGradesFetched', (hooks) => {
    const EG = SpeedGrader.EG
    let submission

    hooks.beforeEach(() => {
      setupFixtures(`
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `);

      SpeedGrader.setup()
      EG.currentStudent = {
        anonymous_id: 'abcde',
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, scorer_name: 'Gradual', grade: 11},
            {provisional_grade_id: '2', readonly: true, scorer_name: 'Gradus', grade: 22},
          ],
          updated_at: 'never'
        }
      }
      EG.setupProvisionalGraderDisplayNames()

      submission = EG.currentStudent.submission

      sinon.stub(EG, 'showStudent')
      sinon.stub(SpeedGraderHelpers, 'submissionState').callsFake(() => 'not_submitted')
    })

    hooks.afterEach(() => {
      SpeedGraderHelpers.submissionState.restore()
      EG.showStudent.restore()

      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    test('sets needs_provisional_grade to the supplied value', () => {
      EG.onProvisionalGradesFetched({needs_provisional_grade: true})
      strictEqual(EG.currentStudent.needs_provisional_grade, true)
    })

    test('calls SpeedGraderHelpers.submissionState to set currentStudent.submission_state', () => {
      EG.onProvisionalGradesFetched({needs_provisional_grade: true})
      strictEqual(EG.currentStudent.submission_state, 'not_submitted')
    })

    test('calls showStudent', () => {
      EG.onProvisionalGradesFetched({})
      strictEqual(EG.showStudent.callCount, 1)
    })

    QUnit.module('when the user is a moderator and provisional_grades are returned', () => {
      const fakeData = {
        provisional_grades: [{grade: -1}],
        updated_at: 'now',
        final_provisional_grade: {grade: -999}
      }

      test('sets submission.provisional_grades to the supplied value', () => {
        ENV.grading_role = 'moderator'
        EG.onProvisionalGradesFetched(fakeData)
        deepEqual(submission.provisional_grades, [{grade: -1}])
      })

      test('sets submission.updated_at to the supplied value', () => {
        ENV.grading_role = 'moderator'
        EG.onProvisionalGradesFetched(fakeData)
        deepEqual(submission.updated_at, 'now')
      })

      test('sets submission.final_provisional_grade to the supplied value', () => {
        ENV.grading_role = 'moderator'
        EG.onProvisionalGradesFetched(fakeData)
        deepEqual(submission.final_provisional_grade, {grade: -999})
      })
    })
  })

  QUnit.module('#submitSelectedProvisionalGrade', (hooks) => {
    const EG = SpeedGrader.EG

    hooks.beforeEach(() => {
      ENV.provisional_select_url = "provisional_select_url?{{provisional_grade_id}}"
      setupFixtures(`
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `);
      SpeedGrader.setup()
      EG.currentStudent = {
        anonymous_id: 'abcde',
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, scorer_name: 'Gradual', grade: 11},
            {provisional_grade_id: '2', readonly: true, scorer_name: 'Gradus', grade: 22},
          ],
          updated_at: 'never'
        }
      }
      EG.setupProvisionalGraderDisplayNames()

      $.ajaxJSON.callsFake((url, method, params, success) => {
        success(params)
      })
      sinon.stub(EG, 'fetchProvisionalGrades')
      sinon.stub(EG, 'renderProvisionalGradeSelector')
    })

    hooks.afterEach(() => {
      EG.renderProvisionalGradeSelector.restore()
      EG.fetchProvisionalGrades.restore()
      SpeedGrader.teardown()
      window.location.hash = ''

      teardownFixtures()
    })

    test('includes the value of ENV.provisional_select_url and provisionalGradeId in the URL', () => {
      EG.submitSelectedProvisionalGrade(123)
      const addSubmissionCommentAjaxJSON = $.ajaxJSON.getCalls().find(call =>
        call.args[0] === 'provisional_select_url?123'
      )
      notStrictEqual(addSubmissionCommentAjaxJSON, undefined)
    })

    QUnit.module('when the request completes successfully', () => {
      test('calls fetchProvisionalGrades when refetchOnSuccess is true', () => {
        EG.submitSelectedProvisionalGrade(1, true)
        strictEqual(EG.fetchProvisionalGrades.callCount, 1)
      })

      test('calls renderProvisionalGradeSelector when refetchOnSuccess is false', () => {
        EG.submitSelectedProvisionalGrade(1, false)
        strictEqual(EG.renderProvisionalGradeSelector.callCount, 1)
      })
    })
  })

  QUnit.module('#loadSubmissionPreview', (hooks) => {
    const EG = SpeedGrader.EG

    hooks.beforeEach(() => {
      setupFixtures(`
        <div id='this_student_does_not_have_a_submission'></div>
        <div id='iframe_holder'>
          I am an iframe holder!
        </div>
      `);
      SpeedGrader.setup()
      EG.currentStudent = {
        submission: { submission_type: 'quiz', workflow_state: 'unsubmitted' }
      }
    })

    hooks.afterEach(() => {
      teardownFixtures()
      SpeedGrader.teardown()
      window.location.hash = ''
    })

    QUnit.module('when a submission is unsubmitted', () => {
      test('shows the "this student does not have a submission" div', () => {
        const $noSubmission = $('#this_student_does_not_have_a_submission')
        $noSubmission.hide()

        EG.loadSubmissionPreview()
        ok($noSubmission.is(':visible'))
      })

      test('clears the contents of the iframe holder', () => {
        EG.loadSubmissionPreview()

        strictEqual($('#iframe_holder').html(), '')
      })
    })
  })

  QUnit.module('when a course has multiple sections', (hooks) => {
    const sectionSelectPath = '#section-menu li a[data-section-id="2"]'
    const allSectionsSelectPath = '#section-menu li a[data-section-id="all"]'
    let originalWindowJSONData

    hooks.beforeEach(() => {
      setupFixtures(`
        <div id="combo_box_container">
        </div>
        <ul
          id="section-menu"
          class="ui-selectmenu-menu ui-widget ui-widget-content ui-selectmenu-menu-dropdown ui-selectmenu-open"
          style="display:none;" role="listbox" aria-activedescendant="section-menu-link"
        >
          <li role="presentation" class="ui-selectmenu-item">
            <a href="#" tabindex="-1" role="option" aria-selected="true" id="section-menu-link">
              <span>Showing: <span id="section_currently_showing">All Sections</span></span>
            </a>
            <ul>
              <li><a class="selected" data-section-id="all" href="#">Show All Sections</a></li>
            </ul>
          </li>
        </ul>
      `);

      originalWindowJSONData = window.jsonData
      window.jsonData = {
        context: {
          students: [
            {
              id: 4,
              name: 'Guy B. Studying'
            }
          ],
          enrollments: [
            {
              user_id: 4,
              workflow_state: 'active',
              course_section_id: 1
            },
            {
              user_id: 4,
              workflow_state: 'active',
              course_section_id: 2
            },
            {
              user_id: 4,
              workflow_state: 'active',
              course_section_id: 3
            }
          ],
          active_course_sections: [
            {
              id: 1,
              name: 'The First Section'
            },
            {
              id: 2,
              name: 'The Second Section'
            },
            {
              id: 3,
              name: 'The Third Section'
            },
            {
              id: 4,
              name: 'The Lost Section'
            }
          ]
        },
        submissions: []
      }

      // This function gets set by a jQuery extension in a way that doesn't
      // appear to happen as part of the testing setup. So far as I can tell
      // it does nothing except return the current jQuery element.
      $.fn.menu = function() { return $(this) }

      sandbox.stub($, 'post').yields()
      sandbox.stub(SpeedGraderHelpers, 'reloadPage')
      sandbox.stub(SpeedGrader.EG, 'handleFragmentChanged')
      sandbox.stub(userSettings, 'contextSet')
      sandbox.stub(userSettings, 'contextRemove')
      sandbox.stub(userSettings, 'contextGet').returns('3')
    })

    hooks.afterEach(() => {
      userSettings.contextGet.restore()
      userSettings.contextRemove.restore()
      userSettings.contextSet.restore()
      SpeedGrader.EG.handleFragmentChanged.restore()
      SpeedGraderHelpers.reloadPage.restore()
      $.post.restore()
      delete $.fn.menu

      document.querySelectorAll('.ui-selectmenu-menu').forEach(element => { element.remove() })

      window.location.hash = ''
      teardownFixtures()
      SpeedGrader.teardown()
      window.jsonData = originalWindowJSONData
    })

    test('initially selects the section in userSettings if ENV.new_gradebook_enabled is not true', () => {
      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      const currentlyShowing = document.querySelector('#section_currently_showing')
      strictEqual(currentlyShowing.innerText, 'The Third Section')
    })

    test('initially selects the section in ENV.selected_section_id if ENV.new_gradebook_enabled is true', () => {
      window.ENV.new_gradebook_enabled = true
      window.ENV.selected_section_id = 2

      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      const currentlyShowing = document.querySelector('#section_currently_showing')
      strictEqual(currentlyShowing.innerText, 'The Second Section')

      delete window.ENV.selected_section_id
      delete window.ENV.new_gradebook_enabled
    })

    test('reloads SpeedGrader when the user selects a new section and ENV.settings_url is set', () => {
      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      $(sectionSelectPath).click()
      strictEqual(SpeedGraderHelpers.reloadPage.callCount, 1)
    })

    test('reloads SpeedGrader when the user selects a new section and ENV.settings_url is not set', () => {
      const settingsURL = window.ENV.settings_url
      delete window.ENV.settings_url

      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      $(sectionSelectPath).click()
      strictEqual(SpeedGraderHelpers.reloadPage.callCount, 1)

      window.ENV.settings_url = settingsURL
    })

    test('saves the selected section in userSettings when one is selected', () => {
      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      $(sectionSelectPath).click()

      const params = userSettings.contextSet.firstCall.args
      deepEqual(params, ['grading_show_only_section', 2])
    })

    test('annuls the selected section in userSettings when "all sections" is selected', () => {
      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      $(allSectionsSelectPath).click()

      const [key] = userSettings.contextRemove.firstCall.args
      strictEqual(key, 'grading_show_only_section')
    })

    test('posts the selected section to the settings URL when a specific section is selected', () => {
      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      $(sectionSelectPath).click()

      const [, params] = $.post.firstCall.args
      deepEqual(params, {selected_section_id: 2})
    })

    test('posts the value "all" to the settings URL when "all sections" is selected', () => {
      SpeedGrader.EG.jsonReady()
      SpeedGrader.setup()

      $(allSectionsSelectPath).click()

      const [, params] = $.post.firstCall.args
      deepEqual(params, {selected_section_id: 'all'})
    })

    QUnit.module('when a course loads with an empty section selected', emptySectionHooks => {
      emptySectionHooks.beforeEach(() => {
        userSettings.contextGet.returns('4')
        sandbox.stub(SpeedGrader.EG, 'changeToSection')
        sandbox.stub(window, 'alert')
      })

      emptySectionHooks.afterEach(() => {
        window.alert.restore()
        SpeedGrader.EG.changeToSection.restore()
      })

      test('displays an alert indicating the section has no students', () => {
        SpeedGrader.EG.jsonReady()
        SpeedGrader.setup()

        const [message] = window.alert.firstCall.args
        strictEqual(message, "Could not find any students in that section, falling back to showing all sections.")
      })

      test('calls changeToSection with the value "all"', () => {
        SpeedGrader.EG.jsonReady()
        SpeedGrader.setup()

        const [sectionId] = SpeedGrader.EG.changeToSection.firstCall.args
        strictEqual(sectionId, 'all')
      })
    })
  })

  QUnit.module('a moderated assignment with a rubric', hooks => {
    let originalJsonData
    let moderatorProvisionalGrade
    let provisionalGraderProvisionalGrade
    let otherGraderProvisionalGrade
    let submission
    let student
    let testJsonData

    hooks.beforeEach(() => {
      fakeENV.setup({
        ...ENV,
        anonymous_identities: {
          'aaaaa': { id: 'aaaaa', name: 'Grader 1' },
          'bbbbb': { id: 'bbbbb', name: 'Grader 2' },
          'zzzzz': { id: 'zzzzz', name: 'Grader 3' }
        },
        current_anonymous_id: 'zzzzz',
        current_user_id: '1',
        RUBRIC_ASSESSMENT: {
          assessment_type: 'grading',
          assessor_id: '1'
        }
      })

      moderatorProvisionalGrade = {
        provisional_grade_id: '1',
        scorer_id: '1',
        scorer_name: 'Urd',
        readonly: true,
        rubric_assessments: [
          {
            id: '1',
            assessor_id: '1',
            assessor_name: 'Urd',
            data: [{ points: 2, criterion_id: '9' }]
          }
        ]
      }

      provisionalGraderProvisionalGrade = {
        provisional_grade_id: '3',
        scorer_id: '3',
        scorer_name: 'Verdandi',
        readonly: true,
        rubric_assessments: [
          {
            id: '3',
            assessor_id: '3',
            assessor_name: 'Verdandi',
            data: [{ points: 4, criterion_id: '9' }]
          }
        ]
      }

      otherGraderProvisionalGrade = {
        provisional_grade_id: '2',
        scorer_id: '2',
        scorer_name: 'Skuld',
        readonly: true,
        rubric_assessments: [
          {
            id: '2',
            assessor_id: '2',
            assessor_name: 'Skuld',
            data: [{ points: 4, criterion_id: '9' }]
          }
        ]
      }

      submission = {
        user_id: '10',
        provisional_grades: [moderatorProvisionalGrade, otherGraderProvisionalGrade, provisionalGraderProvisionalGrade]
      }

      student = {
        id: '10',
        name: 'Sextus Student',
        rubric_assessments: []
      }

      testJsonData = {
        moderated_grading: true,
        context: {
          students: [student],
          enrollments: [{user_id: '10', workflow_state: 'active', course_setion_id: 1}],
          active_course_sections: [{ id: 1, name: 'The Only Section' }],
        },
        submissions: [submission],
        rubric_association: {},
        anonymous_grader_ids: ['zzzzz', 'bbbbb', 'aaaaa']
      }

      originalJsonData = window.jsonData

      setupFixtures(`
        <div id="rubric_summary_holder">
          <div id="rubric_assessments_list_and_edit_button_holder">
            <span id="rubric_assessments_list">
              <select id="rubric_assessments_select"></select>
            </span>
          </div>
          <div id="rubric_summary_container">
            <div class="button-container">
              <div class="edit"></div>
            </div>
          </div>
        </div>
        <select id="rubric_assessments_select">
        </select>
        <div id="rubric_summary_container">
        </div>
      `)

      const getFromCache = sinon.stub(JQuerySelectorCache.prototype, 'get');
      getFromCache.withArgs('#rubric_full').returns($('#rubric_full'));
      getFromCache.withArgs('#rubric_assessments_select').returns($('#rubric_assessments_select'));

      sandbox.stub(SpeedGrader.EG, 'handleFragmentChanged')
    })

    hooks.afterEach(() => {
      SpeedGrader.EG.handleFragmentChanged.restore()
      JQuerySelectorCache.prototype.get.restore();

      window.jsonData = originalJsonData
      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    QUnit.module('when the viewer is a provisional grader', graderHooks => {
      const finishSetup = () => {
        SpeedGrader.setup()
        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = student
        SpeedGrader.EG.showRubric()
      }

      graderHooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          current_anonymous_id: 'bbbbb',
          current_user_id: '3',
          grading_role: 'provisional_grader'
        })
      })

      test('shows a button to edit the assessment', () => {
        finishSetup()
        ok($('#rubric_assessments_list_and_edit_button_holder .edit').is(':visible'))
      })

      test('hides the dropdown for selecting rubrics', () => {
        finishSetup()
        notOk($('#rubric_assessments_select').is(':visible'))
      })
    })

    QUnit.module('when the viewer is a moderator', graderHooks => {
      const finishSetup = () => {
        SpeedGrader.setup()
        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = testJsonData.context.students[0]
        SpeedGrader.EG.setupProvisionalGraderDisplayNames()
        SpeedGrader.EG.setCurrentStudentRubricAssessments()
        SpeedGrader.EG.showRubric()
      }

      graderHooks.beforeEach(() => {
        fakeENV.setup({
          ...ENV,
          grading_role: 'moderator'
        })
      })

      test('shows all available rubrics in the dropdown', () => {
        finishSetup()
        strictEqual($('#rubric_assessments_select option').length, 3)
      })

      test('includes the moderator-submitted assessment at the top', () => {
        finishSetup()
        strictEqual($('#rubric_assessments_select option').first().val(), '1')
      })

      test('includes a blank assessment if the moderator has not submitted one', () => {
        submission.provisional_grades = [otherGraderProvisionalGrade, provisionalGraderProvisionalGrade]

        finishSetup()
        strictEqual($('#rubric_assessments_select option:first').val(), '')
      })

      test('shows a button to edit if the assessment belonging to the moderator is selected', () => {
        finishSetup()

        $('#rubric_assessments_select').val('1').change()
        ok($('#rubric_assessments_list_and_edit_button_holder .edit').is(':visible'))
      })

      test('does not show a button to edit if a different assessment is selected', () => {
        finishSetup()

        $('#rubric_assessments_select').val('3').change()
        notOk($('#rubric_assessments_list_and_edit_button_holder .edit').is(':visible'))
      })

      test('shows a button to edit', () => {
        finishSetup()

        ok($('#rubric_assessments_list_and_edit_button_holder .edit').is(':visible'))
      })

      test('shows a button to edit if moderated_grading disabled', () => {
        testJsonData.moderated_grading = false
        finishSetup()

        ok($('#rubric_assessments_list_and_edit_button_holder .edit').is(':visible'))
      })

      test('labels the moderator-submitted assessment as "Custom"', () => {
        finishSetup()
        strictEqual($('#rubric_assessments_select option[value="1"]').text(), 'Custom')
      })

      test('appends "Rubric" to the grader name in the dropdown if graders are anonymous', () => {
        testJsonData.anonymize_graders = true
        moderatorProvisionalGrade.anonymous_grader_id = 'zzzzz'
        moderatorProvisionalGrade.rubric_assessments[0].anonymous_assessor_id = 'zzzzz'
        otherGraderProvisionalGrade.anonymous_grader_id = 'aaaaa'
        otherGraderProvisionalGrade.rubric_assessments[0].anonymous_assessor_id = 'aaaaa'
        provisionalGraderProvisionalGrade.anonymous_grader_id = 'bbbbb'
        provisionalGraderProvisionalGrade.rubric_assessments[0].anonymous_assessor_id = 'bbbbb'

        finishSetup()
        strictEqual($('#rubric_assessments_select option[value="3"]').text(), 'Grader 2 Rubric')
      })

      test('does not append "Rubric" to the grader name in the dropdown if grader names are shown', () => {
        finishSetup()
        strictEqual($('#rubric_assessments_select option[value="3"]').text(), 'Verdandi')
      })

      test('defaults to the assessment by the moderator if there is one', () => {
        finishSetup()
        strictEqual($('#rubric_assessments_select').val(), '1')
      })

      test('defaults to the first assessment of type "grading" if the moderator does not have one', () => {
        submission.provisional_grades = [otherGraderProvisionalGrade, provisionalGraderProvisionalGrade]
        provisionalGraderProvisionalGrade.rubric_assessments[0].assessment_type = 'grading'

        finishSetup()
        strictEqual($('#rubric_assessments_select').val(), '3')
      })
    })
  })

  QUnit.module('originality reports', originalityHooks => {
    const turnitinData = {
      submission_1: {
        similarity_score: '60'
      }
    }
    const vericiteData = {
      provider: 'vericite',
      submission_1: {
        similarity_score: '99'
      }
    }
    const student = {id: '1', name: 'Original and Insightful Scholar'}
    let submission

    const gradeSimilaritySelector = '#grade_container .turnitin_score_container .turnitin_similarity_score'
    let testJsonData

    originalityHooks.beforeEach(() => {
      // Both Turnitin and VeriCite use elements with "turnitin" as the class
      setupFixtures(`
        <div id='grade_container'>
          <span class='turnitin_score_container'></span>
          <span class='turnitin_info_container'></span>
        </div>
        <div id='submission_files_container'>
          <span class='turnitin_info_container'></span>
        </div>
        <a id='assignment_submission_originality_report_url' href='#'></a>
        <a id='assignment_submission_turnitin_report_url' href='#{{ user_id }}/{{ asset_string }}'></a>
        <a id='assignment_submission_vericite_report_url' href='#'></a>
      `)

      fakeENV.setup({
        current_user_id: '1',
        assignment_id: '17',
        course_id: '29',
        grading_role: 'moderator',
        help_url: 'example.com/support',
        show_help_menu_item: false
      })

      submission = {
        anonymous_id: 'abcde',
        grading_period_id: 8,
        id: '1',
        user_id: '1',
        submission_type: 'online_text_entry',
        submission_history: [{
          anonymous_id: 'abcde',
          grading_period_id: 8,
          id: '1',
          user_id: '1',
          submission_type: 'online_text_entry',
        }]
      }
      testJsonData = {
        context: {
          active_course_sections: [],
          enrollments: [{user_id: '1', course_section_id: '1'}],
          students: [student]
        },
        gradingPeriods: [],
        submissions: [submission]
      }

      sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
      sinon.stub(SpeedGrader.EG, 'loadSubmissionPreview')

      SpeedGrader.setup()
    })

    originalityHooks.afterEach(() => {
      SpeedGrader.EG.loadSubmissionPreview.restore()
      SpeedGrader.EG.handleFragmentChanged.restore()

      fakeENV.teardown()
      SpeedGrader.teardown()
      window.location.hash = ''
      teardownFixtures()
    })

    QUnit.module('when anonymous grading is inactive', () => {
      test('links to a detailed report for Turnitin submissions', () => {
        submission.submission_history[0].turnitin_data = turnitinData
        submission.submission_history[0].has_originality_score = true

        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = {
          ...student,
          submission
        }
        SpeedGrader.EG.handleSubmissionSelectionChange()

        strictEqual(document.querySelector(gradeSimilaritySelector).tagName, 'A')
      })

      test('includes the user ID and asset ID in the link for Turnitin submissions', () => {
        submission.submission_history[0].turnitin_data = turnitinData
        submission.submission_history[0].has_originality_score = true

        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = {
          ...student,
          submission
        }
        SpeedGrader.EG.handleSubmissionSelectionChange()

        ok(document.querySelector(gradeSimilaritySelector).href.includes('#1/submission_1'))
      })

      test('links to a detailed report for VeriCite submissions', () => {
        submission.submission_history[0].turnitin_data = vericiteData
        submission.submission_history[0].has_originality_score = true

        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = {
          ...student,
          submission
        }
        SpeedGrader.EG.handleSubmissionSelectionChange()

        strictEqual(document.querySelector(gradeSimilaritySelector).tagName, 'A')
      })
    })

    QUnit.module('when anonymous grading is active', hooks => {
      hooks.beforeEach(() => {
        const reportURL = document.querySelector('#assignment_submission_turnitin_report_url')
        reportURL.href = reportURL.href.replace('user_id', 'anonymous_id')

        testJsonData.anonymize_students = true
      })

      test('links to a report for Turnitin submissions', () => {
        submission.submission_history[0].turnitin_data = turnitinData
        submission.submission_history[0].has_originality_score = true

        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = {
          ...student,
          submission
        }
        SpeedGrader.EG.handleSubmissionSelectionChange()

        strictEqual(document.querySelector(gradeSimilaritySelector).tagName, 'A')
      })

      test('includes the anonymous submission ID and asset ID in the link for Turnitin submissions', () => {
        submission.submission_history[0].turnitin_data = turnitinData
        submission.submission_history[0].has_originality_score = true

        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = {
          ...student,
          submission
        }
        SpeedGrader.EG.handleSubmissionSelectionChange()

        const destinationURL = new URL(document.querySelector(gradeSimilaritySelector).href)
        strictEqual(destinationURL.hash, '#abcde/submission_1')
      })

      test('does not link to a report for VeriCite submissions', () => {
        submission.submission_history[0].turnitin_data = vericiteData
        submission.submission_history[0].has_originality_score = true

        window.jsonData = testJsonData
        SpeedGrader.EG.jsonReady()
        SpeedGrader.EG.currentStudent = {
          ...student,
          submission
        }
        SpeedGrader.EG.handleSubmissionSelectionChange()

        strictEqual(document.querySelector(gradeSimilaritySelector).tagName, 'SPAN')
      })
    })

    test('does not show an originality score if originality data is not present', () => {
      window.jsonData = testJsonData
      SpeedGrader.EG.jsonReady()
      SpeedGrader.EG.currentStudent = {
        ...student,
        submission
      }
      SpeedGrader.EG.handleSubmissionSelectionChange()

      strictEqual(document.querySelector(gradeSimilaritySelector), null)
    })
  })
})
