define([
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* fragmentChange */,
  'jquery.templateData' /* getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'compiled/behaviors/quiz_selectmenu'
], function($) {

  var data = $("#submission_details").getTemplateData({textValues: ['version_number', 'user_id']});
  var scoringSnapshot = {
    snapshot: {
      user_id: parseInt(data.user_id, 10) || null,
      version_number: data.version_number,
      last_question_touched: null,
      question_updates: {},
      fudge_points: 0
    },
    getSnapshot: function() {
      return scoringSnapshot.snapshot;
    },
    jumpToQuestion: function(question_id) {
      var top = $("#question_" + question_id).offset().top - 10;
      $("html,body").scrollTo({top: top, left:0});
    },
    externallySet: false,
    setSnapshot: function(data, cancelIfAlreadyExternallySet) {
      if(data) {
        if(cancelIfAlreadyExternallySet && scoringSnapshot.externallySet) { return; }
        scoringSnapshot.externallySet = true;
        scoringSnapshot.snapshot = data;
        for(var idx in data.question_updates) {
          var question = data.question_updates[idx];
          var $question = $("#question_" + idx);
          $question.addClass('modified_but_not_saved');
          $question.find(".user_points :text").val(question.points).end()
            .find(".question_neutral_comment .question_comment_text textarea").val(question.comments);
        }
        if(window.parent && window.parent.INST && window.parent.INST.lastQuestionTouched) {
          scoringSnapshot.jumpToQuestion(window.parent.INST.lastQuestionTouched);
        } else if(scoringSnapshot.snapshot.last_question_touched) {
          scoringSnapshot.jumpToQuestion(scoringSnapshot.snapshot.last_question_touched);
        }
      } else if(cancelIfAlreadyExternallySet) {
        if(window.parent && window.parent.INST && window.parent.INST.lastQuestionTouched) {
          scoringSnapshot.jumpToQuestion(window.parent.INST.lastQuestionTouched);
        }
      }
      if(scoringSnapshot.externallySet || cancelIfAlreadyExternallySet) {
        $("#feel_free_to_toggle_message").show();
      }
      if(window.parent && window.parent.INST && window.parent.INST.refreshQuizSubmissionSnapshot && $.isFunction(window.parent.INST.refreshQuizSubmissionSnapshot)) {
        window.parent.INST.refreshQuizSubmissionSnapshot(scoringSnapshot.snapshot);
      }
    }
  }
  $(document).ready(function() {
    $(":text").focus(function() {
      $(this).select();
    });
    $(document).fragmentChange(function(event, hash) {
      if(hash.indexOf("#question") == 0) {
        var id = hash.substring(10);
        scoringSnapshot.jumpToQuestion(id);
      }
    });
    if(window.parent && window.parent.INST && window.parent.INST.getQuizSubmissionSnapshot && $.isFunction(window.parent.INST.getQuizSubmissionSnapshot)) {
      $("#feel_free_to_toggle_message").show();
      var data = window.parent.INST.getQuizSubmissionSnapshot(scoringSnapshot.snapshot.user_id, scoringSnapshot.snapshot.version_number);
      if(data) {
        scoringSnapshot.setSnapshot(data);
      } else {
        scoringSnapshot.setSnapshot(null, true);
      }
    }
    $(".question_holder .user_points :text,.question_holder .question_neutral_comment .question_comment_text textarea").change(function() {
      var $question = $(this).parents(".display_question");
      var question_id = parseInt($question.attr('id').substring(9), 10) || null;
      if(question_id) {
        var data = {};
        $question.addClass('modified_but_not_saved');
        data.points = parseFloat($question.find(".user_points :text").val(), 10);
        data.comments = $question.find(".question_neutral_comment .question_comment_text textarea").val() || "";
        scoringSnapshot.snapshot.question_updates[question_id] = data;
        scoringSnapshot.snapshot.last_question_touched = question_id;
        scoringSnapshot.setSnapshot();
      }
      $(document).triggerHandler('score_changed');
    });
    $("#fudge_points_entry").change(function() {
      var points = parseFloat($(this).val(), 10);
      if(points || points === 0) {
        scoringSnapshot.snapshot.fudge_points = points;
        scoringSnapshot.setSnapshot();
      }
      $(document).triggerHandler('score_changed');
    });
    $(document).bind('score_changed', function() {
      var $total = $("#after_fudge_points_total");
      var total = 0;
      $(".display_question .user_points:visible").each(function() {
        var points = parseFloat($(this).find(":text:first").val(), 10) || 0;
        points = Math.round(points * 100.0) / 100.0;
        total = total + points;
      });
      var fudge = (parseFloat($("#fudge_points_entry").val(), 10) || 0);
      fudge = Math.round(fudge * 100.0) / 100.0;
      total = total + fudge;
      $total.text(total || "0");
    });
  });

  if (ENV.SCORE_UPDATED) {
    $(document).ready(function() {
      if(window.parent && window.parent.INST && window.parent.INST.refreshGrades && $.isFunction(window.parent.INST.refreshGrades)) {
        window.parent.INST.refreshGrades();
      }
      if(window.parent && window.parent.INST && window.parent.INST.clearQuizSubmissionSnapshot && $.isFunction(window.parent.INST.clearQuizSubmissionSnapshot)) {
        window.parent.INST.clearQuizSubmissionSnapshot(scoringSnapshot.snapshot);
      }
    });
  }
});

