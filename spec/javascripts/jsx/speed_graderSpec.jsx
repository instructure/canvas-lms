define([
  'jquery',
  'speed_grader',
  'speed_grader_helpers',
  'helpers/fakeENV',
  'jsx/grading/helpers/OutlierScoreHelper',
  'compiled/userSettings',
  'jsx/speed_grader/gradingPeriod',
  'jquery.ajaxJSON'
], ($, SpeedGrader, SpeedgraderHelpers, fakeENV, OutlierScoreHelper, userSettings, MGP) => {
  module('SpeedGrader#showDiscussion', {
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

  let commentRenderingOptions;
  module('SpeedGrader#renderComment', {
    setup () {
      fakeENV.setup();
      this.originalWindowJSONData = window.jsonData;
      window.jsonData = {
        id: 27,
        GROUP_GRADING_MODE: false,
      };
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

  module('SpeedGrader#handleGradeSubmit', {
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
      window.jsonData = this.originalWindowJSONData;
      fakeENV.teardown();
    }
  });

  test('hasWarning and flashWarning are called', function () {
    const flashWarningStub = this.stub($, 'flashWarning');
    this.stub(SpeedgraderHelpers, 'determineGradeToSubmit').returns('15');
    this.stub(SpeedGrader.EG, 'setOrUpdateSubmission');
    this.stub(SpeedGrader.EG, 'refreshSubmissionsToView');
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

  let $div = null;
  module('loading a submission Preview', {
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

  module('resizeImg', {
    setup () {
      fakeENV.setup();
      $div = $("<div id='iframe_holder'><iframe src='about:blank'></iframe></div>");
      $('#fixtures').html($div);
    },

    teardown () {
      fakeENV.teardown();
      $('#fixtures').empty();
    }
  });

  test('resizes images', () => {
    const $body = $('#iframe_holder').find('iframe').contents().find('body');
    $body.html('<img src="#" />');
    SpeedGrader.EG.resizeImg.call($('#iframe_holder').find('iframe').get(0));
    equal($body.find('img').attr('style'), 'max-width: 100vw; max-height: 100vh;');
  });

  test('does not resize other types of content', () => {
    const $body = $('#iframe_holder').find('iframe').contents().find('body');
    $body.html('<p>This is more than an img.</p><img src="#" />');
    SpeedGrader.EG.resizeImg.call($('#iframe_holder').find('iframe').get(0));
    notEqual($body.find('img').attr('style'), 'max-width: 100vw; max-height: 100vh;');
  });

  module('emptyIframeHolder', {
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

  module('renderLtiLaunch', {
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
    let retrieveUrl = 'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
    let url = 'www.example.com/lti/launch/user/4'
    SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, url)
    let srcUrl = $div.find('iframe').attr('src')
    ok(srcUrl.indexOf(retrieveUrl) > -1)
    ok(srcUrl.indexOf(encodeURIComponent(url)) > -1)
  });

  test('can be fullscreened', () => {
    let retrieveUrl = 'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22';
    let url = 'www.example.com/lti/launch/user/4';
    SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, url);
    let fullscreenAttr = $div.find('iframe').attr('allowfullscreen');
    equal(fullscreenAttr, "true");
  })

  module('speed_grader#getGradeToShow');

  test('returns an empty string if submission is null', () => {
    let grade = SpeedGrader.EG.getGradeToShow(null, 'some_role');
    equal(grade, '');
  });

  test('returns an empty string if the submission is undefined', () => {
    let grade = SpeedGrader.EG.getGradeToShow(undefined, 'some_role');
    equal(grade, '');
  });

  test('returns an empty string if a submission has no excused or grade', () => {
    let grade = SpeedGrader.EG.getGradeToShow({}, 'some_role');
    equal(grade, '');
  });

  test('returns excused if excused is true', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ excused: true }, 'some_role');
    equal(grade, 'EX');
  });

  test('returns excused if excused is true and user is moderator', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ excused: true }, 'moderator');
    equal(grade, 'EX');
  });

  test('returns excused if excused is true and user is provisional grader', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ excused: true }, 'provisional_grader');
    equal(grade, 'EX');
  });

  test('returns grade if submission has no excused and grade is not a float', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ grade: 'some_grade' }, 'some_role');
    equal(grade, 'some_grade');
  });

  test('returns score of submission if user is a moderator', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ grade: 15, score: 25 }, 'moderator');
    equal(grade, '25');
  });

  test('returns score of submission if user is a provisional grader', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ grade: 15, score: 25 }, 'provisional_grader');
    equal(grade, '25');
  });

  test('returns grade of submission if user is neither a moderator or provisional grader', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ grade: 15, score: 25 }, 'some_role');
    equal(grade, '15');
  });

  test('returns grade of submission if user is moderator but score is null', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ grade: 15 }, 'moderator');
    equal(grade, '15');
  });

  test('returns grade of submission if user is provisional grader but score is null', () => {
    let grade = SpeedGrader.EG.getGradeToShow({ grade: 15 }, 'provisional_grader');
    equal(grade, '15');
  });

  module('speed_grader#getStudentNameAndGrade');

  test('returns name and status', () => {
    let result = SpeedGrader.EG.getStudentNameAndGrade();
    equal(result, 'Guy B. Studying - not graded');
  });

  test('hides name if shouldHideStudentNames is true', function() {
    this.stub(userSettings, 'get').returns(true);
    this.stub(SpeedGrader.EG, 'currentIndex').returns(5);
    let result = SpeedGrader.EG.getStudentNameAndGrade();
    equal(result, 'Student 6 - not graded');
  });

  module('handleSubmissionSelectionChange', {
    setup() {
      fakeENV.setup();
      this.originalWindowJSONData = window.jsonData;
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
      fakeENV.teardown();
      window.jsonData = this.originalWindowJSONData;
    }
  });

  test('should use submission history lti launch url', () => {
    let renderLtiLaunch = sinon.stub(SpeedGrader.EG, 'renderLtiLaunch');
    sinon.stub(MGP, 'assignmentClosedForStudent').returns(false);
    SpeedGrader.EG.handleSubmissionSelectionChange();
    ok(renderLtiLaunch.calledWith(sinon.match.any, sinon.match.any, "bar"));
  })
});
