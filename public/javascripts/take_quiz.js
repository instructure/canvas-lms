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
  'compiled/views/quizzes/FileUploadQuestionView',
  'compiled/models/File',
  'i18n!quizzes.take_quiz',
  'jquery' /* $ */,
  'quiz_timing',
  'compiled/behaviors/autoBlurActiveInput',
  'underscore',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.toJSON',
  'jquery.instructure_date_and_time' /* friendlyDatetime, friendlyDate */,
  'jquery.instructure_forms' /* getFormData, errorBox */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* scrollSidebar */,
  'compiled/jquery.rails_flash_notifications',
  'compiled/tinymce',
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'compiled/behaviors/quiz_selectmenu'
], function(FileUploadQuestionView, File, I18n, $, timing, autoBlurActiveInput, _) {

  var lastAnswerSelected = null;
  var lastSuccessfulSubmissionData = null;
  var quizSubmission = (function() {
    var timeMod = 0,
        started_at =  $(".started_at"),
        end_at = $(".end_at"),
        startedAtText = started_at.text(),
        endAtText = end_at.text(),
        endAtParsed = endAtText && new Date(endAtText),
        $countdown_seconds = $(".countdown_seconds"),
        $time_running_time_remaining = $(".time_running,.time_remaining"),
        $last_saved = $('#last_saved_indicator');

    return {
      referenceDate: null,
      countDown: null,
      isDeadline: true,
      fiveMinuteDeadline: false,
      oneMinuteDeadline: false,
      submitting: false,
      dialogged: false,
      contentBoxCounter: 0,
      lastSubmissionUpdate: new Date(),
      currentlyBackingUp: false,
      started_at: started_at,
      end_at: end_at,
      time_limit: parseInt($(".time_limit").text(), 10) || null,
      oneAtATime: $("#submit_quiz_form").hasClass("one_question_at_a_time"),
      cantGoBack: $("#submit_quiz_form").hasClass("cant_go_back"),
      finalSubmitButtonClicked: false,
      updateSubmission: function(repeat, beforeLeave) {
        if(quizSubmission.submitting && !repeat) { return; }
        var now = new Date();
        if((now - quizSubmission.lastSubmissionUpdate) < 1000) { return }
        if(quizSubmission.currentlyBackingUp) { return; }
        quizSubmission.currentlyBackingUp = true;
        quizSubmission.lastSubmissionUpdate = new Date();
        var data = $("#submit_quiz_form").getFormData();

        $(".question_holder .question").each(function() {
          value = ($(this).hasClass("marked")) ? "1" : "";
          data[$(this).attr('id') + "_marked"] = value;
        });

        $last_saved.text(I18n.t('saving', 'Saving...'));
        var url = $(".backup_quiz_submission_url").attr('href');
        // If called before leaving the page (ie. onbeforeunload), we can't use any async or FF will kill the PUT request.
        if (beforeLeave){
          $.flashMessage(I18n.t('saving', 'Saving...'));
          $.ajax({
            url: url,
            data: data,
            type: 'PUT',
            dataType: 'json',
            async: false        // NOTE: Not asynchronous. Otherwise Firefox will cancel the request as navigating away from the page.
            // NOTE: No callbacks. Don't care about response. Just making effort to save the quiz
          });
        }
        else {
          (function(submissionData) {
            // Need a shallow clone of the data here because $.ajaxJSON modifies in place
            var thisSubmissionData = _.clone(submissionData);
            // If this is a timeout-based submission and the data is the same as last time,
            // palliate the server by skipping the data submission
            if (repeat && _.isEqual(submissionData, lastSuccessfulSubmissionData)) {
              quizSubmission.currentlyBackingUp = false;
              setTimeout(function() { quizSubmission.updateSubmission(true) }, 30000);
              return;
            }
            $.ajaxJSON(url, 'PUT', submissionData,
              // Success callback
              function(data) {
                lastSuccessfulSubmissionData = thisSubmissionData;
                $last_saved.text(I18n.t('saved_at', 'Quiz saved at %{t}', { t: $.friendlyDatetime(new Date()) }));
                quizSubmission.currentlyBackingUp = false;
                if(repeat) {
                  setTimeout(function() {quizSubmission.updateSubmission(true) }, 30000);
                }
                if(data && data.end_at) {
                  var endAtFromServer     = Date.parse(data.end_at),
                      submissionEndAt     = Date.parse(quizSubmission.end_at.text()),
                      serverEndAtTime     = endAtFromServer.getTime(),
                      submissionEndAtTime = submissionEndAt.getTime();

                  quizSubmission.referenceDate = null;

                  // if the new end_at from the server is different than our current end_at, then notify
                  // the user that their time limit's changed and let updateTime do the rest.
                  if (serverEndAtTime !== submissionEndAtTime) {
                    serverEndAtTime > submissionEndAtTime ?
                      $.flashMessage(I18n.t('notices.extra_time', 'You have been given extra time on this attempt')) :
                      $.flashMessage(I18n.t('notices.less_time', 'Your time for this quiz has been reduced.'));

                    quizSubmission.end_at.text(data.end_at);
                    endAtText   = data.end_at;
                    endAtParsed = new Date(data.end_at);
                  }
                }
              },
              // Error callback
              function(resp, ec) {
                var current_user_id = $("#identity .user_id").text() || "none";
                quizSubmission.currentlyBackingUp = false;

                // has the user logged out?
                // TODO: support this redirect in LDB, by getting out of high security mode.
                if (!ENV.LOCKDOWN_BROWSER && (ec.status == 401 || resp['status'] == 'unauthorized')) {
                  var $dialog = $("#deauthorized_dialog");
                  if ($dialog.is(':data(dialog)')) {
                    if (!$dialog.dialog("isOpen")) { $dialog.dialog("open"); }
                  } else {
                    $dialog.dialog({
                      modal: true,
                      buttons: [{
                        text: I18n.t("#buttons.cancel", "Cancel"),
                        'class': "dialog_closer",
                        click: function() { $(this).dialog("close"); }
                      }, {
                        text: I18n.t("#buttons.login", "Login"),
                        'class': "btn-primary relogin_button button_type_submit",
                        click: function() {
                          quizSubmission.navigatingToRelogin = true;
                          $('#deauthorized_dialog').submit();
                        }
                      }]
                    });
                  }
                } else {
                  $.ajaxJSON(
                      location.protocol + '//' + location.host + "/simple_response.json?user_id=" + current_user_id + "&rnd=" + Math.round(Math.random() * 9999999),
                      'GET', {},
                      function() {},
                      function() {
                        $.flashError(I18n.t('errors.connection_lost', "Connection to %{host} was lost.  Please make sure you're connected to the Internet before continuing.", {'host': location.host}));
                      }
                  );
                }

                if(repeat) {
                  setTimeout(function() {quizSubmission.updateSubmission(true) }, 30000);
                }
              },
              {
                timeout: 5000
              }
            );
          })(data);
        }
      },

      updateTime: function() {
        var now = new Date();
        var end_at = quizSubmission.time_limit ? endAtText : null;
        timeMod = (timeMod + 1) % 120;
        if(timeMod == 0 && !end_at && !quizSubmission.twelveHourDeadline) {
          quizSubmission.referenceDate = null;
          var end = endAtParsed;
          if(!quizSubmission.time_limit && (end - now) < 43200000) {
            end_at = endAtText;
          }
        }
        if(!quizSubmission.referenceDate) {
          $.extend(quizSubmission, timing.setReferenceDate(startedAtText, end_at, now));
        }
        if(quizSubmission.countDown) {
          var diff = quizSubmission.countDown.getTime() - now.getTime() - quizSubmission.clientServerDiff;
          if(diff <= 0) {
            diff = 0;
          }
          var d = new Date(diff);
          $countdown_seconds.text(d.getUTCSeconds());
          if(diff <= 0 && !quizSubmission.submitting) {
            quizSubmission.submitting = true;
            quizSubmission.submitQuiz();
          }
        }
        var diff = quizSubmission.referenceDate.getTime() - now.getTime() - quizSubmission.clientServerDiff;
        if(quizSubmission.isDeadline) {
          if(diff < 1000) {
            diff = 0;
          }
          if(diff < 1000 && !quizSubmission.dialogged) {
            quizSubmission.dialogged = true;
            quizSubmission.countDown = new Date(now.getTime() + 10000);
            $("#times_up_dialog").show().dialog({
              title: I18n.t('titles.times_up', "Time's Up!"),
              width: "auto",
              height: "auto",
              modal: true,
              overlay: {
                backgroundColor: "#000",
                opacity: 0.7
              },
              close: function() {
                if(!quizSubmission.submitting) {
                  quizSubmission.submitting = true;
                  quizSubmission.submitQuiz();
                }
              }
            });
          } else if(diff >    30000 && diff <    60000 && !quizSubmission.oneMinuteDeadline) {
            quizSubmission.oneMinuteDeadline = true;
            $.flashMessage(I18n.t('notices.one_minute_left', "One Minute Left"));
          } else if(diff >   250000 && diff <   300000 && !quizSubmission.fiveMinuteDeadline) {
            quizSubmission.fiveMinuteDeadline = true;
            $.flashMessage(I18n.t('notices.five_minutes_left', "Five Minutes Left"));
          } else if(diff >  1800000 && diff <  1770000 && !quizSubmission.thirtyMinuteDeadline) {
            quizSubmission.thirtyMinuteDeadline = true;
            $.flashMessage(I18n.t('notices.thirty_minutes_left', "Thirty Minutes Left"));
          } else if(diff > 43200000 && diff < 43170000 && !quizSubmission.twelveHourDeadline) {
            quizSubmission.twelveHourDeadline = true;
            $.flashMessage(I18n.t('notices.twelve_hours_left', "Twelve Hours Left"));
          }
        }
        quizSubmission.updateTimeString(diff);
      },
      updateTimeString: function(diff) {
        var date = new Date(Math.abs(diff));
        var yr = date.getUTCFullYear() - 1970;
        var mon = date.getUTCMonth();
        var day = date.getUTCDate() - 1;
        var hr = date.getUTCHours();
        var min = date.getUTCMinutes();
        var sec = date.getUTCSeconds();
        var times = [];
        if(yr) { times.push(I18n.t('years_count', "Year", {'count': yr})); }
        if(mon) { times.push(I18n.t('months_count', "Month", {'count': mon})); }
        if(day) { times.push(I18n.t('days_count', "Day", {'count': day})); }
        if(hr) { times.push(I18n.t('hours_count', "Hour", {'count': hr})); }
        if(true || min) { times.push(I18n.t('minutes_count', "Minute", {'count': min})); }
        if(true || sec) { times.push(I18n.t('seconds_count', "Second", {'count': sec})); }
        $time_running_time_remaining.text(times.join(", "));
      },
      updateFinalSubmitButtonState: function() {
        var allQuestionsAnswered = ($("#question_list li:not(.answered)").length == 0);
        var lastQuizPage = ($("#submit_quiz_form").hasClass('last_page'));
        var thisQuestionAnswered = ($("div.question.answered").length > 0);
        var oneAtATime = quizSubmission.oneAtATime;

        var active = (oneAtATime && lastQuizPage && thisQuestionAnswered) || allQuestionsAnswered;

        quizSubmission.toggleActiveButtonState("#submit_quiz_button", active);
      },

      updateQuestionIndicators: function(answer, questionId){
        var listSelector = "#list_" + questionId;
        var questionSelector = "#" + questionId;
        var combinedId = listSelector + ", " + questionSelector;
        var $questionIcon = $(listSelector + "> i.placeholder");
        if(answer) {
          $(combinedId).addClass('answered');
          $questionIcon.addClass('icon-check').removeClass('icon-question');
          $questionIcon.siblings('div.icon-text').text(I18n.t('question_answered',"Answered"))
        } else {
          $(combinedId).removeClass('answered');
          $questionIcon.addClass('icon-question').removeClass('icon-check');
          $questionIcon.siblings('div.icon-text').text(I18n.t('question_unanswered', "Haven't Answered Yet"))
        }
      },

      updateNextButtonState: function(id) {
        var $question = $("#" + id);
        quizSubmission.toggleActiveButtonState('button.next-question', $question.hasClass('answered'));
      },
      toggleActiveButtonState: function(selector, primary) {
        var addClass = (primary ? 'btn-primary' : 'btn-secondary');
        var removeClass = (primary ? 'btn-secondary' : 'btn-primary');
        $(selector).addClass(addClass).removeClass(removeClass);
      },
      submitQuiz: function() {
        var action = $('#submit_quiz_button').data('action');
        $('#submit_quiz_form').attr('action', action).submit();
      }
    };
  })();

  $(document).mousedown(function(event) {
    lastAnswerSelected = $(event.target).parents(".answer")[0];
  }).keydown(function() {
    lastAnswerSelected = null;
  });

  $(function() {
    $.scrollSidebar();
    autoBlurActiveInput();

    if($("#preview_mode_link").length == 0) {
      window.onbeforeunload = function() {
        if (!quizSubmission.navigatingToRelogin) {
          quizSubmission.updateSubmission(false, true);
          if(!quizSubmission.submitting && !quizSubmission.alreadyAcceptedNavigatingAway) {
            return I18n.t('confirms.unfinished_quiz', "You're about to leave the quiz unfinished.  Continue anyway?");
          }
        }
      };
      $(document).delegate('a', 'click', function(event) {
        if($(this).closest('.ui-dialog,.mceToolbar,.ui-selectmenu').length > 0) { return; }
        
        if($(this).hasClass('no-warning')) {
          quizSubmission.alreadyAcceptedNavigatingAway = true
          return;
        }

        if(!event.isDefaultPrevented()) {
          var url = $(this).attr('href') || "";
          var hashStripped = location.href;
          if(hashStripped.indexOf('#')) {
            hashStripped = hashStripped.substring(0, hashStripped.indexOf('#'));
          }
          if(url.indexOf('#') == 0 || url.indexOf(hashStripped + "#") == 0) {
            return;
          }
          var result = confirm(I18n.t('confirms.navigate_away', "You're about to navigate away from this page.  Continue anyway?"));
          if(!result) {
            event.preventDefault();
          } else {
            quizSubmission.alreadyAcceptedNavigatingAway = true
          }
        }
      });
    }
    var $questions = $("#questions");
    $("#question_list")
      .delegate(".jump_to_question_link", 'click', function(event) {
        event.preventDefault();
        var $obj = $($(this).attr('href'));
        $("html,body").scrollTo($obj.parent());
        $obj.find(":input:first").focus().select();
      })
      .find(".list_question").bind({
        mouseenter: function(event) {
          var $this = $(this),
              data = $this.data(),
              title = I18n.t('titles.not_answered', "Haven't Answered yet");

          if ($this.hasClass('marked')) {
            title = I18n.t('titles.come_back_later', "You marked this question to come back to later");
          } else if ($this.hasClass('answered')) {
            title = I18n.t('titles.answered', "Answered");
          }
          $this.attr('title', title);

          if(!quizSubmission.oneAtATime) {
            data.relatedQuestion || (data.relatedQuestion = $("#" + $this.attr('id').substring(5)));
            data.relatedQuestion.addClass('related');
          }
        },
        mouseleave: function(event) {
          if(!quizSubmission.oneAtATime) {
            var relatedQuestion = $(this).data('relatedQuestion')
            relatedQuestion && relatedQuestion.removeClass('related');            
          }
        }
      });

    $questions.find('.group_top,.answer_select').bind({
      mouseenter: function(event) {
        $(this).addClass('hover');
      },
      mouseleave: function(event) {
        $(this).removeClass('hover');
      }
    });

    $questions
      .delegate(":checkbox,:radio,label", 'change mouseup', function(event) {
        var $answer = $(this).parents(".answer");
        if (lastAnswerSelected == $answer[0]) {
          $answer.find(":checkbox,:radio").blur();
          quizSubmission.updateSubmission();
        }
      })
      .delegate(":text,textarea,select", 'change', function(event, update) {
        var $this = $(this);
        if ($this.hasClass('numerical_question_input')) {
          var val = parseFloat($this.val());
          $this.val(isNaN(val) ? "" : val.toFixed(4));
        }
        if (update !== false) {
          quizSubmission.updateSubmission();
        }
      })
      .delegate(".numerical_question_input", {
        keyup: function(event) {
          var val = $(this).val();
          if (val === '' || !isNaN(parseFloat(val))) {
            $(this).triggerHandler('focus'); // makes the errorBox go away
          } else{
            $(this).errorBox(I18n.t('errors.only_numerical_values', "only numerical values are accepted"));
          }
        }
      })
      .delegate(".flag_question", 'click', function() {
        var $question = $(this).parents(".question");
        $question.toggleClass('marked');
        $("#list_" + $question.attr('id')).toggleClass('marked');
        quizSubmission.updateSubmission();
      })
      .delegate(".question_input", 'change', function(event, update, changedMap) {
        var $this = $(this),
            tagName = this.tagName.toUpperCase(),
            id = $this.parents(".question").attr('id'),
            val = "";
        if (tagName == "A") return;
        if (changedMap) { // reduce redundant jquery lookups and other calls
          if (changedMap[id]) return;
          changedMap[id] = true;
        }

        if (tagName == "TEXTAREA") {
          val = $this.editorBox('get_code');
        } else if ($this.attr('type') == "text" || $this.attr('type') == 'hidden') {
          val = $this.val();
        } else if (tagName == "SELECT") {
          var $selects = $this.parents(".question").find("select.question_input");
          val = !$selects.filter(function() { return !$(this).val() }).length;
        } else {
          $this.parents(".question").find(".question_input").each(function() {
            if($(this).attr('checked') || $(this).attr('selected')) {
              val = true;
            }
          });
        }

        quizSubmission.updateQuestionIndicators(val, id);
        quizSubmission.updateFinalSubmitButtonState();
        quizSubmission.updateNextButtonState(id);
      })

    $questions.find(".question_input").trigger('change', [false, {}]);

    setInterval(function() {
      $("textarea.question_input").each(function() {
        $(this).triggerHandler('change', false);
      });
    }, 2500);

    $(".hide_time_link").click(function(event) {
      event.preventDefault();
      if($(".time_running").css('visibility') != 'hidden') {
        $(".time_running").css('visibility', 'hidden');
        $(this).text(I18n.t('show_time_link', "Show"));
      } else {
        $(".time_running").css('visibility', 'visible');
        $(this).text(I18n.t('hide_time_link', "Hide"));
      }
    });

    setTimeout(function() {
      $("#question_list .list_question").each(function() {
        var $this = $(this);
        if($this.find(".jump_to_question_link").text() == "Spacer") {
          $this.remove();
        }
      });
    }, 1000);

    // Suppress "<ENTER>" key from submitting a form when clicked inside a text input.
    $("#submit_quiz_form input[type=text]").keypress(function(e){
      if (e.keyCode == 13)
        return false;
    });

    $(".quiz_submit").click(function(event) {
      quizSubmission.finalSubmitButtonClicked = true;
    });

    $("#submit_quiz_form").submit(function(event) {
      $(".question_holder textarea.question_input").each(function() { $(this).change(); });

      var unanswered;
      var warningMessage;
      
      if(quizSubmission.cantGoBack) {
        if(!$(".question").hasClass("answered")) {
          warningMessage = I18n.t('confirms.cant_go_back_blank',
            "You can't come back to this question once you hit next. Are you sure you want to leave it blank?");
        }
      }

      if(quizSubmission.finalSubmitButtonClicked) {
        quizSubmission.finalSubmitButtonClicked = false; // reset in case user cancels

        if(quizSubmission.cantGoBack) {
          unseen = $("#question_list .list_question:not(.seen)").length;
          if(unseen > 0) {
            warningMessage = I18n.t('confirms.unseen_questions',
              {'one': "There is still 1 question you haven't seen yet.  Submit anyway?",
               'other': "There are still %{count} questions you haven't seen yet.  Submit anyway?"},
               {'count': unseen})            
          }
        }
        else {
          unanswered = $("#question_list .list_question:not(.answered)").length;
          if(unanswered > 0) {
            warningMessage = I18n.t('confirms.unanswered_questions',
              {'one': "You have 1 unanswered question (see the right sidebar for details).  Submit anyway?",
               'other': "You have %{count} unanswered questions (see the right sidebar for details).  Submit anyway?"},
               {'count': unanswered});            
          }
        }
      }

      if(warningMessage != undefined && !quizSubmission.submitting) {
        var result = confirm(warningMessage);
        if(!result) {
          event.preventDefault();
          event.stopPropagation();
          return false;
        }
      }        

      quizSubmission.submitting = true;
    });

    $(".submit_quiz_button").click(function(event) {
      event.preventDefault();
      $("#times_up_dialog").dialog('close');
    });

    setTimeout(function() {
      $(".question_holder textarea.question_input").each(function() {
        $(this).attr('id', 'question_input_' + quizSubmission.contentBoxCounter++);
        $(this).editorBox();
      });
    }, 2000);

    setInterval(quizSubmission.updateTime, 400);

    setTimeout(function() { quizSubmission.updateSubmission(true) }, 15000);

    var $submit_buttons = $("#submit_quiz_form button[type=submit]");

    // set the form action depending on the button clicked
    $submit_buttons.click(function(event) {
      // call updateSubmission with beforeLeave=true so quiz is saved synchronously
      quizSubmission.updateSubmission(false, true);

      var action = $(this).data('action');
      if(action != undefined) {
        $('#submit_quiz_form').attr('action', action);
      }
    });

    // now that JS has been initialized, enable the next and previous buttons
    $submit_buttons.removeAttr('disabled');
  });

  $('.file-upload-question-holder').each(function(i,el) {
    var $el = $(el);
    var val = parseInt($el.find('input.attachment-id').val(),10);
    if (val && val !==  0){
      $el.find('.file-upload-box').addClass('file-upload-box-with-file');
    }
    var model = new File(ENV.ATTACHMENTS[val], {preflightUrl: ENV.UPLOAD_URL});
    new FileUploadQuestionView({el: el, model: model}).render();
  });

});

