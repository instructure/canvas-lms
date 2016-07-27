/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'compiled/util/round',
  'i18n!submissions',
  'jquery',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* ajaxJSONFiles */,
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jquery.instructure_misc_plugins' /* fragmentChange, showIf */,
  'jquery.loadingImg' /* loadingImg, loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'media_comments' /* mediaComment */,
  'compiled/jquery/mediaCommentThumbnail',
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(round, I18n, $) {

  $("#content").addClass('padless');
  var fileIndex = 1;
  var submissionLoaded = function(data) {
    if(data.submission) {
      var d = [];
      d.push(data);
      data = d;
    }
    for(var jdx in data) {
      var submission = data[jdx].submission;
      var comments = submission.visible_submission_comments || submission.submission_comments;
      if(submission.user_id != ENV.SUBMISSION.user_id) { continue; }

      for(var idx in comments) {
        var comment = comments[idx].submission_comment;
        if($("#submission_comment_" + comment.id).length > 0) { continue; }
        var $comment = $("#comment_blank").clone(true).removeAttr('id');
        comment.posted_at = $.datetimeString(comment.created_at);
        $comment.fillTemplateData({
          data: comment,
          id: 'submission_comment_' + comment.id
        });
        if(comment.media_comment_id) {
          $media_comment_link = $("#comment_media_blank").clone(true).removeAttr('id');
          $media_comment_link.fillTemplateData({
            data: comment
          });
          $comment.find(".comment").empty().append($media_comment_link.show());
        } else {
          for(var jdx in comment.attachments) {
            var attachment = comment.attachments[jdx].attachment;
            var $attachment = $("#comment_attachment_blank").clone(true).removeAttr('id');
            attachment.comment_id = comment.id;
            $attachment.fillTemplateData({
              data: attachment,
              hrefValues: ['comment_id', 'id']
            });
            $comment.find(".comment_attachments").append($attachment.show());
          }
        }
        $(".comments .comment_list").append($comment.show()).scrollTop(10000);
        if ($(".grading_comment").val() === comment.comment) {
          $(".grading_comment").val("");
        }
      }
      $(".comments .comment_list .play_comment_link").mediaCommentThumbnail('small');
      $(".save_comment_button").attr('disabled',null);
      if(submission) {
        showGrade(submission);
        $(".submission_details").fillTemplateData({
          data: submission
        });
        $("#add_comment_form .comment_attachments").empty();
      }
    }
    $(".submission_header").loadingImage('remove');
  }
  var showGrade = function(submission) {
    $(".grading_box").val(submission.grade != undefined && submission.grade !== null ? submission.grade : "");
    $(".score").text(submission.score != undefined && submission.score !== null ? round(submission.score, round.DEFAULT) : "");
    $(".published_score").text(submission.published_score != undefined && submission.published_score !== null ? round(submission.published_score, round.DEFAULT) : "");
  }
  var makeRubricAccessible = function($rubric) {
    $rubric.show()
    var $tabs = $rubric.find(":tabbable")
    var tabBounds = [$tabs.first()[0], $tabs.last()[0]]
    var keyCodes = {
      9: "tab",
      13: "enter",
      27: "esc"
    }
    $(".hide_rubric_link").keydown(function(e) {
      if (keyCodes[e.which] == "enter") {
        e.preventDefault();
        $(this).click();
      };
    });
    $tabs.each(function(){
      $(this).bind('keydown', function(e){
        if(keyCodes[e.which] == "esc")
          $(".hide_rubric_link").click()
      });
    });
    $(tabBounds).each(function(e){
      $(this).bind('keydown', function(e){
        if (keyCodes[e.which] == "tab"){
          var isLeavingHolder = $(this).is($(tabBounds).first()) ? e.shiftKey : !e.shiftKey;
          if(isLeavingHolder) {
            e.preventDefault();
            var thisEl = this
            var target = $.grep(tabBounds,function(el){return el != thisEl})
            $(target).focus();
          };
        };
      });
    });
    $rubric.siblings().attr('data-hide_from_rubric', true).end().
      parentsUntil("#application").siblings().not("#aria_alerts").attr('data-hide_from_rubric', true)
    $rubric.hide()
  }
  var closeRubric = function() {
    $("#rubric_holder").fadeOut(function() {
      toggleRubric($(this));
      $(".assess_submission_link").focus();
    });
  }
  var openRubric = function() {
    $("#rubric_holder").fadeIn(function() {
      toggleRubric($(this));
      $(this).find('.hide_rubric_link').focus();
    });
  }
  var toggleRubric = function($rubric) {
    ariaSetting = $rubric.is(":visible");
    $("#application").find("[data-hide_from_rubric]").attr("aria-hidden", ariaSetting)
  }
  var windowResize = function() {
    var $frame = $("#preview_frame");
    var top = $frame.offset().top;
    var height = $(window).height() - top;
    $frame.height(height);
    $("#rubric_holder").css({'maxHeight': height - 50, 'overflow': 'auto', 'zIndex': 5});
    $(".comments").height(height);
  };
  var SubmissionsObj = {};
  // This `setup` function allows us to control when the setup is triggered.
  // submissions.coffee requires this file and then immediately triggers it,
  // while submissionsSpec.jsx triggers it after setup is complete.
  SubmissionsObj.setup = function() {
    $(document).ready(function() {
      $(".comments .comment_list .play_comment_link").mediaCommentThumbnail('small');
      $(window).bind('resize', windowResize).triggerHandler('resize');
      $(".comments_link").click(function(event) {
        event.preventDefault();
        $(".comments").slideToggle(function() {
          $(".comments .media_comment_content").empty();
          $(".comments textarea:visible").focus().select();
        });
      });
      $(".save_comment_button").click(function(event) {
        $(document).triggerHandler('comment_change');
      });
      // post new comment but no grade
      $(document).bind('comment_change', function(event) {
        $(".save_comment_button").attr('disabled','disabled');
        $(".submission_header").loadingImage();
        var url = $(".update_submission_url").attr('href');
        var method = $(".update_submission_url").attr('title');
        var formData = {
          'submission[assignment_id]': ENV.SUBMISSION.assignment_id,
          'submission[user_id]': ENV.SUBMISSION.user_id,
          'submission[group_comment]': ($("#submission_group_comment").attr('checked') ? "1" : "0")
        };
        if($("#media_media_recording:visible").length > 0) {
          var comment_id = $("#media_media_recording").data('comment_id');
          var comment_type = $("#media_media_recording").data('comment_type');
          formData['submission[media_comment_type]'] = comment_type || 'video';
          formData['submission[media_comment_id]'] = comment_id;
        } else {
          if($(".grading_comment").val() && $(".grading_comment").val != "") {
            formData['submission[comment]'] = $(".grading_comment").val();
          }
          if(!formData['submission[comment]'] && $("#add_comment_form input[type='file']").length > 0) {
            formData['submission[comment]'] = I18n.t("see_attached_files", "See attached files");
          }
        }
        if(!formData['submission[comment]'] && !formData['submission[media_comment_id]']) {
          $(".submission_header").loadingImage('remove');
          $(".save_comment_button").attr('disabled',null);
          return;
        }
        if($("#add_comment_form input[type='file']").length > 0) {
          $.ajaxJSONFiles(url + ".text", method, formData, $("#add_comment_form input[type='file']"), submissionLoaded);
        } else {
          $.ajaxJSON(url, method, formData, submissionLoaded);
        }
      });
      $(".cancel_comment_button").click(function(event) {
        $(".grading_comment").val("");
        $(".comments_link").click();
      });
      $(".grading_value").change(function(event) {
        $(document).triggerHandler('grading_change');
      });
      // post new grade but no comments
      $(document).bind('grading_change', function(event) {
        $(".save_comment_button").attr('disabled','disabled');
        $(".submission_header").loadingImage();
        var url = $(".update_submission_url").attr('href');
        var method = $(".update_submission_url").attr('title');
        var formData = {
          'submission[assignment_id]': ENV.SUBMISSION.assignment_id,
          'submission[user_id]': ENV.SUBMISSION.user_id,
          'submission[group_comment]': ($("#submission_group_comment").attr('checked') ? "1" : "0")
        };
        if($(".grading_value:visible").length > 0) {
          formData['submission[grade]'] = $(".grading_value").val();
          $.ajaxJSON(url, method, formData, submissionLoaded);
        } else {
          $(".submission_header").loadingImage('remove');
          $(".save_comment_button").attr('disabled',null);
        }
      });
      $(".attach_comment_file_link").click(function(event) {
        event.preventDefault();
        var $attachment = $("#comment_attachment_input_blank").clone(true).removeAttr('id');
        $attachment.find("input").attr('name', 'attachments[' + (fileIndex++) + '][uploaded_data]');
        $("#add_comment_form .comment_attachments").append($attachment.slideDown());
      });
      $(".delete_comment_attachment_link").click(function(event) {
        event.preventDefault();
        $(this).parents(".comment_attachment_input").slideUp(function() {
          $(this).remove();
        });
      });
      $(".save_rubric_button").click(function() {
        var $rubric = $(this).parents("#rubric_holder").find(".rubric");
        var data = rubricAssessment.assessmentData($rubric);
        var url = $(".update_rubric_assessment_url").attr('href');
        var method = "POST";
        $rubric.loadingImage();
        $.ajaxJSON(url, method, data, function(data) {
          $rubric.loadingImage('remove');
          var assessment = data;
          var found = false;
          if(assessment.rubric_association) {
            rubricAssessment.updateRubricAssociation($rubric, data.rubric_association);
            delete assessment.rubric_association;
          }
          for(var idx in rubricAssessments) {
            var a = rubricAssessments[idx].rubric_assessment;
            if(a && assessment && assessment.id == a.id) {
              rubricAssessments[idx].rubric_assessment = assessment;
              found = true;
            }
          }
          if(!found) {
            if (!data.rubric_assessment) {
              data = { rubric_assessment: data };
            }
            rubricAssessments.push(data);
            var $option = $(document.createElement('option'));
            $option.val(assessment.id).text(assessment.assessor_name).attr('id', 'rubric_assessment_option_' + assessment.id);
            $("#rubric_assessments_select").prepend($option).val(assessment.id);
          }
          $("#rubric_assessment_option_" + assessment.id).text(assessment.assessor_name);
          $("#new_rubric_assessment_option").remove();
          $("#rubric_assessments_list").show();
          rubricAssessment.populateRubric($rubric, assessment);
          submission = assessment.artifact;
          if (submission) {
            showGrade(submission);
          }
          closeRubric();
        });
      });
      $("#rubric_holder .rubric").css({'width': 'auto', 'marginTop': 0});
      makeRubricAccessible($("#rubric_holder"));
      $(".hide_rubric_link").click(function(event) {
        event.preventDefault();
        closeRubric();
      });
      $(".assess_submission_link").click(function(event) {
        event.preventDefault();
        $("#rubric_assessments_select").change();
        openRubric();
      });
      $("#rubric_assessments_select").change(function() {
        var id = $(this).val();
        var found = null;
        for(var idx in rubricAssessments) {
          var assessment = rubricAssessments[idx].rubric_assessment;
          if(assessment.id == id) {
            found = assessment;
          }
        }
        rubricAssessment.populateRubric($("#rubric_holder .rubric"), found);
        var current_user = (!found || found.assessor_id == ENV.RUBRIC_ASSESSMENT.assessor_id);
        $("#rubric_holder .save_rubric_button").showIf(current_user);
      }).change();
      $(".media_comment_link").click(function(event) {
        event.preventDefault();
        $("#add_comment_form").hide();
        $("#media_media_recording").show();
        $recording = $("#media_media_recording").find(".media_recording");
        $recording.mediaComment('create', 'any', function(id, type) {
          $("#media_media_recording").data('comment_id', id).data('comment_type', type);
          $(document).triggerHandler('comment_change');
          $("#add_comment_form").show();
          $("#media_media_recording").hide();
          $recording.empty();
        }, function() {
          $("#add_comment_form").show();
          $("#media_media_recording").hide();
        });
      });
      $("#media_recorder_container a").live('click', function(event) {
        $("#add_comment_form").show();
        $("#media_media_recording").hide();
      });
      $(".comments .comment_list")
        .delegate(".play_comment_link", 'click', function(event) {
          event.preventDefault();
          var comment_id = $(this).parents(".comment_media").getTemplateData({textValues: ['media_comment_id']}).media_comment_id;
          if(comment_id) {
            $(this).parents(".comment_media").find(".media_comment_content").mediaComment('show', comment_id, 'video');
          }
        })

        // this is to prevent the default behavior of loading the video inline from happening
        // the .delegate(".play_comment_link"... and the .delegate('a.instructure_inline_media_comment'...
        // are actually selecting the same links I just wanted to use the different selectors because
        // instructure.js uses 'a.instructure_inline_media_comment' as the selector for its .live handler
        // to show things inline.
        .delegate('a.instructure_inline_media_comment', 'click', function(e){
          // dont let it bubble past this so it doesnt get to the .live handler to show the video inline
          e.preventDefault();
          e.stopPropagation();
        });

        showGrade(ENV.SUBMISSION.submission);
    });
  };
  // necessary for tests
  SubmissionsObj.teardown = function() {
    $(window).unbind('resize', windowResize);
    $(document).unbind('comment_change');
    $(document).unbind('grading_change');
  };
  $(document).fragmentChange(function(event, hash) {
    if(hash == '#rubric') {
      $(".assess_submission_link:visible:first").click();
    } else if(hash.match(/^#comment/)) {
      var params = null;
      try {
        params = JSON.parse(hash.substring(8));
      } catch(e) { }
      if(params && params.comment) {
        $(".grading_comment").val(params.comment);
      }
      $(".grading_comment").focus().select();
    }
  });
  INST.refreshGrades = function() {
    var url = $(".submission_data_url").attr('href');
    setTimeout(function() {
      $.ajaxJSON(url, 'GET', {}, submissionLoaded);
    }, 500);
  };

  return SubmissionsObj;
});
