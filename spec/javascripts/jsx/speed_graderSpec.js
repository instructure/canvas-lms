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
import natcompare from 'compiled/util/natcompare';
import fakeENV from 'helpers/fakeENV';
import JQuerySelectorCache from 'jsx/shared/helpers/JQuerySelectorCache';
import numberHelper from 'jsx/shared/helpers/numberHelper';
import SpeedGrader, {teardownHandleFragmentChanged} from 'speed_grader';
import SpeedgraderHelpers from 'speed_grader_helpers';
import userSettings from 'compiled/userSettings';
import 'jquery.ajaxJSON';
import ReactDOM from 'react-dom';

const fixtures = document.getElementById('fixtures')
const setupCurrentStudent = () => SpeedGrader.EG.handleStudentChanged()

let $div

QUnit.module('SpeedGrader#showDiscussion', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
    this.stub($, 'ajaxJSON');
    this.spy($.fn, 'append');
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
          author_name: 'neil@instructure.com',
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
    fixtures.innerHTML = ''
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
  sinon.assert.calledTwice($.fn.append);
});

test('showDiscussion should show private comments for non group assignments', () => {
  window.jsonData.GROUP_GRADING_MODE = false;
  SpeedGrader.EG.currentStudent.submission.submission_comments[0].group_comment_id = null;
  SpeedGrader.EG.showDiscussion();
  sinon.assert.calledTwice($.fn.append);
});

QUnit.module('SpeedGrader#refreshSubmissionToView', {
  setup () {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false
    })
    fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
    this.stub($, 'ajaxJSON');
    this.spy($.fn, 'append');
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
        submission_history: [
          {
            submission_type: 'basic_lti_launch',
            external_tool_url: 'foo'
          },
          {
            submission_type: 'basic_lti_launch',
            external_tool_url: 'bar'
          }
        ]
      }
    };
    sinon.stub($, 'getJSON')
    sinon.stub(SpeedGrader.EG, 'domReady')
    SpeedGrader.setup()
  },

  teardown () {
    SpeedGrader.EG.domReady.restore()
    $.getJSON.restore()
    window.jsonData = this.originalWindowJSONData;
    SpeedGrader.EG.currentStudent = this.originalStudent;
    fixtures.innerHTML = ''
    fakeENV.teardown();
  }
})

