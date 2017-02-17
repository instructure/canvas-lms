define([
  'jquery',
  'submissions',
  'jquery.ajaxJSON'
  ], ($, submissions) => {

  QUnit.module("submissions", {
    setup() {
      sinon.spy($, 'ajaxJSON');
      ENV.SUBMISSION = {
        user_id: 1,
        assignment_id: 27,
        submission: {}
      }
      $("#fixtures").html(
        "<div id='preview_frame'>"                            +
        "  <div id='rubric_holder'>"                          +
        "  </div>"                                            +
        "  <div class='save_rubric_button'>"                  +
        "  </div>"                                            +
        "  <a class='update_submission_url'"                  +
        "   href='my_url.com' title='POST'></a>"              +
        "  <textarea class='grading_value'>A</textarea>"      +
        "  <div class='submission_header'>"                   +
        "  </div>"                                            +
        "  <div class='comments_link'>"                       +
        "  </div>"                                            +
        "  <div class='attach_comment_file_link'>"            +
        "  </div>"                                            +
        "  <div class='delete_comment_attachment_link'>"      +
        "  </div>"                                            +
        "  <div class='comments'>"                            +
        "  </div>"                                            +
        "  <textarea class='grading_comment'>"                +
        "  Hello again.</textarea>"                           +
        "  <div class='save_comment_button'>"                 +
        "  </div>"                                            +
        "</div>"
      );
      submissions.setup();
    },

    teardown() {
      $.ajaxJSON.restore();
      submissions.teardown();
      $("#fixtures").html("");
    }
  });

  test('comment_change posts to update_submission_url', ()=>{
    $(".grading_comment").val('Hello again.');
    $(document).triggerHandler('comment_change');
    equal($.ajaxJSON.getCall(0).args[0], 'my_url.com');
    equal($.ajaxJSON.getCall(0).args[1], 'POST');
  });

  test('comment_change submits the grading_comment but not grade', ()=>{
    $(".grading_comment").val('Hello again.');
    $(".save_comment_button").click();
    equal($.ajaxJSON.getCall(0).args[2]['submission[user_id]'], 1);
    equal($.ajaxJSON.getCall(0).args[2]['submission[assignment_id]'], 27);
    equal($.ajaxJSON.getCall(0).args[2]['submission[comment]'], 'Hello again.');
    equal($.ajaxJSON.getCall(0).args[2]['submission[grade]'], undefined);
  });

  test('comment_change does not submit if no comment', ()=>{
    $(".grading_comment").val('');
    $(".save_comment_button").click();
    ok($.ajaxJSON.notCalled);
  });

  test('grading_change posts to update_submission_url', ()=>{
    $(document).triggerHandler('grading_change');
    equal($.ajaxJSON.getCall(0).args[0], 'my_url.com');
    equal($.ajaxJSON.getCall(0).args[1], 'POST');
  });

  test('grading_change submits the grade but not grading_comment', ()=>{
    $(document).triggerHandler('grading_change');
    equal($.ajaxJSON.getCall(0).args[2]['submission[user_id]'], 1);
    equal($.ajaxJSON.getCall(0).args[2]['submission[assignment_id]'], 27);
    equal($.ajaxJSON.getCall(0).args[2]['submission[grade]'], 'A');
    equal($.ajaxJSON.getCall(0).args[2]['submission[comment]'], undefined);
  });
});
