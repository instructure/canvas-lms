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
  'i18n!quizzes.moderate',
  'jquery' /* $ */,
  'quiz_timing',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jquery.instructure_forms' /* fillFormData, getFormData */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData */,
  'vendor/date' /* Date.parse */
], function(I18n, $, timing) {
  var DIALOG_WIDTH = 490;
  /**
   * Updates the digit(s) in the "gets X extra minutes" message in a student's
   * block.
   *
   * @param {jQuery} $studentBlock
   *        Selector to the student block you're updating.
   *
   * @param {Number} extraTime
   *        The submission's extra allotted time.
   */
  var updateExtraTime = function($studentBlock, extraTime) {
    var $extraTime = $studentBlock.find('.extra_time_allowed');

    if (extraTime > 0) {
      $extraTime.text($extraTime.text().replace(/\s\d+\s/, ' ' + extraTime + ' '));
    }

    $extraTime.toggle(extraTime > 0);
  };

  window.moderation = {
    updateTimes: function() {
      var now = new Date();
      moderation.studentsCurrentlyTakingQuiz = !!$("#students .student.in_progress");
      $("#students .student.in_progress").each(function() {
        var $row = $(this);
        var row = $row.data('timing') || {};
        var started_at = $row.attr('data-started-at');
        var end_at = $row.attr('data-end-at');
        if(!row.referenceDate) {
          $.extend(row, timing.setReferenceDate(started_at, end_at, now));
        }
        if(!row.referenceDate) { return; }
        $row.data('timing', row);
        var diff = row.referenceDate.getTime() - now.getTime() - row.clientServerDiff;
        if(row.isDeadline && diff < 0) {
          $row.find(".time").text(I18n.t('time_up', "Time Up!"));
          return;
        }
        $row.data('minutes_left', diff / 60000);
        var date = new Date(Math.abs(diff));
        var yr = date.getUTCFullYear() - 1970;
        var mon = date.getUTCMonth();
        mon = mon + (12 * yr);
        var day = date.getUTCDate() - 1;
        var hr = date.getUTCHours();
        var min = date.getUTCMinutes();
        var sec = date.getUTCSeconds();
        var times = [];
        if(mon) { times.push(mon < 10 ? '0' + mon : mon); }
        if(day) { times.push(day < 10 ? '0' + day : day); }
        if(hr) { times.push(hr < 10 ? '0' + hr : hr); }
        if(true || min) { times.push(min < 10 ? '0' + min : min); }
        if(true || sec) { times.push(sec < 10 ? '0' + sec : sec); }
        $row.find(".time").text(times.join(":"));
      });
    },
    updateSubmission: function(submission, updateLastUpdatedAt) {
      var $student = $("#student_" + submission.user_id);
      if(updateLastUpdatedAt) {
        moderation.lastUpdatedAt = new Date(Math.max(Date.parse(submission.updated_at), moderation.lastUpdatedAt));
      }
      var state_text = "";
      if(submission.workflow_state == 'complete' || submission.workflow_state == 'pending_review') {
        state_text = I18n.t('finished_in_duration', "finished in %{duration}", {'duration': submission.finished_in_words});
      }
      var data = {
        attempt: submission.attempt || '--',
        extra_time: submission.extra_time,
        extra_attempts: submission.extra_attempts,
        score: submission.kept_score
      };
      if(submission.attempts_left == -1) {
        data.attempts_left = '--';
      } else if(submission.attempts_left) {
        data.attempts_left = submission.attempts_left;
      }
      if(submission.workflow_state != 'untaken') {
        data.time = state_text;
      }
      $student
        .fillTemplateData({data: data})
        .toggleClass('extendable', submission['extendable?'])
        .toggleClass('in_progress', submission.workflow_state == 'untaken')
        .toggleClass('manually_unlocked', !!submission.manually_unlocked)
        .attr('data-started-at', submission.started_at || '')
        .attr('data-end-at', submission.end_at || '')
        .data('timing', null)
        .find(".unlocked").showIf(submission.manually_unlocked);

      updateExtraTime($student, submission.extra_time);
    },
    lastUpdatedAt: "",
    studentsCurrentlyTakingQuiz: false
  };

  $(document).ready(function(event) {
    timing.initTimes();
    setInterval(moderation.updateTimes, 500)
    var updateErrors = 0;
    var moderate_url = $(".update_url").attr('href');
    moderation.lastUpdatedAt = Date.parse($(".last_updated_at").text());
    var currently_updating = false;
    var $updating_img = $(".reload_link img");
    function updating(bool) {
      currently_updating = bool;
      if(bool) {
        $updating_img.attr('src', $updating_img.attr('src').replace("ajax-reload.gif", "ajax-reload-animated.gif"));
      } else {
        $updating_img.attr('src', $updating_img.attr('src').replace("ajax-reload-animated.gif", "ajax-reload.gif"));
      }
    }
    function updateSubmissions(repeat) {
      if(currently_updating) { return; }
      updating(true);
      var last_updated_at = moderation.lastUpdatedAt && moderation.lastUpdatedAt.toISOString();

      $.ajaxJSON($.replaceTags(moderate_url, 'update', last_updated_at), 'GET', {}, function(data) {
        updating(false);
        if(repeat) {
          if(data.length || moderation.studentsCurrentlyTakingQuiz) {
            setTimeout(function() { updateSubmissions(true); }, 60000);
          } else {
            setTimeout(function() { updateSubmissions(true); }, 180000);
          }
        }
        for(var idx in data) {
          moderation.updateSubmission(data[idx], true);
        }
      }, function(data) {
        updating(false);
        updateErrors++;
        if(updateErrors > 5) {
          $.flashMessage(I18n.t('errors.server_communication_failed', "There was a problem communicating with the server.  The system will try again in five minutes, or you can reload the page"));
          updateErrors = 0;
          if(repeat) {
            setTimeout(function() { updateSubmissions(true); }, 300000);
          }
        } else if(repeat) {
          setTimeout(function() { updateSubmissions(true); }, 120000);
        }
      });
    };
    setTimeout(function() { updateSubmissions(true); }, 1000);
    function checkChange() {
      var cnt = $(".student_check:checked").length;
      $("#checked_count").text(cnt);
      $(".moderate_multiple_link").showIf(cnt);
    }
    $("#check_all").change(function() {
      var isChecked = $(this).is(":checked");
      $(".student_check").each(function(index, elem) {
        $(elem).prop("checked", isChecked);
      });
      checkChange();
    });
    $(".student_check").change(function() {
      if(!$(this).attr('checked')) {
        $("#check_all").attr('checked', false);
      }
      checkChange();
    });

    $(".moderate_multiple_link").live('click', function(event) {
      event.preventDefault();
      var student_ids = []
      var data = {};
      $(".student_check:checked").each(function() {
        var $student = $(this).parents(".student");
        student_ids.push($(this).attr('data-id'));
        var student_data = {
          manually_unlocked: $student.hasClass('manually_unlocked') ? '1' : '0',
          extra_attempts: parseInt($student.find(".extra_attempts").text(), 10) || "",
          extra_time: parseInt($student.find(".extra_time").text(), 10) || ""
        };
        $.each(['manually_unlocked', 'extra_attempts', 'extra_time'], function() {
          if(data[this] == null) {
            data[this] = student_data[this].toString();
          } else if(data[this] != student_data[this].toString()) {
            data[this] = '';
          }
        });
      });
      $("#moderate_student_form").data('ids', student_ids);
      $("#moderate_student_dialog h2").text(I18n.t('extensions_for_students', {'one': "Extensions for 1 Student", 'other': "Extensions for %{count} Students"}, {'count': student_ids.length}));
      $("#moderate_student_form").fillFormData(data);
      $("#moderate_student_dialog").dialog({
        title: I18n.t('titles.student_extensions', "Student Extensions"),
        width: DIALOG_WIDTH
      }).fixDialogButtons();
    });

    $(".moderate_student_link").live('click', function(event) {
      event.preventDefault();
      var $student = $(this).parents(".student");
      var data = {
        manually_unlocked: $student.hasClass('manually_unlocked') ? '1' : '0',
        extra_attempts: parseInt($student.find(".extra_attempts").text(), 10) || "",
        extra_time: parseInt($student.find(".extra_time_allowed").text().replace(/[^\d]/g, ''), 10) || ""
      };
      var name = $student.find(".student_name").text();
      $("#moderate_student_form").fillFormData(data);
      $("#moderate_student_form").data('ids', [$student.attr('data-user-id')]);
      $("#moderate_student_form").find("button").attr('disabled', false);
      $("#moderate_student_dialog h2").text(I18n.t('extensions_for_student', "Extensions for %{student}", {'student': name}));
      $("#moderate_student_dialog").dialog({
        title: I18n.t('titles.student_extensions', "Student Extensions"),
        width: DIALOG_WIDTH
      }).fixDialogButtons();
    });
    $(".reload_link").click(function(event) {
      event.preventDefault();
      updateSubmissions();
    });

    $('#extension_extra_time')
      .on('invalid:not_a_number', function(e) {
        $(this).errorBox(I18n.t('errors.quiz_submission_extra_time_not_a_number', 'Extra time must be a number.'));
      })
      .on('invalid:greater_than', function(e) {
        $(this).errorBox(I18n.t('errors.quiz_submission_extra_time_too_short', 'Extra time must be greater than 0.'));
      })
      .on('invalid:less_than', function(e) {
        $(this).errorBox(I18n.t('errors.quiz_submission_extra_time_too_long', 'Extra time must be less than than 10080.'));
      });

    $('#extension_extra_attempts')
      .on('invalid:not_a_number', function(e) {
        $(this).errorBox(I18n.t('errors.quiz_submission_extra_attempts_not_a_number', 'Extra attempts must be a number.'));
      })
      .on('invalid:greater_than', function(e) {
        $(this).errorBox(I18n.t('errors.quiz_submission_extra_attempts_too_short', 'Extra attempts must be greater than 0.'));
      })
      .on('invalid:less_than', function(e) {
        $(this).errorBox(I18n.t('errors.quiz_submission_extra_attempts_too_long', 'Extra attempts must be less than than 1000.'));
      });

    $("#moderate_student_form").submit(function(event) {
      event.preventDefault();
      event.stopPropagation();
      var ids = $(this).data('ids');
      if(ids.length == 0) { return; }
      var $form = $(this);
      $form.find("button").attr('disabled', true).filter(".save_button").text(I18n.t('buttons.saving', "Saving..."));
      var finished = 0, errors = 0;
      var formData = $(this).getFormData();

      function valid(data) {
        var extraAttempts = parseInt(data.extra_attempts),
            extraTime     = parseInt(data.extra_time),
            valid         = true;

        if (data.extra_attempts && isNaN(extraAttempts)) {
          $("#extension_extra_attempts").trigger("invalid:not_a_number");
          valid = false;
        } else if (extraAttempts > 1000) {
          $("#extension_extra_attempts").trigger("invalid:less_than");
          valid = false;
        } else if (extraAttempts < 0) {
          $("#extension_extra_attempts").trigger("invalid:greater_than");
          valid = false;
        }

        if (data.extra_time && isNaN(extraTime)) {
          $("#extension_extra_time").trigger("invalid:not_a_number");
          valid = false;
        } else if (extraTime > 10080) { // 1 week
          $("#extension_extra_time").trigger("invalid:less_than");
          valid = false;
        } else if (extraTime < 0) {
          $("#extension_extra_time").trigger("invalid:greater_than");
          valid = false;
        }
        return valid;
      }
      if (!valid(formData)) {
        $form.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.save', "Save"));
        return;
      }

      function checkIfFinished() {
        if(finished >= ids.length) {
          if(errors > 0) {
            if(ids.length == 1) {
              $form.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.save_failed', "Save Failed, please try again"));
            } else {
              $form.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.save_failed_n_updates_lost', "Save Failed, %{n} Students were not updated", {'n': errors}));
            }
          } else {
            $form.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.save', "Save"));
            $("#moderate_student_dialog").dialog('close');
          }
        }
      };
      for(var idx in ids) {
        var id = ids[idx];
        var url = $.replaceTags($(".extension_url").attr('href'), 'user_id', id);
        $.ajaxJSON(url, 'POST', formData, function(data) {
          finished++;
          moderation.updateSubmission(data);
          checkIfFinished();
        }, function(data) {
          finished++;
          errors++;
          checkIfFinished();
        });
      }
    });
    $("#moderate_student_dialog").find('.cancel_button').click(function() {
      $("#moderate_student_dialog").dialog('close');
    });
    $(".extend_time_link").live('click', function(event) {
      event.preventDefault();
      var $row = $(event.target).parents(".student");
      var end_at = $.datetimeString($row.attr('data-end-at'));
      var started_at = $.datetimeString($row.attr('data-started-at'));
      var $dialog = $("#extend_time_dialog");
      $dialog.data('row', $row);
      $dialog.fillTemplateData({
        data: {
          end_at: end_at,
          started_at: started_at
        }
      });
      $dialog.find("button").attr('disabled', false);
      $dialog.dialog({
        title: I18n.t('titles.extend_quiz_time', "Extend Quiz Time"),
        width: DIALOG_WIDTH
      }).fixDialogButtons();
    });
    $("#extend_time_dialog").find(".cancel_button").click(function() {
      $("#extend_time_dialog").dialog('close');
    }).end().find(".save_button").click(function() {
      var $dialog = $("#extend_time_dialog");
      var data = $dialog.getFormData();
      var params = {};
      data.time = parseInt(data.time, 10) || 0;
      if(data.time <= 0) { return; }
      if(data.time_type == 'extend_from_now' && data.time < $dialog.data('row').data('minutes_left')) {
        var result = confirm(I18n.t('confirms.taking_time_away', "That would be less time than the student currently has.  Continue anyway?"));
        if(!result) { return; }
      }
      params[data.time_type] = data.time;
      $dialog.find("button").attr('disabled', true).filter(".save_button").text(I18n.t('buttons.extending_time', "Extending Time..."));
      var url = $.replaceTags($(".extension_url").attr('href'), 'user_id', $dialog.data('row').attr('data-user-id'));
      $.ajaxJSON(url, 'POST', params, function(data) {
        $dialog.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.extend_time', "Extend Time"));
        moderation.updateSubmission(data);
        $dialog.dialog('close');
      }, function(data) {
        $dialog.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.time_extension_failed', "Extend Time Failed, please try again"));
      });
    });

    var outstanding = {
      init: function(event) {
        event.preventDefault();
        this.$container = $(".child_container")

        this.showDialog();
        this.showResultsList(this.data);
      },
      fetchData: function () {
        var indexUrl = $(".outstanding_index_url").attr('href');
        $.ajaxJSON(indexUrl, "GET", null, this.storeDataAndShowAlert.bind(this));
      },
      storeDataAndShowAlert: function(data) {
        if (data.quiz_submissions.length > 0) {
          this.toggleAlertHeader();
          this.data = data;
        }
      },
      toggleAlertHeader: function() {
        $(".alert").toggle();
      },
      showResultsList: function(data) {
        this.adjustDialogHeight(data);
        $("#autosubmit_content_description_things_to_do").show();

        this.buildResultList(data);
        $("#autosubmit_form_submit_btn").prop('disabled', false);
      },
      adjustDialogHeight: function(data) {
        var height = 80;
        height = height + (data['quiz_submissions'].length * 29);
        if (height > 270) {
          height = 270;
        }
        this.dialog.animate({height: height + 'px'});
      },
      buildResultList: function(data) {
        $.each(data["quiz_submissions"], function (index, qs) {
          clone = $(".example_autosubmit_row").clone()
            .removeClass("example_autosubmit_row")
            .appendTo(".outstanding_submissions_list").show();
          clone.children("input").val(qs.id);
          clone.find("input").prop("checked", true)
            .attr('id', "id_" + index);
          clone.children("label").attr("for", 'id_'+index)
            .text(data["users"][index].sortable_name);
          clone.show();
        });
      },
      submitOutstandings: function () {
        var gradeUrl = $(".outstanding_grade_url").attr('href');
        var ids = this.$container.find("input:checked").map(function extractQSIds () {
          return this.value;
        }).get()
        var json = {'quiz_submission_ids': ids };
        $.ajaxJSON(gradeUrl, "POST", json, function successReporting(data,xhr) {
          if (xhr.status === 204) {
            if (ids.length == this.data["users"].length) {
              this.toggleAlertHeader();
            }
            $.flashMessage("Successfully graded outstanding quizzes")
            this.closeDialog();
            updateSubmissions();
          }
        }.bind(this));
      },
      cleanUpEventListeners: function () {
        $('#autosubmit_form_cancel_btn').off();
        $('#autosubmit_form_submit_btn').off();
      },
      closeDialog: function() {
        $("#autosubmit_content_description_things_to_do").hide();
        $("#autosubmit_content_description_all_done").hide();
        $(".autosubmit_data_row").not(".example_autosubmit_row").remove();
        this.cleanUpEventListeners();
        this.dialog.dialog('close');
      },
      setFocusOnLoad: function(event, ui) {
        $("#autosubmit_form").focus();
      },
      showDialog: function() {
        this.dialog = $("#autosubmit_form").dialog({
          title: I18n.t('titles.autosubmit_dialog', "Outstanding Quiz Submissions"),
          modal: true,
          width: DIALOG_WIDTH,
          height: 200,
          close: this.closeDialog.bind(this)
        }).dialog('open').fixDialogButtons();

        // Set up button behaviors
        $('#autosubmit_form_cancel_btn').on('click keyclick', function() {
          this.closeDialog();
        }.bind(this));
        $("#autosubmit_form_submit_btn").on("click keyclick", this.submitOutstandings.bind(this));

        this.setFocusOnLoad();
      }
    };
    outstanding.fetchData();
    $("#check_outstanding").click(outstanding.init.bind(outstanding));
  });
});