test('can handle non-nested submission history', () => {
  SpeedGrader.EG.refreshSubmissionsToView();
  ok(true, 'should not throw an exception');
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
    fixtures.innerHTML = `
      <span id="speedgrader-settings"></span>
      <div id="submission_details">Submission Details</div>
    `
    sinon.stub($, 'getJSON')
    sinon.stub($, 'ajaxJSON')
    sinon.stub(SpeedGrader.EG, 'domReady')
    SpeedGrader.setup()
  })

  hooks.afterEach(function() {
    SpeedGrader.EG.domReady.restore()
    $.ajaxJSON.restore()
    $.getJSON.restore()
    fixtures.innerHTML = ''
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
    this.spy($.fn, 'append');
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
      GROUP_GRADING_MODE: false
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
          author_name: 'neil@instructure.com',
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
              last_lock_at: null,
              last_unlock_at: null,
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
          author_name: 'neil@instructure.com',
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

QUnit.module('SpeedGrader#showGrade', {
  setup () {
    fakeENV.setup();
    this.stub($, 'ajaxJSON');
    this.spy($.fn, 'append');
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
  this.stub(SpeedGrader.EG, 'updateStatsInHeader');
  const $grade = this.stub($.fn, 'val');
  SpeedGrader.EG.showGrade();
  ok($grade.calledWith('complete'));
});

test('uses submission#entered_grade for other types of assignments', function () {
  this.stub(SpeedGrader.EG, 'updateStatsInHeader');
  const $grade = this.stub($.fn, 'val');
  SpeedGrader.EG.currentStudent.submission.grade = 'B';
  SpeedGrader.EG.showGrade();
  ok($grade.calledWith('A'));
});

test('Does not error out if a user has no submission', function () {
  this.stub(SpeedGrader.EG, 'updateStatsInHeader');

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
    this.stub($, 'ajaxJSON');
    this.spy($.fn, 'append');
    this.originalWindowJSONData = window.jsonData;
    fixtures.innerHTML = `
      <span id="speedgrader-settings"></span>
      <div id="multiple_submissions"></div>
      <a class="update_submission_grade_url" href="my_url.com" title="POST"></a>
    `
    SpeedGrader.setup()
    window.jsonData = {
      gradingPeriods: {},
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
      anonymous_grading: false,
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
          author_name: 'neil@instructure.com',
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

    sinon.stub(SpeedgraderHelpers, 'reloadPage');

  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    fixtures.innerHTML = ''
    window.jsonData = this.originalWindowJSONData;
    fakeENV.teardown();
    SpeedgraderHelpers.reloadPage.restore();
  }
});

test('hasWarning and flashWarning are called', function () {
  sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
  SpeedGrader.EG.jsonReady()
  const flashWarningStub = this.stub($, 'flashWarning');
  this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('15');
  this.stub(SpeedGrader.EG, 'setOrUpdateSubmission');
  this.stub(SpeedGrader.EG, 'refreshSubmissionsToView');
  this.stub(SpeedGrader.EG, 'updateSelectMenuStatus');
  this.stub(SpeedGrader.EG, 'showGrade');
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
  this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('56');
  SpeedGrader.EG.handleGradeSubmit(null, false);
  equal($.ajaxJSON.getCall(2).args[0], 'my_url.com');
  equal($.ajaxJSON.getCall(2).args[1], 'POST');
  const [,, formData] = $.ajaxJSON.getCall(2).args;
  equal(formData['submission[score]'], undefined);
  equal(formData['submission[grade]'], '56');
  equal(formData['submission[user_id]'], 4);
  SpeedgraderHelpers.determineGradeToSubmit.restore();
  SpeedGrader.EG.handleFragmentChanged.restore()
});

test('unexcuses the submission if the grade is blank and the assignment is complete/incomplete', function () {
  sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
  SpeedGrader.EG.jsonReady()
  this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('');
  window.jsonData.grading_type = 'pass_fail';
  SpeedGrader.EG.currentStudent.submission.excused = true;
  SpeedGrader.EG.handleGradeSubmit(null, false);
  const [,, formData] = $.ajaxJSON.getCall(2).args;
  strictEqual(formData['submission[excuse]'], false);
  SpeedgraderHelpers.determineGradeToSubmit.restore();
  SpeedGrader.EG.handleFragmentChanged.restore()
});

QUnit.module('attachmentIframeContents', {
  setup () {
    fakeENV.setup();
    this.originalStudent = SpeedGrader.EG.currentStudent;
    SpeedGrader.EG.currentStudent = { id: 4, submission: { user_id: 4 } };
  },

  teardown () {
    fakeENV.teardown();
    SpeedGrader.EG.currentStudent = this.originalStudent;
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
    this.stub($, 'ajaxJSON');
    $div = $("<div id='iframe_holder'>not empty</div>")
    fixtures.innerHTML = $div

  },

  teardown() {
    fakeENV.teardown();
    fixtures.innerHTML = ''
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
    fixtures.innerHTML = `
      <span id="speedgrader-settings"></span>
      <div id="iframe_holder">not empty</div>
    `
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
    fixtures.innerHTML = ''
  }
});

test('contains iframe with the escaped student submission url', () => {
  const retrieveUrl = 'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22';
  const url = 'www.example.com/lti/launch/user/4'
  SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, url)
  const srcUrl = $div.find('iframe').attr('src')
  ok(srcUrl.indexOf(retrieveUrl) > -1)
  ok(srcUrl.indexOf(encodeURIComponent(url)) > -1)
});

test('can be fullscreened', () => {
  const retrieveUrl = 'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22';
  const url = 'www.example.com/lti/launch/user/4';
  SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, url);
  const fullscreenAttr = $div.find('iframe').attr('allowfullscreen');
  equal(fullscreenAttr, "true");
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
  this.stub(userSettings, 'get').returns(true);
  const result = SpeedGrader.EG.getStudentNameAndGrade();
  equal(result, 'Student 1 - not graded');
});

test("returns name and status for non-current student", () => {
  const student = window.jsonData.studentsWithSubmissions[1];
  const result = SpeedGrader.EG.getStudentNameAndGrade(student);
  equal(result, 'Sil E. Bus - graded');
});

test("hides non-current student name if shouldHideStudentNames is true", function () {
  this.stub(userSettings, 'get').returns(true);
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
  let assignment
  let submission
  let params

  hooks.beforeEach(() => {
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
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
    fixtures.innerHTML =`
      <span id="speedgrader-settings"></span>
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
      `
    sinon.stub($, 'ajaxJSON');
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
              external_tool_url: 'bar'
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
  })

  hooks.afterEach(() => {
    getFromCache.restore()
    window.jsonData = originalWindowJSONData
    SpeedGrader.EG.currentStudent = originalStudent
    $.ajaxJSON.restore()
    SpeedGrader.EG.handleFragmentChanged.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('should use submission history lti launch url', () => {
    const renderLtiLaunch = sinon.stub(SpeedGrader.EG, 'renderLtiLaunch')
    SpeedGrader.EG.handleSubmissionSelectionChange()
    ok(renderLtiLaunch.calledWith(sinon.match.any, sinon.match.any, "bar"))
  })

  test('shows a "closed grading period" notice if the submission is in a closed period', () => {
    SpeedGrader.EG.handleSubmissionSelectionChange()
    ok(closedGradingPeriodNotice.showIf.calledWithExactly(true))
  })

  test('does not show a "closed grading period" notice if the submission is not in a closed period', () => {
    SpeedGrader.EG.currentStudent.submission.grading_period_id = null
    SpeedGrader.EG.handleSubmissionSelectionChange()
    notOk(closedGradingPeriodNotice.showIf.calledWithExactly(true))
  })

  QUnit.skip('disables the complete/incomplete select when grading period is closed', () => {
    // the select box is not powered by isClosedForSubmission, it's powered by isConcluded
    SpeedGrader.EG.currentStudent.submission.grading_period_id = 8
    SpeedGrader.EG.handleSubmissionSelectionChange()
    const select = document.getElementById('grading-box-extended')
    ok(select.hasAttribute('disabled'))
  })

  QUnit.skip('does not disable the complete/incomplete select when grading period is open', () => {
    // the select box is not powered by isClosedForSubmission, it's powered by isConcluded
    SpeedGrader.EG.currentStudent.submission.grading_period_id = 7
    SpeedGrader.EG.handleSubmissionSelectionChange()
    const select = document.getElementById('grading-box-extended')
    notOk(select.hasAttribute('disabled'))
  })

  test('submission files list template is populated with anonymous submission data', () => {
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
    this.stub(numberHelper, 'parse').returns(42);
  },

  teardown () {
    fakeENV.teardown();
  }
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

QUnit.module('Function returned by SpeedGrader#compareStudentsBy', {
  setup () {
    this.spy(natcompare, 'strings');
  }
});

test('returns 1 when the given function returns false for the first student and non-false for the second', () => {
  const studentA = { sortable_name: 'b' };
  const studentB = { sortable_name: 'a' };
  const stub = sinon.stub().returns(false, 'foo');
  const compare = SpeedGrader.EG.compareStudentsBy(stub);
  strictEqual(compare(studentA, studentB), 1);
});

test('returns 1 when the given function returns a greater value for the first student than the second', () => {
  const studentA = { sortable_name: 'b' };
  const studentB = { sortable_name: 'a' };
  const stub = sinon.stub();
  stub.onFirstCall().returns(2);
  stub.onSecondCall().returns(1);
  const compare = SpeedGrader.EG.compareStudentsBy(stub);
  strictEqual(compare(studentA, studentB), 1);
});

test('returns -1 when the given function returns a lesser value for the first student than the second', () => {
  const studentA = { sortable_name: 'b' };
  const studentB = { sortable_name: 'a' };
  const stub = sinon.stub();
  stub.onFirstCall().returns(1);
  stub.onSecondCall().returns(2);
  const compare = SpeedGrader.EG.compareStudentsBy(stub);
  strictEqual(compare(studentA, studentB), -1);
});

test('compares student sortable names when given function returns falsey for both students', () => {
  const studentA = { sortable_name: 'b' };
  const studentB = { sortable_name: 'a' };
  const compare = SpeedGrader.EG.compareStudentsBy(() => false);
  const order = compare(studentA, studentB);
  equal(natcompare.strings.callCount, 1);
  ok(natcompare.strings.calledWith(studentA.sortable_name, studentB.sortable_name));
  equal(order, 1);
});

test('compares student sortable names when given function returns equal values for both students', () => {
  const studentA = { sortable_name: 'b' };
  const studentB = { sortable_name: 'a' };
  let compare = SpeedGrader.EG.compareStudentsBy(() => 42);
  let order = compare(studentA, studentB);
  equal(natcompare.strings.callCount, 1);
  ok(natcompare.strings.calledWith(studentA.sortable_name, studentB.sortable_name));
  equal(order, 1);

  compare = SpeedGrader.EG.compareStudentsBy(() => 'foo');
  order = compare(studentA, studentB);
  equal(natcompare.strings.callCount, 2);
  ok(natcompare.strings.calledWith(studentA.sortable_name, studentB.sortable_name));
  equal(order, 1);
});

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
    fixtures.innerHTML = `
      <span id="speedgrader-settings"></span>
      <div id="speed_grader_timeout_alert"></div>
    `
  },
  teardown () {
    fixtures.innerHTML = ''
    this.server.restore();
    fakeENV.teardown();
  }
});

test('shows an error when the gateway times out', function () {
  this.stub(SpeedGrader.EG, 'domReady');
  ENV.assignment_title = 'Assignment Title';
  SpeedGrader.setup();
  const message = 'Something went wrong. Please try refreshing the page. If the problem persists, there may be too many records on "Assignment Title" to load SpeedGrader.';
  strictEqual($('#speed_grader_timeout_alert').text(), message);
});

QUnit.module('SpeedGrader - clicking save rubric button', function(hooks) {
  let disableWhileLoadingStub;

  hooks.beforeEach(function () {
    sinon.stub($, 'ajaxJSON');
    disableWhileLoadingStub = sinon.stub($.fn, 'disableWhileLoading');
    fakeENV.setup({ RUBRIC_ASSESSMENT: {} });

    const rubricHTML = `
      <button class="save_rubric_button"></button>
      <div id="speedgrader_comment_textarea_mount_point"></div>
    `

    fixtures.innerHTML = rubricHTML
  });

  hooks.afterEach(function() {
    fixtures.innerHTML = ''
    fakeENV.teardown();
    disableWhileLoadingStub.restore();
    $.ajaxJSON.restore();
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
  let disableWhileLoadingStub

  hooks.beforeEach(() => {
    sinon.stub($, 'ajaxJSON');
    disableWhileLoadingStub = sinon.stub($.fn, 'disableWhileLoading');
    fakeENV.setup({
      assignment_id: '27',
      course_id: '3',
      help_url: '',
      show_help_menu_item: false,
      RUBRIC_ASSESSMENT: {},
    });

    sinon.stub(SpeedGrader.EG, 'handleFragmentChanged')
    sinon.stub(window.rubricAssessment, 'assessmentData').returns({ 'rubric_assessment[user_id]': 'abcde' });

    fixtures.innerHTML = `
      <span id="speedgrader-settings"></span>
      <button class="save_rubric_button"></button>
      <div id="speedgrader_comment_textarea_mount_point"></div>
      <div id="speedgrader-settings"></div>
    `
    SpeedGrader.setup()
    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'P. Sextus Rubricius',
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
      anonymous_grading: true,
      submissions: [],
      context: {
        students: [
          {
            id: 4,
            name: 'P. Sextus Rubricius'
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
      studentMap: {
        4: SpeedGrader.EG.currentStudent
      }
    }
    ENV.SUBMISSION = {
      grading_role: 'teacher'
    };
    ENV.RUBRIC_ASSESSMENT = {
      assessment_type: 'grading',
      assessor_id: 1
    };

    SpeedGrader.EG.jsonReady();
  })

  hooks.afterEach(() => {
    window.rubricAssessment.assessmentData.restore();
    SpeedGrader.EG.handleFragmentChanged.restore();

    fixtures.innerHTML = ''
    fakeENV.teardown();
    disableWhileLoadingStub.restore();
    $.ajaxJSON.restore();
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
    fixtures.innerHTML = `
      <span id="speedgrader-settings"></span>
      <div id="speed_grader_timeout_alert"></div>
    `
  },
  teardown () {
    fixtures.innerHTML = ''
    this.server.restore();
    fakeENV.teardown();
  }
});

test('does not show an error when the gateway times out', function () {
  this.stub(SpeedGrader.EG, 'domReady');
  ENV.assignment_title = 'Assignment Title';
  SpeedGrader.setup();
  strictEqual($('#speed_grader_timeout_alert').text(), '');
});

QUnit.module('SpeedGrader', function(suiteHooks) {
  suiteHooks.beforeEach(() => {
    fakeENV.setup({
      assignment_id: '2',
      course_id: '7',
      help_url: 'example.com/foo',
      show_help_menu_item: false
    })
    sinon.stub($, 'getJSON')
    sinon.stub($, 'ajaxJSON')
    fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
  })

  suiteHooks.afterEach(() => {
    $.getJSON.restore()
    $.ajaxJSON.restore()
    fixtures.innerHTML = ''
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
      fixtures.innerHTML = rubricHTML
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
      fixtures.innerHTML = ''
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
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id="speedgrader_comment_textarea_mount_point"/>
      `
    })

    hooks.afterEach(function() {
      fixtures.innerHTML = ''
    })

    test('mounts the comment text area when there is an element to mount it in', function() {
      ENV.can_comment_on_submission = true
      SpeedGrader.setup()

      strictEqual($('#speedgrader_comment_textarea').length, 1)
    })

    test('does not mount the comment text area when there is no element to mount it in', function() {
      ENV.can_comment_on_submission = false
      SpeedGrader.setup()

      strictEqual($('#speedgrader_comment_textarea').length, 0)
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

      fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
    })

    hooks.afterEach(function() {
      fixtures.innerHTML = ''
    })

    test('populates the settings mount point', () => {
      SpeedGrader.setup()
      const mountPoint = document.getElementById('speedgrader-settings')
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

      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id="combo_box_container"></div>
        <div id="iframe_holder"></div>
        `
      SpeedGrader.setup()
      window.jsonData = windowJsonData
      SpeedGrader.EG.jsonReady()
      setupCurrentStudent()
      commentToRender = {...submissionComment}
      commentToRender.draft = true

      commentRenderingOptions = { commentBlank: $(commentBlankHtml), commentAttachmentBlank: $(commentAttachmentBlank) };
    })

    hooks.afterEach(() => {
      fixtures.innerHTML = ''
      delete SpeedGrader.EG.currentStudent
      window.jsonData = jsonData
      teardownHandleFragmentChanged()
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

  QUnit.module('Anonymous Assignments', anonymousHooks => {
    const assignment = {anonymous_grading: true}
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
      submission_comments: [alphaSubmissionComment]
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

    QUnit.module('renderComment', hooks => {
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

        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        fakeENV.teardown()
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
        window.location.hash = ''
      })

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

      commentRenderingOptions = { commentBlank: $(commentBlankHtml), commentAttachmentBlank: $(commentAttachmentBlank) };

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
          fixtures.innerHTML = '<div id="combo_box_container"></div>'
        })

        hooks.afterEach(() => {
          fixtures.innerHTML = ''
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
        fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
        sinon.stub(SpeedGrader.EG, 'handleFragmentChanged');
        sinon.stub(SpeedGrader.EG, 'goToStudent')
        SpeedGrader.setup()
        window.jsonData = windowJsonData // setup() resets jsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(function() {
        fixtures.innerHTML = ''
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
        fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
        sinon.stub(SpeedGrader.EG, 'goToStudent')
        sinon.stub(SpeedGrader.EG, 'handleFragmentChanged');
        SpeedGrader.setup()
        window.jsonData = windowJsonData // setup() resets jsonData
        SpeedGrader.EG.jsonReady()
        document.location.hash = `#${encodeURIComponent(JSON.stringify(omegaStudent))}`
        SpeedGrader.EG.handleFragmentChanged.restore()
      })

      hooks.afterEach(function() {
        fixtures.innerHTML = ''
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
        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <img id="avatar_image" alt="" />
          <div id="combo_box_container"></div>
        `
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
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
        fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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
        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
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
        `;
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
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
        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <div id="rubric_holder">
            <div class="rubric"></div>
            <div class='update_rubric_assessment_url' href=${rubricUrl}></div>
            <button class='save_rubric_button'></button>
          </div>
        `;
        sinon.stub(SpeedGrader.EG, 'showSubmission');
        sinon.stub($.fn, 'ready');
        SpeedGrader.setup();
        window.jsonData = windowJsonData;
        SpeedGrader.EG.jsonReady();
        $.fn.ready.restore();
      });

      hooks.afterEach(() => {
        window.jsonData = originalJsonData;
        SpeedGrader.EG.showSubmission.restore();
        fixtures.innerHTML = '';
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
        fixtures.innerHTML = '<span id="speedgrader-settings"></span>';
        sinon.stub($.fn, 'ready');
        SpeedGrader.setup();
        window.jsonData = windowJsonData;
        SpeedGrader.EG.jsonReady();
        $.fn.ready.restore();
      });

      hooks.afterEach(() => {
        window.jsonData = originalJsonData;
        fixtures.innerHTML = '';
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
        fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
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
        fixtures.innerHTML = '<span id="speedgrader-settings"></span>'
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
        window.location.hash = ''
      })

      test('assessment_user_id is set via anonymous id', () => {
        SpeedGrader.EG.showRubric()
        strictEqual(ENV.RUBRIC_ASSESSMENT.assessment_user_id, alphaStudent.anonymous_id)
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
        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <div id="comment_attachment_blank"><a id="submitter_id" href="{{submitter_id}}" /></a></div>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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
        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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
        fixtures.innerHTML = `
          <a id="assignment_url" href=${assignmentURL}>Assignment 1<a>
          <span id="speedgrader-settings"></span>
          <textarea id="speedgrader_comment_textarea_mount_point">hi hi</textarea>
        `
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
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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
        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <div id="grade_container">
            <input />
          </div>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
        window.location.hash = ''
      })

      test('calls isStudentConcluded with student looked up by anonymous id', () => {
        const isStudentConcluded = sinon.spy(SpeedGrader.EG, 'isStudentConcluded')
        SpeedGrader.EG.handleGradeSubmit({}, false)
        deepEqual(isStudentConcluded.firstCall.args, [alphaStudent.anonymous_id])
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

      test('clears the grade input if an error is encountered', () => {
        $.ajaxJSON.restore()
        sinon.stub($, 'ajaxJSON').callsFake((_url, _method, _form, _success, error) => { error() })
        const handleGradingError = sinon.stub(SpeedGrader.EG, 'handleGradingError')
        const showGrade = sinon.stub(SpeedGrader.EG, 'showGrade')

        SpeedGrader.EG.handleGradeSubmit({}, false)
        strictEqual(showGrade.firstCall.args.length, 0)

        showGrade.restore()
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

        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <div id="combo_box_container"></div>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        window.jsonData.rubric_association = {}
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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

        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <div id="iframe_holder">not empty</div>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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

        fixtures.innerHTML = `
          <span id="speedgrader-settings"></span>
          <div id="submission_file_hidden">
            <a
              class="display_name"
              href="/courses/${course_id}/assignments/${assignment_id}/submissions/{{anonymousId}}?download={{attachmentId}}">
            </a>
          </div>
        `
        SpeedGrader.setup()
        window.jsonData = windowJsonData
        SpeedGrader.EG.jsonReady()
        setupCurrentStudent()
      })

      hooks.afterEach(() => {
        fixtures.innerHTML = ''
        window.jsonData = originalJsonData
        delete SpeedGrader.EG.currentStudent
        teardownHandleFragmentChanged()
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

  QUnit.module('#removeModerationBarAndShowSubmission', function(hooks) {
    hooks.beforeEach(() => {
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id="full_width_container" class="with_moderation_tabs"></div>
        <div id="moderation_bar"></div>
        <form id="add_a_comment" style="display:none;"></form>
      `
      sinon.stub(SpeedGrader.EG, 'domReady')
      sinon.stub(SpeedGrader.EG, 'showSubmission')
      SpeedGrader.setup()
    })

    hooks.afterEach(() => {
      SpeedGrader.EG.showSubmission.restore()
      SpeedGrader.EG.domReady.restore()
      fixtures.innerHTML = ''
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

    test('shows a generic error message if not given a MAX_GRADERS_REACHED error code', () => {
      SpeedGrader.EG.handleGradingError({})

      const [errorMessage] = $.flashError.firstCall.args
      strictEqual(errorMessage, 'An error occurred updating this assignment.')
    })
  })

  QUnit.module('#renderProvisionalGradeSelector', function(hooks) {
    const EG = SpeedGrader.EG
    let submission

    hooks.beforeEach(() => {
      ENV.grading_type = 'gpa_scale'
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading_box_selected_grader'></div>
        <input type='text' id='grade' />
      `

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

      fixtures.innerHTML = ''
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
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading_box_selected_grader'></div>
        <input type='text' id='grade' />
      `

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

      fixtures.innerHTML = ''
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
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
          <div class="score"></div>
        </div>
      `

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
      fixtures.innerHTML = ''
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
  })

  QUnit.module('#fetchProvisionalGrades', (hooks) => {
    const EG = SpeedGrader.EG

    hooks.beforeEach(() => {
      ENV.grading_role = 'moderator'

      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `

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
      fixtures.innerHTML = ''
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
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `

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
      sinon.stub(SpeedgraderHelpers, 'submissionState').callsFake(() => 'not_submitted')
    })

    hooks.afterEach(() => {
      SpeedgraderHelpers.submissionState.restore()
      EG.showStudent.restore()

      fixtures.innerHTML = ''
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

      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `

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
      teardownHandleFragmentChanged()
      window.location.hash = ''

      fixtures.innerHTML = ''
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

  QUnit.module('provisional grader display names', (hooks) => {
    const EG = SpeedGrader.EG

    hooks.beforeEach(() => {
      fixtures.innerHTML = `
        <span id="speedgrader-settings"></span>
        <div id='grading_details_mount_point'></div>
        <div id='grading-box-selected-grader'></div>
        <div id='grade_container'>
          <input type='text' id='grading-box-extended' />
        </div>
      `

      SpeedGrader.setup()

      sinon.stub(EG, 'submitSelectedProvisionalGrade')
      sinon.spy(EG, 'setActiveProvisionalGradeFields')
    })

    hooks.afterEach(() => {
      EG.setActiveProvisionalGradeFields.restore()
      EG.submitSelectedProvisionalGrade.restore()
      teardownHandleFragmentChanged()
      window.location.hash = ''

      fixtures.innerHTML = ''
    })

    test('assigns anonymous grader names based on sorted anonymous grader ID', () => {
      EG.currentStudent = {
        anonymous_id: 'abcde',
        submission: {
          provisional_grades: [
            {provisional_grade_id: '1', readonly: true, anonymous_grader_id: 'bbbbb', grade: 11},
            {provisional_grade_id: '2', readonly: true, anonymous_grader_id: 'aaaaa', grade: 22},
          ],
          updated_at: 'never'
        }
      }
      EG.setupProvisionalGraderDisplayNames()

      const selectedGrade = EG.currentStudent.submission.provisional_grades[0]
      EG.handleProvisionalGradeSelected({selectedGrade})

      const {label} = EG.setActiveProvisionalGradeFields.firstCall.args[0]
      strictEqual(label, 'Grader 2')
    })
  })
})
