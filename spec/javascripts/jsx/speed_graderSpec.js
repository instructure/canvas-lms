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
import SpeedGrader from 'speed_grader';
import SpeedgraderHelpers from 'speed_grader_helpers';
import SpeedgraderSelectMenu from 'speed_grader_select_menu';
import fakeENV from 'helpers/fakeENV';
import userSettings from 'compiled/userSettings';
import MGP from 'jsx/speed_grader/gradingPeriod';
import numberHelper from 'jsx/shared/helpers/numberHelper';
import natcompare from 'compiled/util/natcompare';
import 'jquery.ajaxJSON';

QUnit.module('SpeedGrader#showDiscussion', {
  setup () {
    fakeENV.setup();
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

    const gradeContainerHtml = `
      <div id="grade_container">
        <a class="update_submission_grade_url" href="my_url.com" title="POST"></a>
        <input class="grading_value" value="56" />
        <div id="combo_box_container"></div>
        <div id="comments">
        </div>
      </div>
    `;

    $('#fixtures').html(gradeContainerHtml);
  },

  teardown () {
    $('#fixtures').empty();
    SpeedGrader.EG.currentStudent = this.originalStudent;
    window.jsonData = this.originalWindowJSONData;
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
    fakeENV.setup();
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
  },

  teardown () {
    window.jsonData = this.originalWindowJSONData;
    SpeedGrader.EG.currentStudent = this.originalStudent;
    fakeENV.teardown();
  }
})

test('can handle non-nested submission history', () => {
  SpeedGrader.EG.refreshSubmissionsToView();
  ok(true, 'should not throw an exception');
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
      <div class="comment" style="display: none;">
        <div class="comment_flex">
          <img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=" class="avatar" alt="" style="display: none;"/>
          <span class="draft-marker" aria-label="Draft comment">*</span>
          <span class="comment"></span>
          <button class="submit_comment_button">
            <span>Submit</span>
          </button>
          <a href="javascript:void 0;" class="delete_comment_link icon-x">
            <span class="screenreader-only">Delete comment</span>
          </a>
        </div>
        <a href="#" class="play_comment_link media-comment" style="display:none;">click here to view</a>
        <div class="media_comment_content" style="display:none"></div>
        <div class="comment_attachments"></div>
        <div class="comment_citation">
          <span class="author_name">&nbsp;</span>,
          <span class="posted_at">&nbsp;</span>
        </div>
      </div>
    `;

    const commentAttachmentBlank = `
      <div class="comment_attachment" id="comment_attachment_blank" style="display: none;">
        <a href="example.com/{{ submitter_id }}/{{ id }}/{{ comment_id }}"><span class="display_name">&nbsp;</span></a>
      </div>
    `;

    const gradeContainerHtml = `
      <div id="grade_container">
        <a class="update_submission_grade_url" href="my_url.com" title="POST"></a>
        <input class="grading_value" value="56" />
        <div id="combo_box_container"></div>
        <div id="comments">
        </div>
      </div>
    `;

    $('#fixtures').html(gradeContainerHtml);

    commentRenderingOptions = { commentBlank: $(commentBlankHtml), commentAttachmentBlank: $(commentAttachmentBlank) };
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    $('#fixtures').empty();
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

test('renderComment should add the comment text to the submit link for draft comments', () => {
  const commentToRender = SpeedGrader.EG.currentStudent.submission.submission_comments[0];
  commentToRender.draft = true;
  const renderedComment = SpeedGrader.EG.renderComment(commentToRender, commentRenderingOptions);
  const submitLinkScreenreaderText = renderedComment.find('.submit_comment_button').attr('aria-label');

  equal(submitLinkScreenreaderText, 'Submit comment: test');
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

    const gradeContainerHtml = `
      <div id="grade_container">
        <a class="update_submission_grade_url" href="my_url.com" title="POST"></a>
        <input class="grading_value" value="56" />
        <div id="combo_box_container"></div>
        <div id="comments">
        </div>
      </div>
    `;

    $('#fixtures').html(gradeContainerHtml);
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    $('#fixtures').empty();
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

QUnit.module('SpeedGrader#handleGradeSubmit', {
  setup () {
    fakeENV.setup();
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

    const gradeContainerHtml = `
      <div id="grade_container">
        <a class="update_submission_grade_url" href="my_url.com" title="POST"></a>
        <input class="grading_value" value="56" />
        <div id="combo_box_container"></div>
        <div id="comments">
        </div>
      </div>
    `;

    $('#fixtures').html(gradeContainerHtml);
  },

  teardown () {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    $('#fixtures').empty();
    window.jsonData = this.originalWindowJSONData;
    fakeENV.teardown();
  }
});

test('hasWarning and flashWarning are called', function () {
  const flashWarningStub = this.stub($, 'flashWarning');
  this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('15');
  this.stub(SpeedGrader.EG, 'setOrUpdateSubmission');
  this.stub(SpeedGrader.EG, 'refreshSubmissionsToView');
  this.stub(SpeedGrader.EG, 'updateSelectMenuStatus');
  this.stub(SpeedGrader.EG, 'showGrade');
  SpeedGrader.EG.handleGradeSubmit(10, false);
  const callback = $.ajaxJSON.getCall(0).args[3];
  const submissions = [{
    submission: { user_id: 1, score: 15, excused: false }
  }];
  callback(submissions);
  ok(flashWarningStub.calledOnce);
});

test('handleGradeSubmit should submit score if using existing score', () => {
  SpeedGrader.EG.handleGradeSubmit(null, true);
  equal($.ajaxJSON.getCall(0).args[0], 'my_url.com');
  equal($.ajaxJSON.getCall(0).args[1], 'POST');
  const formData = $.ajaxJSON.getCall(0).args[2];
  equal(formData['submission[score]'], '7');
  equal(formData['submission[grade]'], undefined);
  equal(formData['submission[user_id]'], 4);
});

test('handleGradeSubmit should submit grade if not using existing score', function() {
  this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('56');
  SpeedGrader.EG.handleGradeSubmit(null, false);
  equal($.ajaxJSON.getCall(0).args[0], 'my_url.com');
  equal($.ajaxJSON.getCall(0).args[1], 'POST');
  const formData = $.ajaxJSON.getCall(0).args[2];
  equal(formData['submission[score]'], undefined);
  equal(formData['submission[grade]'], '56');
  equal(formData['submission[user_id]'], 4);
  SpeedgraderHelpers.determineGradeToSubmit.restore();
});

test('unexcuses the submission if the grade is blank and the assignment is complete/incomplete', function () {
  this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('');
  window.jsonData.grading_type = 'pass_fail';
  SpeedGrader.EG.currentStudent.submission.excused = true;
  SpeedGrader.EG.handleGradeSubmit(null, false);
  const formData = $.ajaxJSON.getCall(0).args[2];
  strictEqual(formData['submission[excuse]'], false);
  SpeedgraderHelpers.determineGradeToSubmit.restore();
});

let $div = null;
QUnit.module('loading a submission Preview', {
  setup() {
    fakeENV.setup();
    this.stub($, 'ajaxJSON');
    $div = $("<div id='iframe_holder'>not empty</div>")
    $("#fixtures").html($div)
  },

  teardown() {
    fakeENV.teardown();
    $("#fixtures").empty();
  }
});

test('entry point function, loadSubmissionPreview, is a function', () => {
  ok(typeof SpeedGrader.EG.loadSubmissionPreview === 'function');
})

QUnit.module('attachmentIFrameContents', {
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
  const contents = SpeedGrader.EG.attachmentIFrameContents(attachment);
  strictEqual(/^<img/.test(contents.string), true);
});

test('returns an iframe tag if the attachment is not of type "image"', () => {
  const attachment = { id: 1, mime_class: 'text/plain' };
  const contents = SpeedGrader.EG.attachmentIFrameContents(attachment);
  strictEqual(/^<iframe/.test(contents.string), true);
});

QUnit.module('emptyIframeHolder', {
  setup() {
    fakeENV.setup();
    this.stub($, 'ajaxJSON');
    $div = $("<div id='iframe_holder'>not empty</div>")
    $("#fixtures").html($div)
  },

  teardown() {
    fakeENV.teardown();
    $("#fixtures").empty();
  }
});

test('is a function', () => {
  ok(typeof SpeedGrader.EG.emptyIframeHolder === 'function');
});

test('clears the contents of the iframe_holder', () => {
  SpeedGrader.EG.emptyIframeHolder($div);
  ok($div.is(':empty'));
});

QUnit.module('renderLtiLaunch', {
  setup() {
    fakeENV.setup();
    this.stub($, 'ajaxJSON');
    $div = $("<div id='iframe_holder'>not empty</div>")
    $("#fixtures").html($div)
  },

  teardown() {
    fakeENV.teardown();
    $("#fixtures").empty();
  }
});

test('is a function', () => {
  ok(typeof SpeedGrader.EG.renderLtiLaunch === 'function')
})

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

QUnit.module('handleSubmissionSelectionChange', {
  setup() {
    fakeENV.setup();
    this.originalWindowJSONData = window.jsonData;
    this.originalStudent = SpeedGrader.EG.currentStudent;
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
        submission_type: 'basic_lti_launch',
        workflow_state: 'submitted',
        submission_history: [
          {
            submission: {
              submission_type: 'basic_lti_launch',
              external_tool_url: 'foo'
            }
          },
          {
            submission: {
              submission_type: 'basic_lti_launch',
              external_tool_url: 'bar'
            }
          }
        ]
      }
    };

    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
      studentMap : {
        4 : SpeedGrader.EG.currentStudent
      }
    };
  },

  teardown() {
    SpeedGrader.EG.currentStudent = this.originalStudent;
    fakeENV.teardown();
    window.jsonData = this.originalWindowJSONData;
  }
});

test('should use submission history lti launch url', () => {
  const renderLtiLaunch = sinon.stub(SpeedGrader.EG, 'renderLtiLaunch');
  sinon.stub(MGP, 'assignmentClosedForStudent').returns(false);
  SpeedGrader.EG.handleSubmissionSelectionChange();
  ok(renderLtiLaunch.calledWith(sinon.match.any, sinon.match.any, "bar"));
});

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
    fakeENV.setup();
    this.server = sinon.fakeServer.create({ respondImmediately: true });
    this.server.respondWith(
      'GET',
      `${window.location.pathname}.json${window.location.search}`,
      [504, { 'Content-Type': 'application/json' }, '']
    );
    $('#fixtures').html('<div id="speed_grader_timeout_alert"></div>');
  },
  teardown () {
    $('#fixtures').empty();
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

QUnit.module('SpeedGrader - no gateway timeout', {
  setup () {
    fakeENV.setup();
    this.server = sinon.fakeServer.create({ respondImmediately: true });
    this.server.respondWith(
      'GET',
      `${window.location.pathname}.json${window.location.search}`,
      [200, { 'Content-Type': 'application/json' }, '{ hello: "world"}']
    );
    $('#fixtures').html('<div id="speed_grader_timeout_alert"></div>');
  },
  teardown () {
    $('#fixtures').empty();
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

QUnit.module('SpeedGrader#updateSelectMenuStatus', {
  setup () {
    fakeENV.setup();
    this.originalWindowJSONData = window.jsonData;
    window.jsonData = {};

    window.jsonData.studentsWithSubmissions = [
      {
        index: 0,
        id: 4,
        name: 'Guy B. Studying',
        submission_state: 'not_graded',
        submission: {
          score: null,
          grade: null
        }
      },
      {
        index: 1,
        id: 12,
        name: 'Sil E. Bus',
        submission_state: 'graded',
        submission: {
          score: 7,
          grade: 70
        }
      }
    ];

    const menuHtml = `<div id="combo_box_container"></div>`;
    $('#fixtures').html(menuHtml);

    const optionsArray = window.jsonData.studentsWithSubmissions.map((s, _) => {
      const className = SpeedgraderHelpers.classNameBasedOnStudent(s);
      return { id: s.id, name: s.name, className };
    });

    this.selectmenu = new SpeedgraderSelectMenu(optionsArray);
    this.selectmenu.appendTo("#combo_box_container", function () {});
  },

  teardown () {
    $('#fixtures').empty();
    window.jsonData = this.originalWindowJSONData;
    fakeENV.teardown();
  }
});

test('ignores null students', function () {
  SpeedGrader.EG.updateSelectMenuStatus(null, this.selectmenu);
  ok(true, 'does not error');
});

test('updates to graded', function () {
  const student = window.jsonData.studentsWithSubmissions[0];
  student.submission_state = 'graded';
  SpeedGrader.EG.updateSelectMenuStatus(student, this.selectmenu);

  const entry = this.selectmenu.jquerySelectMenu().data('selectmenu').list.find('li:eq(0)').children();
  strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check').length, 1);
  strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1)

  const option = $(this.selectmenu.option_tag_array[0]);
  strictEqual(option.hasClass("not_graded"), false);
  equal(option.text(), "Guy B. Studying - graded");
  strictEqual(option.hasClass("graded"), true);
});

test('updates to not_graded', function () {
  const student = window.jsonData.studentsWithSubmissions[1];
  student.submission_state = 'not_graded';
  SpeedGrader.EG.updateSelectMenuStatus(student, this.selectmenu);

  const entry = this.selectmenu.jquerySelectMenu().data('selectmenu').list.find('li:eq(1)').children();
  strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")').length, 1);
  strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Sil E. Bus")').length, 1)

  const option = $(this.selectmenu.option_tag_array[1]);
  strictEqual(option.hasClass("graded"), false);
  equal(option.text(), "Sil E. Bus - not graded");
  strictEqual(option.hasClass("not_graded"), true);
});

// We really never go to not_submitted, but a background update
// *could* potentially do this, so we should handle it.
test('updates to not_submitted', function () {
  const student = window.jsonData.studentsWithSubmissions[0];
  student.submission_state = 'not_submitted';
  SpeedGrader.EG.updateSelectMenuStatus(student, this.selectmenu);

  const entry = this.selectmenu.jquerySelectMenu().data('selectmenu').list.find('li:eq(0)').children();
  strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon').length, 1);
  strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1)

  const option = $(this.selectmenu.option_tag_array[0]);
  strictEqual(option.hasClass("graded"), false);
  equal(option.text(), "Guy B. Studying - not submitted");
  strictEqual(option.hasClass("not_submitted"), true);
});

// We really never go to resubmitted, but a backgroud update *could*
// potentially do this, so we should handle it.
test('updates to resubmitted', function () {
  const student = window.jsonData.studentsWithSubmissions[1];
  student.submission_state = 'resubmitted';
  student.submission.submitted_at = '2017-07-10T17:00:00Z';
  SpeedGrader.EG.updateSelectMenuStatus(student, this.selectmenu);

  const entry = this.selectmenu.jquerySelectMenu().data('selectmenu').list.find('li:eq(0)').children();
  strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")').length, 1);
  strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1)

  const option = $(this.selectmenu.option_tag_array[1]);
  strictEqual(option.hasClass("not_graded"), false);
  equal(option.text(), "Sil E. Bus - graded, then resubmitted (Jul 10 at 5pm)");
  strictEqual(option.hasClass("resubmitted"), true);
});

// We really never go to not_gradable, but a backgroud update *could*
// potentially do this, so we should handle it.
test('updates to not_gradable', function () {
  const student = window.jsonData.studentsWithSubmissions[0];
  student.submission_state = 'not_gradeable';
  student.submission.submitted_at = '2017-07-10T17:00:00Z';
  SpeedGrader.EG.updateSelectMenuStatus(student, this.selectmenu);

  const entry = this.selectmenu.jquerySelectMenu().data('selectmenu').list.find('li:eq(0)').children();
  strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon > i.icon-check').length, 1);
  strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1)

  const option = $(this.selectmenu.option_tag_array[1]);
  strictEqual(option.hasClass("not_graded"), false);
  equal(option.text().trim(), "Sil E. Bus - graded");
  strictEqual(option.hasClass("graded"), true);
});
