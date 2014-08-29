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
  'jst/speed_grader/submissions_dropdown',
  'compiled/util/round',
  'underscore',
  'INST' /* INST */,
  'i18n!gradebook',
  'jquery' /* $ */,
  'timezone',
  'compiled/userSettings',
  'str/htmlEscape',
  'rubric_assessment',
  'jst/_turnitinInfo',
  'jst/_turnitinScore',
  'ajax_errors' /* INST.log_error */,
  'jqueryui/draggable' /* /\.draggable/ */,
  'jquery.ajaxJSON' /* getJSON, ajaxJSON */,
  'jquery.instructure_forms' /* ajaxJSONFiles */,
  'jquery.doc_previews' /* loadDocPreview */,
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf, hasScrollbar */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImg, loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'media_comments' /* mediaComment */,
  'compiled/jquery/mediaCommentThumbnail',
  'vendor/jquery.ba-hashchange' /* hashchange */,
  'vendor/jquery.elastic' /* elastic */,
  'vendor/jquery.getScrollbarWidth' /* getScrollbarWidth */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'vendor/jquery.spin' /* /\.spin/ */,
  'vendor/scribd.view' /* scribd */,
  'vendor/spin' /* new Spinner */,
  'vendor/ui.selectmenu' /* /\.selectmenu/ */
], function(submissionsDropdownTemplate, round, _, INST, I18n, $, tz, userSettings, htmlEscape, rubricAssessment, turnitinInfoTemplate, turnitinScoreTemplate) {

  // fire off the request to get the jsonData
  window.jsonData = {};
  $.ajaxJSON(window.location.pathname+ '.json' + window.location.search, 'GET', {}, function(json) {
    jsonData = json;
    $(EG.jsonReady);
  });
  // ...and while we wait for that, get this stuff ready

  // PRIVATE VARIABLES AND FUNCTIONS
  // all of the $ variables here are to speed up access to dom nodes,
  // so that the jquery selector does not have to be run every time.
  // note, this assumes that this js file is being loaded at the bottom of the page
  // so that all these dom nodes already exists.
  var $window = $(window),
      $body = $("body"),
      $full_width_container =$("#full_width_container"),
      $left_side = $("#left_side"),
      $resize_overlay = $("#resize_overlay"),
      $right_side = $("#right_side"),
      $width_resizer = $("#width_resizer"),
      $fixed_bottom = $("#fixed_bottom"),
      $gradebook_header = $("#gradebook_header"),
      assignmentUrl = $("#assignment_url").attr('href'),
      $full_height = $(".full_height"),
      $rightside_inner = $("#rightside_inner"),
      $comments = $("#comments"),
      $comment_blank = $("#comment_blank").removeAttr('id').detach(),
      $comment_attachment_blank = $("#comment_attachment_blank").removeAttr('id').detach(),
      $comment_media_blank = $("#comment_media_blank").removeAttr('id').detach(),
      $add_a_comment = $("#add_a_comment"),
      $add_a_comment_submit_button = $add_a_comment.find("button"),
      $add_a_comment_textarea = $add_a_comment.find("textarea"),
      $group_comment_wrapper = $("#group_comment_wrapper"),
      $comment_attachment_input_blank = $("#comment_attachment_input_blank").detach(),
      fileIndex = 1,
      $add_attachment = $("#add_attachment"),
      minimumWindowHeight = 500,
      $submissions_container = $("#submissions_container"),
      $iframe_holder = $("#iframe_holder"),
      $avatar_image = $("#avatar_image"),
      $x_of_x_students = $("#x_of_x_students_frd"),
      $grded_so_far = $("#x_of_x_graded"),
      $average_score = $("#average_score"),
      $this_student_does_not_have_a_submission = $("#this_student_does_not_have_a_submission").hide(),
      $this_student_has_a_submission = $('#this_student_has_a_submission').hide(),
      $rubric_assessments_select = $("#rubric_assessments_select"),
      $rubric_summary_container = $("#rubric_summary_container"),
      $rubric_holder = $("#rubric_holder"),
      $grade_container = $("#grade_container"),
      $grade = $grade_container.find("input, select"),
      $score = $grade_container.find(".score"),
      $average_score_wrapper = $("#average_score_wrapper"),
      $submission_details = $("#submission_details"),
      $multiple_submissions = $("#multiple_submissions"),
      $submission_late_notice = $("#submission_late_notice"),
      $submission_not_newest_notice = $("#submission_not_newest_notice"),
      $submission_files_container = $("#submission_files_container"),
      $submission_files_list = $("#submission_files_list"),
      $submission_file_hidden = $("#submission_file_hidden").removeAttr('id').detach(),
      $assignment_submission_url = $("#assignment_submission_url"),
      $assignment_submission_turnitin_report_url = $("#assignment_submission_turnitin_report_url"),
      $assignment_submission_resubmit_to_turnitin_url = $("#assignment_submission_resubmit_to_turnitin_url"),
      $rubric_full = $("#rubric_full"),
      $rubric_full_resizer_handle = $("#rubric_full_resizer_handle"),
      $mute_link = $('#mute_link'),
      $no_annotation_warning = $('#no_annotation_warning'),
      $selectmenu = null,
      browserableCssClasses = /^(image|html|code)$/,
      windowLastHeight = null,
      resizeTimeOut = null,
      iframes = {},
      snapshotCache = {},
      sectionToShow,
      header,
      studentLabel = I18n.t("student", "Student"),
      groupLabel = I18n.t("group", "Group"),
      gradeeLabel = studentLabel,
      utils,
      crocodocSessionTimer;

  utils = {
    getParam: function(name){
      var pathRegex = new RegExp(name + '\/([^\/]+)'),
          searchRegex = new RegExp(name + '=([^&]+)'),
          match;

      match = (window.location.pathname.match(pathRegex) || window.location.search.match(searchRegex));
      if (!match) return false;
      return match[1];
    },
    shouldHideStudentNames: function() {
      // this is for backwards compatability, we used to store the value as
      // strings "true" or "false", but now we store boolean true/false values.
      var settingVal = userSettings.get("eg_hide_student_names");
      return settingVal === true || settingVal === "true" || window.anonymousAssignment;
    }
  };

  function mergeStudentsAndSubmission(){
    jsonData.studentsWithSubmissions = jsonData.context.students;
    jsonData.studentMap = {};
    $.each(jsonData.studentsWithSubmissions, function(i, student){
      this.section_ids = $.map($.grep(jsonData.context.enrollments, function(enrollment, i){
          return enrollment.user_id === student.id;
        }), function(enrollment){
        return enrollment.course_section_id;
      });
      this.submission = $.grep(jsonData.submissions, function(submission, i){
        return submission.user_id === student.id;
      })[0];
      $.each(visibleRubricAssessments, function(i, rubricAssessment) {
        rubricAssessment.user_id = rubricAssessment.user_id && String(rubricAssessment.user_id);
        rubricAssessment.assessor_id = rubricAssessment.assessor_id && String(rubricAssessment.assessor_id);
      });
      this.rubric_assessments = $.grep(visibleRubricAssessments, function(rubricAssessment, i){
        return rubricAssessment.user_id === student.id;
      });
      jsonData.studentMap[student.id] = student;
    });

    // handle showing students only in a certain section.
    // the sectionToShow will be remembered for a given user in a given browser across all assignments in this course
    if (!jsonData.GROUP_GRADING_MODE) {
      sectionToShow = userSettings.contextGet('grading_show_only_section');
      sectionToShow = sectionToShow && String(sectionToShow);
    }
    if (sectionToShow) {
      var tempArray  = $.grep(jsonData.studentsWithSubmissions, function(student, i){
        return $.inArray(sectionToShow, student.section_ids) != -1;
      });
      if (tempArray.length) {
        jsonData.studentsWithSubmissions = tempArray;
      } else {
        alert(I18n.t('alerts.no_students_in_section', "Could not find any students in that section, falling back to showing all sections."));
        userSettings.contextRemove('grading_show_only_section');
        window.location.reload();
      }
    }

    //by defaut the list is sorted alphbetically by student last name so we dont have to do any more work here,
    // if the cookie to sort it by submitted_at is set we need to sort by submitted_at.
    var hideStudentNames = utils.shouldHideStudentNames();
    var compareBy = function(f) {
      return function(a, b) {
        a = f(a);
        b = f(b);
        if ((!a && !b) || a === b) { return 0; }
        if (!a || a > b) { return +1; }
        else { return -1; }
      };
    };
    if(hideStudentNames) {
      jsonData.studentsWithSubmissions.sort(compareBy(function(student) {
        return student &&
          student.submission &&
          student.submission.id;
      }));
    } else if (userSettings.get("eg_sort_by") == "submitted_at") {
      jsonData.studentsWithSubmissions.sort(compareBy(function(student){
        return student &&
          student.submission &&
          +tz.parse(student.submission.submitted_at);
      }));
    } else if (userSettings.get("eg_sort_by") == "submission_status") {
      var states = {
        "not_graded": 1,
        "resubmitted": 2,
        "not_submitted": 3,
        "graded": 4
      };
      jsonData.studentsWithSubmissions.sort(compareBy(function(student){
        return student &&
          states[submissionStateName(student.submission)];
      }));
    }
  }

  function submissionStateName(submission) {
    if (submission && submission.workflow_state != 'unsubmitted' && (submission.submitted_at || !(typeof submission.grade == 'undefined'))) {
      if (typeof submission.grade == 'undefined' || submission.grade === null || submission.workflow_state == 'pending_review') {
        return "not_graded";
      } else if (submission.grade_matches_current_submission) {
        return "graded";
      } else {
        return "resubmitted";
      }
    } else {
      return "not_submitted";
    }
  }

  function formattedSubmissionStateName(raw, submission) {
    switch(raw) {
      case "graded":
        return I18n.t('graded', "graded");
      case "not_graded":
        return I18n.t('not_graded', "not graded");
      case "not_submitted":
        return I18n.t('not_submitted', 'not submitted');
      case "resubmitted":
        return I18n.t('graded_then_resubmitted', "graded, then resubmitted (%{when})", {'when': $.datetimeString(submission.submitted_at)});
    }
  }

  function classNameBasedOnStudent(student){
    var raw = submissionStateName(student.submission);
    var formatted = formattedSubmissionStateName(raw, student.submission);
    return {raw: raw, formatted: formatted};
  }

  var MENU_PARTS_DELIMITER = '----☃----'; // something random and unlikely to be in a person's name

  function initDropdown(){
    var hideStudentNames = utils.shouldHideStudentNames();
    $("#hide_student_names").attr('checked', hideStudentNames);
    var options = $.map(jsonData.studentsWithSubmissions, function(s, idx){
      var name = htmlEscape(s.name).replace(MENU_PARTS_DELIMITER, ""),
          className = classNameBasedOnStudent(s);

      if(hideStudentNames) {
        name = I18n.t('nth_student', "Student %{n}", {'n': idx + 1});
      }

      return '<option value="' + s.id + '" class="' + className.raw + ' ui-selectmenu-hasIcon">' + name + MENU_PARTS_DELIMITER + className.formatted + MENU_PARTS_DELIMITER + className.raw + '</option>';
    }).join("");

    $selectmenu = $("<select id='students_selectmenu'>" + options + "</select>")
      .appendTo("#combo_box_container")
      .selectmenu({
        style:'dropdown',
        format: function(text){
          var parts = text.split(MENU_PARTS_DELIMITER);
          return getIcon(parts[2]) + '<span class="ui-selectmenu-item-header">' + htmlEscape(parts[0]) + '</span><span class="ui-selectmenu-item-footer">' + htmlEscape(parts[1]) + '</span>';
        }
      }).change(function(e){
        EG.handleStudentChanged();
      });

    function getIcon(helper_text){
      var icon = "<span class='ui-selectmenu-item-icon speedgrader-selectmenu-icon'>";
      if(helper_text == "graded"){
        icon += "<i class='icon-check'></i>";
      }else if(["not_graded", "resubmitted"].indexOf(helper_text) != -1){
        icon += "&#9679;";
      }
      return icon.concat("</span>");
    }

    if (jsonData.context.active_course_sections.length && jsonData.context.active_course_sections.length > 1 && !jsonData.GROUP_GRADING_MODE) {
      var $selectmenu_list = $selectmenu.data('selectmenu').list,
          $menu = $("#section-menu");


      $menu.find('ul').append($.map(jsonData.context.active_course_sections, function(section, i){
        return '<li><a class="section_' + section.id + '" data-section-id="'+ section.id +'" href="#">'+ htmlEscape(section.name) +'</a></li>';
      }).join(''));

      $menu.insertBefore($selectmenu_list).bind('mouseenter mouseleave', function(event){
        $(this)
          .toggleClass('ui-selectmenu-item-selected ui-selectmenu-item-focus ui-state-hover', event.type == 'mouseenter')
          .find('ul').toggle(event.type == 'mouseenter');
      })
      .find('ul')
        .hide()
        .menu()
        .delegate('a', 'click mousedown', function(){
          userSettings[$(this).data('section-id') == 'all' ? 'contextRemove' : 'contextSet']('grading_show_only_section', $(this).data('section-id'));
          window.location.reload();
        });

      if (sectionToShow) {
        var text = $.map(jsonData.context.active_course_sections, function(section){
                      if (section.id == sectionToShow) { return section.name; }
                   }).join(', ');

        $("#section_currently_showing").text(text);
        $menu.find('ul li a')
          .removeClass('selected')
          .filter('[data-section-id='+ sectionToShow +']')
            .addClass('selected');
      }

      $selectmenu.selectmenu( 'option', 'open', function(){
        $selectmenu_list.find('li:first').css('margin-top', $selectmenu_list.find('li').height() + 'px');
        $menu.show().css({
          'left'   : $selectmenu_list.css('left'),
          'top'    : $selectmenu_list.css('top'),
          'width'  : $selectmenu_list.width() - ($selectmenu_list.hasScrollbar() && $.getScrollbarWidth()),
          'z-index': Number($selectmenu_list.css('z-index')) + 1
        });

      }).selectmenu( 'option', 'close', function(){
        $menu.hide();
      });
    }
  }

  header = {
    elements: {
      mute: {
        icon: $('#mute_link .ui-icon'),
        label: $('#mute_link .mute_label'),
        link: $('#mute_link'),
        modal: $('#mute_dialog')
      },
      nav: $gradebook_header.find('.prev, .next'),
      spinner: new Spinner({
        length: 2,
        radius: 3,
        trail: 25,
        width: 1
      }),
      settings: {
        form: $('#settings_form'),
        link: $('#settings_link')
      }
    },
    courseId: utils.getParam('courses'),
    assignmentId: utils.getParam('assignment_id'),
    init: function(){
      this.muted = this.elements.mute.link.data('muted');
      this.addEvents();
      this.createModals();
      this.addSpinner();
      return this;
    },
    addEvents: function(){
      this.elements.nav.click($.proxy(this.toAssignment, this));
      this.elements.mute.link.click($.proxy(this.onMuteClick, this));
      this.elements.settings.form.submit(this.submitSettingsForm.bind(this));
      this.elements.settings.link.click(this.showSettingsModal.bind(this));
    },
    addSpinner: function(){
      this.elements.mute.link.append(this.elements.spinner.el);
    },
    createModals: function(){
      this.elements.settings.form.dialog({
        autoOpen: false,
        modal: true,
        resizable: false,
        width: 400
      }).fixDialogButtons();
      // FF hack - when reloading the page, firefox seems to "remember" the disabled state of this
      // button. So here we'll manually re-enable it.
      this.elements.settings.form.find(".submit_button").removeAttr('disabled')
      this.elements.mute.modal.dialog({
        autoOpen: false,
        buttons: [{
          text: I18n.t('cancel_button', 'Cancel'),
          click: $.proxy(function(){
            this.elements.mute.modal.dialog('close');
          }, this)
        },{
          text: I18n.t('mute_assignment', 'Mute Assignment'),
          'class': 'btn-primary',
          click: $.proxy(function(){
            this.toggleMute();
            this.elements.mute.modal.dialog('close');
          }, this)
        }],
        modal: true,
        resizable: false,
        title: this.elements.mute.modal.data('title'),
        width: 400
      });
    },

    toAssignment: function(e){
      e.preventDefault();
      EG[e.target.getAttribute('class')]();
    },

    submitSettingsForm: function(e){
      e.preventDefault();
      userSettings.set('eg_sort_by', $('#eg_sort_by').val());
      userSettings.set('eg_hide_student_names', $("#hide_student_names").prop('checked'));
      $(e.target).find(".submit_button").attr('disabled', true).text(I18n.t('buttons.saving_settings', "Saving Settings..."));
      var gradeByQuestion = $("#enable_speedgrader_grade_by_question").prop('checked');
      $.post(ENV.settings_url, {
        enable_speedgrader_grade_by_question: gradeByQuestion
      }).then(function() {
        window.location.reload();
      });
    },

    showSettingsModal: function(e){
      e.preventDefault();
      this.elements.settings.form.dialog('open');
    },

    onMuteClick: function(e){
      e.preventDefault();
      this.muted ? this.toggleMute() : this.elements.mute.modal.dialog('open');
    },

    muteUrl: function(){
      return '/courses/' + this.courseId + '/assignments/' + this.assignmentId + '/mute';
    },

    spinMute: function(){
      this.elements.spinner.spin();
      $(this.elements.spinner.el)
        .css({ left: 9, top: 6})
        .appendTo(this.elements.mute.link);
    },

    toggleMute: function(){
      this.muted = !this.muted;
      var label = this.muted ? I18n.t('unmute_assignment', 'Unmute Assignment') : I18n.t('mute_assignment', 'Mute Assignment'),
          action = this.muted ? 'mute' : 'unmute',
          actions = {
        /* Mute action */
        mute: function(){
          this.elements.mute.icon.css('visibility', 'hidden');
          this.spinMute();
          $.ajaxJSON(this.muteUrl(), 'put', { status: true }, $.proxy(function(res){
            this.elements.spinner.stop();
            this.elements.mute.label.html(label);
            this.elements.mute.icon
              .removeClass('ui-icon-volume-off')
              .addClass('ui-icon-volume-on')
              .css('visibility', 'visible');
          }, this));
        },

        /* Unmute action */
        unmute: function(){
          this.elements.mute.icon.css('visibility', 'hidden');
          this.spinMute();
          $.ajaxJSON(this.muteUrl(), 'put', { status: false }, $.proxy(function(res){
            this.elements.spinner.stop();
            this.elements.mute.label.html(label);
            this.elements.mute.icon
              .removeClass('ui-icon-volume-on')
              .addClass('ui-icon-volume-off')
              .css('visibility', 'visible');
          }, this));
        }
      };

      actions[action].apply(this);
    }
  };

  function initCommentBox(){
    //initialize the auto height resizing on the textarea
    $('#add_a_comment textarea').elastic({
      callback: EG.resizeFullHeight
    });

    $(".media_comment_link").click(function(event) {
      event.preventDefault();
      $("#media_media_recording").show().find(".media_recording").mediaComment('create', 'any', function(id, type) {
        $("#media_media_recording").data('comment_id', id).data('comment_type', type);
        EG.handleCommentFormSubmit();
      }, function() {
        EG.revertFromFormSubmit();
      }, true);
      EG.resizeFullHeight();
    });

    $("#media_recorder_container a").live('click', hideMediaRecorderContainer);

    // handle speech to text for browsers that can (right now only chrome)
    function browserSupportsSpeech(){
      var elem = document.createElement('input');
      // chrome 10 advertises support but it LIES!!! doesn't work till chrome 11
      var support = ('onwebkitspeechchange' in elem || 'speech' in elem) && !navigator.appVersion.match(/Chrome\/10/);
      return support;
    }
    if (browserSupportsSpeech()) {
      $(".speech_recognition_link").click(function() {
          $('<input style="font-size: 30px;" speech x-webkit-speech />')
            .dialog({
              title: I18n.t('titles.click_to_record', "Click the mic to record your comments"),
              open: function(){
                $(this).width(100);
              }
            })
            .bind('webkitspeechchange', function(){
              $add_a_comment_textarea.val($(this).val());
              $(this).dialog('close').remove();
            });
          return false;
        })
        // show the li that contains the button because it is hidden from browsers that dont support speech
        .closest('li').show();
    }
  }

  function hideMediaRecorderContainer(){
    $("#media_media_recording").hide().removeData('comment_id').removeData('comment_type');
    EG.resizeFullHeight();
  }

  function isAssessmentEditableByMe(assessment){
    //if the assessment is mine or I can :manage_course then it is editable
    if (!assessment || assessment.assessor_id === ENV.RUBRIC_ASSESSMENT.assessor_id ||
         (ENV.RUBRIC_ASSESSMENT.assessment_type == 'grading' && assessment.assessment_type == 'grading')
       ){
          return true;
    }
    return false;
  }

  function getSelectedAssessment(){
    return $.grep(EG.currentStudent.rubric_assessments, function(n,i){
      return n.id == $rubric_assessments_select.val();
    })[0];
  }

  function initRubricStuff(){

    $("#rubric_summary_container .button-container").appendTo("#rubric_assessments_list_and_edit_button_holder").find('.edit').text(I18n.t('edit_view_rubric', "View Rubric"));

    $(".toggle_full_rubric, .hide_rubric_link").click(function(e){
      e.preventDefault();
      EG.toggleFullRubric();
    });

    $rubric_assessments_select.change(function(){
      var selectedAssessment = getSelectedAssessment();
      rubricAssessment.populateRubricSummary($("#rubric_summary_holder .rubric_summary"), selectedAssessment, isAssessmentEditableByMe(selectedAssessment));
      EG.resizeFullHeight();
    });

    $rubric_full_resizer_handle.draggable({
      axis: 'x',
      cursor: 'crosshair',
      scroll: false,
      containment: '#left_side',
      snap: '#full_width_container',
      appendTo: '#full_width_container',
      start: function(){
        $rubric_full_resizer_handle.draggable( 'option', 'minWidth', $right_side.width() );
      },
      helper: function(){
        return $rubric_full_resizer_handle.clone().addClass('clone');
      },
      drag: function(event, ui) {
        var offset = ui.offset,
            windowWidth = $window.width();
        $rubric_full.width(windowWidth - offset.left);
        $rubric_full_resizer_handle.css("left","0");
        EG.resizeFullHeight();
      },
      stop: function(event, ui) {
        event.stopImmediatePropagation();
      }
    });

    $(".save_rubric_button").click(function() {
      var $rubric = $(this).parents("#rubric_holder").find(".rubric");
      var data = rubricAssessment.assessmentData($rubric);
      var url = $(".update_rubric_assessment_url").attr('href');
      var method = "POST";
      EG.toggleFullRubric();
      $(".rubric_summary").loadingImage();
      $.ajaxJSON(url, method, data, function(response) {
        var found = false;
        if(response && response.rubric_association) {
          rubricAssessment.updateRubricAssociation($rubric, response.rubric_association);
          delete response.rubric_association;
        }
        for (var i in EG.currentStudent.rubric_assessments) {
          if (response.id === EG.currentStudent.rubric_assessments[i].id) {
            $.extend(true, EG.currentStudent.rubric_assessments[i], response);
            found = true;
            continue;
          }
        }
        if (!found) {
          EG.currentStudent.rubric_assessments.push(response);
        }

        // if this student has a submission, update it with the data returned, otherwise we need to create a submission for them
        EG.setOrUpdateSubmission(response.artifact);

        // this next part will take care of group submissions, so that when one member of the group gets assessesed then everyone in the group will get that same assessment.
        $.each(response.related_group_submissions_and_assessments, function(i,submissionAndAssessment){
          //setOrUpdateSubmission returns the student. so we can set student.rubric_assesments
          // submissionAndAssessment comes back with :include_root => true, so we have to get rid of the root
          var student = EG.setOrUpdateSubmission(response.artifact);
          student.rubric_assessments = $.map(submissionAndAssessment.rubric_assessments, function(ra){return ra.rubric_assessment;});
        });

        $(".rubric_summary").loadingImage('remove');
        EG.showGrade();
    	  EG.showDiscussion();
    	  EG.showRubric();
    	  EG.updateStatsInHeader();
      });
    });
  }

  function initKeyCodes(){
    $window.keycodes({keyCodes: "j k p n c r g", ignore: 'input, textarea, embed, object'}, function(event) {
      event.preventDefault();
      event.stopPropagation();

      //Prev()
      if(event.keyString == "j" || event.keyString == "p") {
        EG.prev();
      }
      //next()
      else if(event.keyString == "k" || event.keyString == "n") {
        EG.next();
      }
      //comment
      else if(event.keyString == "f" || event.keyString == "c") {
        $add_a_comment_textarea.focus();
      }
      // focus on grade
      else if(event.keyString == "g") {
        $grade.focus();
      }
      // focus on rubric
      else if(event.keyString == "r") {
        EG.toggleFullRubric();
      }
    });
  }

  function initGroupAssignmentMode() {
    if (jsonData.GROUP_GRADING_MODE) {
      gradeeLabel = groupLabel;
      disableGroupCommentCheckbox();
    }
  }

  function disableGroupCommentCheckbox() {
    $("#submission_group_comment").prop({checked: true, disabled: true});
  }

  function resizingFunction(){
    var windowHeight = $window.height(),
        delta,
        deltaRemaining,
        headerOffset = $right_side.offset().top,
        fixedBottomHeight = $fixed_bottom.height(),
        fullHeight = Math.max(minimumWindowHeight, windowHeight) - headerOffset - fixedBottomHeight,
        resizableElements = [
          { element: $submission_files_list,    data: { newHeight: 0 } },
          { element: $rubric_summary_container, data: { newHeight: 0 } },
          { element: $comments,                 data: { newHeight: 0 } }
        ],
        visibleResizableElements = $.grep(resizableElements, function(e, i){
          return e && e.element.is(':visible');
        });
    $rubric_full.css({ 'maxHeight': fullHeight - 50, 'overflow': 'auto' });

    $.each(visibleResizableElements, function(){
      this.data.autoHeight = this.element.height("auto").height();
      this.element.height(0);
    });

    var spaceLeftForResizables = fullHeight - $rightside_inner.height("auto").height() - $add_a_comment.outerHeight();

    $full_height.height(fullHeight);
    delta = deltaRemaining = spaceLeftForResizables;
    var step = 1;
    var didNothing;
    if (delta > 0) { //the page got bigger
      while(deltaRemaining > 0){
        didNothing = true;
        var shortestElementHeight = 10000000;
        var shortestElement = null;
        $.each(visibleResizableElements, function(){
          if (this.data.newHeight < shortestElementHeight && this.data.newHeight < this.data.autoHeight) {
            shortestElement = this;
            shortestElementHeight = this.data.newHeight;
          }
        });
        if (shortestElement) {
          shortestElement.data.newHeight = shortestElementHeight + step;
          deltaRemaining = deltaRemaining - step;
          didNothing = false;
        }
        if (didNothing) {
          break;
        }
      }
    }
    else { //the page got smaller
      var tallestElementHeight, tallestElement;
      while(deltaRemaining < 0){
        didNothing = true;
        tallestElementHeight = 0;
        tallestElement = null;
        $.each(visibleResizableElements, function(){
          if (this.data.newHeight > 30 > tallestElementHeight && this.data.newHeight >= this.data.autoHeight ) {
            tallestElement = this;
            tallestElementHeight = this.data.newHeight;
          }
        });
        if (tallestElement) {
          tallestElement.data.newHeight = tallestElementHeight - step;
          deltaRemaining = deltaRemaining + step;
          didNothing = false;
        }
        if (didNothing) {
          break;
        }
      }
    }

    $.each(visibleResizableElements, function(){
      this.element.height(this.data.newHeight);
    });

    if (deltaRemaining > 0) {
      $comments.height( windowHeight - Math.floor($comments.offset().top) - $add_a_comment.outerHeight() );
    }
    // This will cause the page to flicker in firefox if there is a scrollbar in both the comments and the rubric summary.
    // I would like it not to, I tried setTimeout(function(){ $comments.scrollTop(1000000); }, 800); but that still doesnt work
    if(!INST.browser.ff && $comments.height() > 100) {
      $comments.scrollTop(1000000);
    }
  }

  $.extend(INST, {
    refreshGrades: function(){
      var url = unescape($assignment_submission_url.attr('href')).replace("{{submission_id}}", EG.currentStudent.submission.user_id) + ".json";
      $.getJSON( url,
        function(data){
          EG.currentStudent.submission = data.submission;
          EG.showGrade();
      });
    },
    refreshQuizSubmissionSnapshot: function(data) {
      snapshotCache[data.user_id + "_" + data.version_number] = data;
      if(data.last_question_touched) {
        INST.lastQuestionTouched = data.last_question_touched;
      }
    },
    clearQuizSubmissionSnapshot: function(data) {
      snapshotCache[data.user_id + "_" + data.version_number] = null;
    },
    getQuizSubmissionSnapshot: function(user_id, version_number) {
      return snapshotCache[user_id + "_" + version_number];
    }
  });

  window.onbeforeunload = function() {
    window.opener && window.opener.updateGrades && $.isFunction(window.opener.updateGrades) && window.opener.updateGrades();

    var userNamesWithPendingQuizSubmission = $.map(snapshotCache, function(snapshot) {
      return snapshot && $.map(jsonData.context.students, function(student) {
        return (snapshot == student) && student.name;
      })[0];
    })
      hasPendingQuizSubmissions = (function(){
        var ret = false;
        if (userNamesWithPendingQuizSubmission.length){
          for (var i = 0, max = userNamesWithPendingQuizSubmission.length; i < max; i++){
            if (userNamesWithPendingQuizSubmission[i] !== false) { ret = true; }
          }
        }
        return ret;
      })();
    if (hasPendingQuizSubmissions) {
      return I18n.t('confirms.unsaved_changes', "The following students have unsaved changes to their quiz submissions: \n\n %{users}\nContinue anyway?", {'users': userNamesWithPendingQuizSubmission.join('\n ')});
    }
  };

  // Public Variables and Methods
  var EG = {
    options: {},
    publicVariable: [],
    scribdDoc: null,
    currentStudent: null,

    domReady: function(){
      //attach to window resize and
      $window.bind('resize orientationchange', EG.resizeFullHeight).resize();

      function makeFullWidth(){
        $full_width_container.addClass("full_width");
        $left_side.css("width",'');
        $right_side.css("width",'');
      }
      $(document).mouseup(function(event){
        $resize_overlay.hide();
      });
      // it should disappear before it's clickable, but just in case...
      $resize_overlay.click(function(event){
        $(this).hide();
      });
      $width_resizer.mousedown(function(event){
        $resize_overlay.show();
      }).draggable({
        axis: 'x',
        cursor: 'crosshair',
        scroll: false,
        containment: '#full_width_container',
        snap: '#full_width_container',
        appendTo: '#full_width_container',
        helper: function(){
          return $width_resizer.clone().addClass('clone');
        },
        snapTolerance: 200,
        drag: function(event, ui) {
          var offset = ui.offset,
              windowWidth = $window.width();
          $left_side.width(offset.left / windowWidth * 100 + "%" );
          $right_side.width(100 - offset.left / windowWidth  * 100 + '%' );
          $width_resizer.css("left","0");
          if (windowWidth - offset.left < $(this).draggable('option', 'snapTolerance') ) {
            makeFullWidth();
          }
          else {
            $full_width_container.removeClass("full_width");
          }
          if (offset.left < $(this).draggable('option', 'snapTolerance')) {
            $left_side.width("0%" );
            $right_side.width('100%');
          }
          EG.resizeFullHeight();
        },
        stop: function(event, ui) {
          event.stopImmediatePropagation();
          $resize_overlay.hide();
        }
      }).click(function(event){
          event.preventDefault();
          if ($full_width_container.hasClass("full_width")) {
            $full_width_container.removeClass("full_width");
          }
          else {
            makeFullWidth();
            $(this).addClass('highlight', 100, function(){
              $(this).removeClass('highlight', 4000);
            });
          }
      });

      $grade.change(EG.handleGradeSubmit);

      $multiple_submissions.change(function(e) {
        if (typeof EG.currentStudent.submission == 'undefined') EG.currentStudent.submission = {};
        var i = $("#submission_to_view").val() ||
                EG.currentStudent.submission.submission_history.length - 1;
        EG.currentStudent.submission.currentSelectedIndex = parseInt(i, 10);
        EG.handleSubmissionSelectionChange();
      });

      initRubricStuff();
      initCommentBox();
      EG.initComments();
      header.init();
      initKeyCodes();

      $('#hide_no_annotation_warning').click(function(e){
        e.preventDefault();
        $no_annotation_warning.hide();
      });

      $window.bind('hashchange', EG.handleFragmentChange);
      $('#eg_sort_by').val(userSettings.get('eg_sort_by'));
      $('#submit_same_score').click(function(e) {
        EG.handleGradeSubmit();
        e.preventDefault();
      });

    },

    jsonReady: function(){
      //this runs after the request to get the jsonData comes back

      mergeStudentsAndSubmission();
      if (jsonData.GROUP_GRADING_MODE && !jsonData.studentsWithSubmissions.length) {
        if (window.history.length === 1) {
          alert(I18n.t('alerts.no_students_in_groups_close', "Sorry, submissions for this assignment cannot be graded in Speedgrader because there are no assigned users. Please assign users to this group set and try again. Click 'OK' to close this window."))
          window.close();
        }
        else {
          alert(I18n.t('alerts.no_students_in_groups_back', "Sorry, submissions for this assignment cannot be graded in Speedgrader because there are no assigned users. Please assign users to this group set and try again. Click 'OK' to go back."))
          window.history.back();
        }
      }
      else if (!jsonData.studentsWithSubmissions.length) {
        alert(I18n.t('alerts.no_active_students', "Sorry, there are either no active students in the course or none are gradable by you."))
        window.history.back();
      } else {
        $("#speed_grader_loading").hide();
        $("#gradebook_header, #full_width_container").show();
        initDropdown();
        initGroupAssignmentMode();
        EG.handleFragmentChange();
      }
    },

    skipRelativeToCurrentIndex: function(offset){
      var newIndex = (this.currentIndex() + offset+ jsonData.studentsWithSubmissions.length) % jsonData.studentsWithSubmissions.length;
      this.goToStudent(jsonData.studentsWithSubmissions[newIndex].id);
    },

    next: function(){
      this.skipRelativeToCurrentIndex(1);
    },

    prev: function(){
      this.skipRelativeToCurrentIndex(-1);
    },

    resizeFullHeight: function(){
      if (resizeTimeOut) {
        clearTimeout(resizeTimeOut);
      }
      resizeTimeOut = setTimeout(resizingFunction, 0);
    },

    toggleFullRubric: function(force){
      // if there is no rubric associated with this assignment, then the edit
      // rubric thing should never be shown.  the view should make sure that
      // the edit rubric html is not even there but we also want to make sure
      // that pressing "r" wont make it appear either
      if (!jsonData.rubric_association){ return false; }

      if ($rubric_full.filter(":visible").length || force === "close") {
        $("#grading").height("auto").children().show();
        $rubric_full.fadeOut();
        this.resizeFullHeight();
        $(".toggle_full_rubric").focus()
      } else {
        $rubric_full.fadeIn();
        $("#grading").children().hide();
        this.refreshFullRubric();
        $rubric_full.find('.rubric_title .title').focus()
      }
    },

    refreshFullRubric: function() {
      if (!jsonData.rubric_association) { return; }
      if (!$rubric_full.filter(":visible").length) { return; }

      rubricAssessment.populateRubric($rubric_full.find(".rubric"), getSelectedAssessment() );
      $("#grading").height($rubric_full.height());
      this.resizeFullHeight();
    },

    handleFragmentChange: function(){
      var hash;
      try {
        hash = JSON.parse(decodeURIComponent(document.location.hash.substr(1))); //get rid of the first charicter "#" of the hash
      } catch(e) {}
      if (!hash) {
        hash = {};
      }

      // use the group representative if possible
      var studentId = jsonData.context.rep_for_student[hash.student_id] ||
                      hash.student_id;

      // choose the first ungraded student if the requested one doesn't exist
      if (!jsonData.studentMap[studentId]) {
        var ungradedStudent = _(jsonData.studentsWithSubmissions)
        .find(function(s) {
          return s.submission &&
                 s.submission.workflow_state != 'graded' &&
                 s.submission.submission_type;
        });
        studentId = (ungradedStudent || jsonData.studentsWithSubmissions[0]).id;
      }

      EG.goToStudent(studentId);
    },

    goToStudent: function(student_id){
      var hideStudentNames = utils.shouldHideStudentNames();
      var student = jsonData.studentMap[student_id];

      if (student) {
        $selectmenu.selectmenu("value", student.id);
        //this is lame but I have to manually tell $selectmenu to fire its 'change' event if has changed.
        if (!this.currentStudent || (this.currentStudent.id != student.id)) {
          $selectmenu.change();
        }
        if (student.avatar_path && !hideStudentNames) {
          // If there's any kind of delay in loading the user's avatar, it's
          // better to show a blank image than the previous student's image.
          $new_image = $avatar_image.clone().show();
          $avatar_image.after($new_image.attr('src', student.avatar_path)).remove();
          $avatar_image = $new_image;
        } else {
          $avatar_image.hide();
        }
      }
    },

    currentIndex: function(){
      return $.inArray(this.currentStudent, jsonData.studentsWithSubmissions);
    },

    handleStudentChanged: function(){
      var id = $selectmenu.val();
      this.currentStudent = jsonData.studentMap[id] || _.values(jsonData.studentsWithSubmissions)[0];
      document.location.hash = "#" + encodeURIComponent(JSON.stringify({
        "student_id": this.currentStudent.id
      }));

      this.showGrade();
      this.showDiscussion();
      this.showRubric();
      this.updateStatsInHeader();
      this.showSubmissionDetails();
      this.refreshFullRubric();
    },

    populateTurnitin: function(submission, assetString, turnitinAsset, $turnitinScoreContainer, $turnitinInfoContainer, isMostRecent) {
      var $turnitinSimilarityScore = null;

      // build up new values based on this asset
      if (turnitinAsset.status == 'scored' || (turnitinAsset.status == null && turnitinAsset.similarity_score != null)) {
        $turnitinScoreContainer.html(turnitinScoreTemplate({
          state: (turnitinAsset.state || 'no') + '_score',
          reportUrl: $.replaceTags($assignment_submission_turnitin_report_url.attr('href'), { user_id: submission.user_id, asset_string: assetString }),
          tooltip: I18n.t('turnitin.tooltip.score', 'Turnitin Similarity Score - See detailed report'),
          score: turnitinAsset.similarity_score + '%'
        }));
      } else if (turnitinAsset.status) {
        // status == 'error' or status == 'pending'
        var pendingTooltip = I18n.t('turnitin.tooltip.pending', 'Turnitin Similarity Score - Submission pending'),
            errorTooltip = I18n.t('turnitin.tooltip.error', 'Turnitin Similarity Score - See submission error details');
        $turnitinSimilarityScore = $(turnitinScoreTemplate({
          state: 'submission_' + turnitinAsset.status,
          reportUrl: '#',
          tooltip: (turnitinAsset.status == 'error' ? errorTooltip : pendingTooltip),
          icon: '/images/turnitin_submission_' + turnitinAsset.status + '.png'
        }));
        $turnitinScoreContainer.append($turnitinSimilarityScore);
        $turnitinSimilarityScore.click(function(event) {
          event.preventDefault();
          $turnitinInfoContainer.find('.turnitin_'+assetString).slideToggle();
        });

        var defaultInfoMessage = I18n.t('turnitin.info_message',
                                        'This file is still being processed by turnitin. Please check back later to see the score'),
            defaultErrorMessage = I18n.t('turnitin.error_message',
                                         'There was an error submitting to turnitin. Please try resubmitting the file before contacting support');
        var $turnitinInfo = $(turnitinInfoTemplate({
          assetString: assetString,
          message: (turnitinAsset.status == 'error' ? (turnitinAsset.public_error_message || defaultErrorMessage) : defaultInfoMessage),
          showResubmit: turnitinAsset.status == 'error' && isMostRecent
        }));
        $turnitinInfoContainer.append($turnitinInfo);

        if (turnitinAsset.status == 'error' && isMostRecent) {
          var resubmitUrl = $.replaceTags($assignment_submission_resubmit_to_turnitin_url.attr('href'), { user_id: submission.user_id });
          $turnitinInfo.find('.turnitin_resubmit_button').click(function(event) {
            event.preventDefault();
            $(this).attr('disabled', true)
              .text(I18n.t('turnitin.resubmitting', 'Resubmitting...'));

            $.ajaxJSON(resubmitUrl, "POST", {}, function() {
              window.location.reload();
            });
          });
        }
      }
    },

    handleSubmissionSelectionChange: function(){
      clearInterval(crocodocSessionTimer);
      try {
        var $submission_to_view = $("#submission_to_view");
        var submissionToViewVal = $submission_to_view.val(),
            currentSelectedIndex = Number(submissionToViewVal) ||
                                  ( this.currentStudent &&
                                    this.currentStudent.submission &&
                                    this.currentStudent.submission.currentSelectedIndex )
                                  || 0,
            isMostRecent = this.currentStudent &&
                           this.currentStudent.submission &&
                           this.currentStudent.submission.submission_history &&
                           this.currentStudent.submission.submission_history.length - 1 === currentSelectedIndex,
            submission  = this.currentStudent &&
                          this.currentStudent.submission &&
                          this.currentStudent.submission.submission_history &&
                          this.currentStudent.submission.submission_history[currentSelectedIndex] &&
                          this.currentStudent.submission.submission_history[currentSelectedIndex].submission
                          || {},
            inlineableAttachments = [],
            browserableAttachments = [];

        var $turnitinScoreContainer = $grade_container.find(".turnitin_score_container").empty(),
            $turnitinInfoContainer = $grade_container.find(".turnitin_info_container").empty(),
            assetString = 'submission_' + submission.id,
            turnitinAsset = submission.turnitin_data && submission.turnitin_data[assetString];
        // There might be a previous submission that was text_entry, but the
        // current submission is an upload. The turnitin asset for the text
        // entry would still exist
        if (turnitinAsset && submission.submission_type == 'online_text_entry') {
          EG.populateTurnitin(submission, assetString, turnitinAsset, $turnitinScoreContainer, $turnitinInfoContainer, isMostRecent);
        }

        //handle the files
        $submission_files_list.empty();
        $turnitinInfoContainer = $("#submission_files_container .turnitin_info_container").empty();
        $.each(submission.versioned_attachments || [], function(i,a){
          var attachment = a.attachment;
          if (attachment.crocodoc_url ||
              attachment.canvadoc_url ||
              (attachment.scribd_doc && attachment.scribd_doc.created) ||
              $.isPreviewable(attachment.content_type, 'google')) {
            inlineableAttachments.push(attachment);
          }
          if (browserableCssClasses.test(attachment.mime_class)) {
            browserableAttachments.push(attachment);
          }
          $submission_file = $submission_file_hidden.clone(true).fillTemplateData({
            data: {
              submissionId: submission.user_id,
              attachmentId: attachment.id,
              display_name: attachment.display_name
            },
            hrefValues: ['submissionId', 'attachmentId']
          }).appendTo($submission_files_list)
            .find('a.display_name')
              .addClass(attachment.mime_class)
              .data('attachment', attachment)
              .click(function(event){
                event.preventDefault();
                EG.loadAttachmentInline($(this).data('attachment'));
              })
            .end()
            .find('a.submission-file-download')
              .bind('dragstart', function(event){
                // check that event dataTransfer exists
                event.originalEvent.dataTransfer &&
                // handle dragging out of the browser window only if it is supported.
                event.originalEvent.dataTransfer.setData('DownloadURL', attachment.content_type + ':' + attachment.filename + ':' + this.href);
              })
            .end()
            .show();
          $turnitinScoreContainer = $submission_file.find(".turnitin_score_container");
          assetString = 'attachment_' + attachment.id;
          turnitinAsset = submission.turnitin_data && submission.turnitin_data[assetString];
          if (turnitinAsset) {
            EG.populateTurnitin(submission, assetString, turnitinAsset, $turnitinScoreContainer, $turnitinInfoContainer, isMostRecent);
          }
        });

        $submission_files_container.showIf(submission.versioned_attachments && submission.versioned_attachments.length);

        // load up a preview of one of the attachments if we can.
        // do it in this order:
        // show the first scridbable doc if there is one
        // then show the first image if there is one,
        // if not load the generic thing for the current submission (by not passing a value)
        this.loadAttachmentInline(inlineableAttachments[0] || browserableAttachments[0]);

        // if there is any submissions after this one, show a notice that they are not looking at the newest
        $submission_not_newest_notice.showIf($submission_to_view.filter(":visible").find(":selected").nextAll().length);

        // if the submission was after the due date, mark it as late
        this.resizeFullHeight();
        $submission_late_notice.showIf(submission['late']);
      } catch(e) {
        INST.log_error({
          'message': "SG_submissions_" + (e.message || e.description || ""),
          'line': e.lineNumber || ''
        });
        throw e;
      }
    },

    refreshSubmissionsToView: function(){
      var innerHTML = "";
      var s = this.currentStudent.submission;
      var submissionHistory = s.submission_history;

      if (submissionHistory.length > 0) {
        var noSubmittedAt = I18n.t('no_submission_time', 'no submission time');
        var selectedIndex = parseInt($("#submission_to_view").val() ||
                                       submissionHistory.length - 1,
                                     10);
        var templateSubmissions = _(submissionHistory).map(function(o, i) {
          var s = o.submission;
          if (s.grade && (s.grade_matches_current_submission ||
                          s.show_grade_in_dropdown)) {
            var grade = s.grade;
          }
          return {
            value: s.version || i,
            late: s.late,
            selected: selectedIndex === i,
            submittedAt: $.datetimeString(s.submitted_at) || noSubmittedAt,
            grade: grade
          };
        });

        innerHTML = submissionsDropdownTemplate({
          singleSubmission: submissionHistory.length == 1,
          submissions: templateSubmissions,
          linkToQuizHistory: jsonData.too_many_quiz_submissions,
          quizHistoryHref: $.replaceTags(ENV.quiz_history_url,
                                         {user_id: this.currentStudent.id})
        });
      }
      $multiple_submissions.html(innerHTML);
    },

    showSubmissionDetails: function(){
      //if there is a submission
      if (this.currentStudent.submission && this.currentStudent.submission.submitted_at) {
        this.refreshSubmissionsToView();
        $submission_details.show();
      }
      else { //there's no submission
        $submission_details.hide();
      }
      this.handleSubmissionSelectionChange();
    },

    updateStatsInHeader: function(){
      $x_of_x_students.html(
        I18n.t('gradee_index_of_total', '%{gradee} %{x} of %{y}', {
          gradee: gradeeLabel,
          x: EG.currentIndex() + 1,
          y: jsonData.context.students.length
        })
      );

      var gradedStudents = $.grep(jsonData.studentsWithSubmissions, function(s) {
        return (s.submission &&
                s.submission.workflow_state === 'graded' &&
                s.submission.from_enrollment_type === "StudentEnrollment"
        );
      });

      var scores = $.map(gradedStudents , function(s){
        return s.submission.score;
      });

      if (scores.length) { //if there are some submissions that have been graded.
        $average_score_wrapper.show();
        function avg(arr) {
          var sum = 0;
          for (var i = 0, j = arr.length; i < j; i++) {
            sum += arr[i];
          }
          return sum / arr.length;
        }
        function roundWithPrecision(number, precision) {
          precision = Math.abs(parseInt(precision, 10)) || 0;
          var coefficient = Math.pow(10, precision);
          return Math.round(number*coefficient)/coefficient;
        }
        var outOf = jsonData.points_possible ? ([" / ", jsonData.points_possible, " (", Math.round( 100 * (avg(scores) / jsonData.points_possible)), "%)"].join("")) : "";
        $average_score.html( [roundWithPrecision(avg(scores), 2) + outOf].join("") );
      }
      else { //there are no submissions that have been graded.
        $average_score_wrapper.hide();
      }

      $grded_so_far.html(
        I18n.t('portion_graded', '%{x} / %{y} Graded', {
          x: gradedStudents.length,
          y: jsonData.context.students.length
        })
      );
    },

    loadAttachmentInline: function(attachment){
      clearInterval(crocodocSessionTimer);
      $submissions_container.children().hide();
      $no_annotation_warning.hide();
      if (!this.currentStudent.submission || !this.currentStudent.submission.submission_type || this.currentStudent.submission.workflow_state == 'unsubmitted') {
          $this_student_does_not_have_a_submission.show();
      } else if (this.currentStudent.submission && this.currentStudent.submission.submitted_at && jsonData.context.quiz && jsonData.context.quiz.anonymous_submissions) {
          $this_student_has_a_submission.show();
      } else {
        $iframe_holder.empty();

        if (attachment) {
          var scribdDocAvailable = attachment.scribd_doc && attachment.scribd_doc.created && attachment.workflow_state != 'errored' && attachment.scribd_doc.attributes.doc_id;
          var previewOptions = {
            height: '100%',
            mimeType: attachment.content_type,
            attachment_id: attachment.id,
            submission_id: this.currentStudent.submission.id,
            attachment_view_inline_ping_url: attachment.view_inline_ping_url,
            attachment_preview_processing: attachment.workflow_state == 'pending_upload' || attachment.workflow_state == 'processing',
            attachment_scribd_render_url: attachment.scribd_render_url,
            ready: function(){
              EG.resizeFullHeight();
            }
          };
        }
        if (attachment && attachment.crocodoc_url) {
          var crocodocStart = new Date()
          ,   sessionLimit = 60 * 60 * 1000
          ,   aggressiveWarnings = [50 * 60 * 1000,
                                    55 * 60 * 1000,
                                    58 * 60 * 1000,
                                    59 * 60 * 1000];
          crocodocSessionTimer = window.setInterval(function() {
            var elapsed = new Date() - crocodocStart;
            if (elapsed > sessionLimit) {
              window.location.reload();
            } else if (elapsed > aggressiveWarnings[0]) {
              alert(I18n.t("crocodoc_expiring",
                           "Your Crocodoc session is expiring soon.  Please reload " +
                           "the window to avoid losing any work."));
              aggressiveWarnings.shift();
            }
          }, 1000);

          $iframe_holder.show().loadDocPreview($.extend(previewOptions, {
            crocodoc_session_url: attachment.crocodoc_url
          }));
        }
        else if (attachment && attachment.canvadoc_url) {
          $iframe_holder.show().loadDocPreview($.extend(previewOptions, {
            canvadoc_session_url: attachment.canvadoc_url
          }));
        }
        else if ( attachment && (attachment['scribdable?'] || $.isPreviewable(attachment.content_type, 'google')) ) {
          if (!INST.disableCrocodocPreviews) $no_annotation_warning.show();

          if (scribdDocAvailable) {
            previewOptions = $.extend(previewOptions, {
              scribd_doc_id: attachment.scribd_doc.attributes.doc_id,
              scribd_access_key: attachment.scribd_doc.attributes.access_key
            });
          }
          var currentStudentIDAsOfAjaxCall = this.currentStudent.id;
          previewOptions = $.extend(previewOptions, {
              ajax_valid: _.bind(function() {
                return(currentStudentIDAsOfAjaxCall == this.currentStudent.id);
              },this)});
          $iframe_holder.show().loadDocPreview(previewOptions);
	      }
	      else if (attachment && browserableCssClasses.test(attachment.mime_class)) {
	        var src = unescape($submission_file_hidden.find('.display_name').attr('href'))
	                  .replace("{{submissionId}}", this.currentStudent.submission.user_id)
	                  .replace("{{attachmentId}}", attachment.id);
	        $iframe_holder.html('<iframe src="'+src+'" frameborder="0" id="speedgrader_iframe"></iframe>').show();
	      }
	      else {
	        //load in the iframe preview.  if we are viewing a past version of the file pass the version to preview in the url
	        $iframe_holder.html(
            '<iframe id="speedgrader_iframe" src="/courses/' + jsonData.context_id  +
            '/assignments/' + this.currentStudent.submission.assignment_id +
            '/submissions/' + this.currentStudent.submission.user_id +
            '?preview=true' + (

              this.currentStudent.submission &&
              !isNaN(this.currentStudent.submission.currentSelectedIndex) &&
              this.currentStudent.submission.currentSelectedIndex != null ?
              '&version=' + this.currentStudent.submission.currentSelectedIndex :
              ''
            ) + (
              utils.shouldHideStudentNames() ? "&hide_student_name=1" : ""
            ) + '" frameborder="0"></iframe>')
            .show();
	      }
  	  }
    },

    showRubric: function(){
      //if this has some rubric_assessments
      if (jsonData.rubric_association) {
        ENV.RUBRIC_ASSESSMENT.assessment_user_id = this.currentStudent.id;

        var assessmentsByMe = $.grep(EG.currentStudent.rubric_assessments, function(n,i){
          return n.assessor_id === ENV.RUBRIC_ASSESSMENT.assessor_id;
        });
        var gradingAssessments = $.grep(EG.currentStudent.rubric_assessments, function(n,i){
          return n.assessment_type == 'grading';
        });

        $rubric_assessments_select.find("option").remove();
        $.each(this.currentStudent.rubric_assessments, function(){
          $rubric_assessments_select.append('<option value="' + this.id + '">' + htmlEscape(this.assessor_name) + '</option>');
        });

        // show a new option if there is not an assessment by me
        // or, if I can :manage_course, there is not an assessment already with assessment_type = 'grading'
        if( !assessmentsByMe.length || (ENV.RUBRIC_ASSESSMENT.assessment_type == 'grading' && !gradingAssessments.length) ) {
          $rubric_assessments_select.append('<option value="new">' + htmlEscape(I18n.t('new_assessment', '[New Assessment]')) + '</option>');
        }

        //select the assessment that meets these rules:
        // 1. the assessment by me
        // 2. the assessment with assessment_type = 'grading'
        var idToSelect = null;
        if (gradingAssessments.length) {
          idToSelect = gradingAssessments[0].id;
        }
        if (assessmentsByMe.length) {
          idToSelect = assessmentsByMe[0].id;
        }
        if (idToSelect) {
          $rubric_assessments_select.val(idToSelect);
        }

        // hide the select box if there is not >1 option
        $("#rubric_assessments_list").showIf($rubric_assessments_select.find("option").length > 1);
        $rubric_assessments_select.change();
      }
    },

    showDiscussion: function(){
      var hideStudentNames = utils.shouldHideStudentNames();
      $comments.html("");
      if (this.currentStudent.submission && this.currentStudent.submission.submission_comments) {
        $.each(this.currentStudent.submission.submission_comments, function(i, comment){
          // Serialization seems to have changed... not sure if it's changed everywhere, though...
          if(comment.submission_comment) { comment = comment.submission_comment; }
          comment.posted_at = $.datetimeString(comment.created_at);

          var hideStudentName = hideStudentNames && jsonData.studentMap[comment.author_id];
          if (hideStudentName) { comment.author_name = I18n.t('student', "Student"); }
          var $comment = $comment_blank.clone(true).fillTemplateData({ data: comment });
          $comment.find('span.comment').html(htmlEscape(comment.comment).replace(/\n/g, "<br />"));
          if (comment.avatar_path && !hideStudentName) {
            $comment.find(".avatar").attr('src', comment.avatar_path).show();
          }
          // this is really poorly decoupled but over in speed_grader.html.erb these rubricAssessment. variables are set.
          // what this is saying is: if I am able to grade this assignment (I am administrator in the course) or if I wrote this comment...
          var commentIsDeleteableByMe = ENV.RUBRIC_ASSESSMENT.assessment_type === "grading" ||
                                        ENV.RUBRIC_ASSESSMENT.assessor_id === comment.author_id;

          $comment.find(".delete_comment_link").click(function(event) {
            $(this).parents(".comment").confirmDelete({
              url: "/submission_comments/" + comment.id,
              message: I18n.t('confirms.delete_comment', "Are you sure you want to delete this comment?"),
              success: function(data) {
                $(this).slideUp(function() {
                  $(this).remove();
                });
              }
            });
          }).showIf(commentIsDeleteableByMe);

          if (comment.media_comment_type && comment.media_comment_id) {
            $comment.find(".play_comment_link").data(comment).show();
          }
          $.each((comment.cached_attachments || comment.attachments), function(){
            var attachment = this.attachment || this;
            attachment.comment_id = comment.id;
            attachment.submitter_id = EG.currentStudent.id;
            $comment.find(".comment_attachments").append($comment_attachment_blank.clone(true).fillTemplateData({
              data: attachment,
              hrefValues: ['comment_id', 'id', 'submitter_id']
            }).show().find("a").addClass(attachment.mime_class));
          });
          $comments.append($comment.show());
          $comments.find(".play_comment_link").mediaCommentThumbnail('normal');
        });
      }
      $comments.scrollTop(9999999);  //the scrollTop part forces it to scroll down to the bottom so it shows the most recent comment.
    },

    revertFromFormSubmit: function() {
        EG.showDiscussion();
        EG.resizeFullHeight();
        $add_a_comment_textarea.val("");
        // this is really weird but in webkit if you do $add_a_comment_textarea.val("").trigger('keyup') it will not let you
        // type it the textarea after you do that.  but I put it in a setTimeout it works.  so this is a hack for webkit,
        // but it still works in all other browsers.
        setTimeout(function(){ $add_a_comment_textarea.trigger('keyup'); }, 0);

        $add_a_comment.find(":input").prop("disabled", false);
        if (jsonData.GROUP_GRADING_MODE) {
          disableGroupCommentCheckbox();
        }

        $add_a_comment_submit_button.text(I18n.t('buttons.submit_comment', "Submit Comment"));
    },

    handleCommentFormSubmit: function(){
      if (
        !$.trim($add_a_comment_textarea.val()).length &&
        !$("#media_media_recording").data('comment_id') &&
        !$add_a_comment.find("input[type='file']:visible").length
        ) {
          // that means that they did not type a comment, attach a file or record any media. so dont do anything.
        return false;
      }
      var url = assignmentUrl + "/submissions/" + EG.currentStudent.id;
      var method = "PUT";
      var formData = {
        'submission[assignment_id]': jsonData.id,
        'submission[user_id]': EG.currentStudent.id,
        'submission[group_comment]': ($("#submission_group_comment").attr('checked') ? "1" : "0"),
        'submission[comment]': $add_a_comment_textarea.val()
      };
      if ($("#media_media_recording").data('comment_id')) {
        $.extend(formData, {
          'submission[media_comment_type]': $("#media_media_recording").data('comment_type'),
          'submission[media_comment_id]': $("#media_media_recording").data('comment_id')
        });
      }

      function formSuccess(submissions) {
        $.each(submissions, function(){
          EG.setOrUpdateSubmission(this.submission);
        });
        EG.revertFromFormSubmit();
      }
      if($add_a_comment.find("input[type='file']:visible").length) {
        $.ajaxJSONFiles(url + ".text", method, formData, $add_a_comment.find("input[type='file']:visible"), formSuccess);
      } else {
        $.ajaxJSON(url, method, formData, formSuccess);
      }

      $("#comment_attachments").empty();
      $add_a_comment.find(":input").prop("disabled", true);
      $add_a_comment_submit_button.text(I18n.t('buttons.submitting', "Submitting..."));
      hideMediaRecorderContainer();
    },

    setOrUpdateSubmission: function(submission){
      // find the student this submission belongs to and update their submission with this new one, if they dont have a submission, set this as their submission.
      var student =  jsonData.studentMap[submission.user_id];
      if (!student) return;

      student.submission = student.submission || {};

      // stuff that comes back from ajax doesnt have a submission history but handleSubmissionSelectionChange
      // depends on it being there. so mimic it.
      if (typeof submission.submission_history === 'undefined') {
        submission.submission_history = [{
          submission: $.extend(true, {}, submission)
        }];
      }

      $.extend(true, student.submission, submission);
      return student;
    },

    handleGradeSubmit: function(){
      var url    = $(".update_submission_grade_url").attr('href'),
          method = $(".update_submission_grade_url").attr('title'),
          formData = {
            'submission[assignment_id]': jsonData.id,
            'submission[user_id]':       EG.currentStudent.id,
            'submission[grade]':         $grade.val()
          };

      $.ajaxJSON(url, method, formData, function(submissions) {
        $.each(submissions, function(){
          EG.setOrUpdateSubmission(this.submission);
        });
        EG.refreshSubmissionsToView();
        $multiple_submissions.change();
        EG.showGrade();
      });
    },

    showGrade: function(){
      $grade.val( typeof EG.currentStudent.submission != "undefined" &&
                  EG.currentStudent.submission.grade !== null ?
                  EG.currentStudent.submission.grade : "")
            .attr('disabled', typeof EG.currentStudent.submission != "undefined" &&
                              EG.currentStudent.submission.submission_type === 'online_quiz');

      $('#submit_same_score').hide();
      if (typeof EG.currentStudent.submission != "undefined" &&
          EG.currentStudent.submission.score !== null) {
        $score.text(round(EG.currentStudent.submission.score, round.DEFAULT));
        if (!EG.currentStudent.submission.grade_matches_current_submission) {
          $('#submit_same_score').show();
        }
      } else {
        $score.text("");
      }

      EG.updateStatsInHeader();

      // go through all the students and change the class of for each person in the selectmenu to reflect it has / has not been graded.
      // for the current student, you have to do it for both the li as well as the one that shows which was selected (AKA $selectmenu.data('selectmenu').newelement ).
      // this might be the wrong spot for this, it could be refactored into its own method and you could tell pass only certain students that you want to update
      // (ie the current student or all of the students in the group that just got graded)
      $.each(jsonData.studentsWithSubmissions, function(index, val) {
        var $query = $selectmenu.data('selectmenu').list.find("li:eq("+ index +")"),
            className = classNameBasedOnStudent(this),
            submissionStates = 'not_graded not_submitted graded resubmitted';

        if (this == EG.currentStudent) {
          $query = $query.add($selectmenu.data('selectmenu').newelement);
        }
        $query
          .removeClass(submissionStates)
          .addClass(className.raw)
          .find(".ui-selectmenu-item-footer")
            .text(className.formatted);

        $status = $(".ui-selectmenu-status");
        $statusIcon = $status.find(".speedgrader-selectmenu-icon");
        $queryIcon = $query.find(".speedgrader-selectmenu-icon");

        if(className.raw == "graded" && this == EG.currentStudent){
          $queryIcon.text("").append("<i class='icon-check'></i>");
          $status.addClass("graded");
          $statusIcon.text("").append("<i class='icon-check'></i>");
        }else if(className.raw == "not_graded" && this == EG.currentStudent){
          $queryIcon.text("").append("&#9679;");
          $status.removeClass("graded");
          $statusIcon.text("").append("&#9679;");
        }else{
          $status.removeClass("graded");
        }

        // this is because selectmenu.js uses .data('optionClasses' on the li to keep track
        // of what class to put on the selected option ( aka: $selectmenu.data('selectmenu').newelement )
        // when this li is selected.  so even though we set the class of the li and the
        // $selectmenu.data('selectmenu').newelement when it is graded, we need to also set the data()
        // so that if you skip back to this student it doesnt show the old checkbox status.
        $.each(submissionStates.split(' '), function(){
          $query.data('optionClasses', $query.data('optionClasses').replace(this, ''));
        });
      });

    },

    initComments: function(){
      $add_a_comment_submit_button.click(function(event) {
        event.preventDefault();
        EG.handleCommentFormSubmit();
      });
      $add_attachment.click(function(event) {
        event.preventDefault();
        var $attachment = $comment_attachment_input_blank.clone(true);
        $attachment.find("input").attr('name', 'attachments[' + fileIndex + '][uploaded_data]');
        fileIndex++;
        $("#comment_attachments").append($attachment.show());
        EG.resizeFullHeight();
      });
      $comment_attachment_input_blank.find("a").click(function(event) {
        event.preventDefault();
        $(this).parents(".comment_attachment_input").remove();
        EG.resizeFullHeight();
      });
      $right_side.delegate(".play_comment_link", 'click', function() {
        if($(this).data('media_comment_id')) {
          $(this).parents(".comment").find(".media_comment_content").show().mediaComment('show', $(this).data('media_comment_id'), $(this).data('media_comment_type'));
        }
        return false; // so that it doesn't hit the $("a.instructure_inline_media_comment").live('click' event handler
      });
    }
  };

  //run the stuff that just attaches event handlers and dom stuff, but does not need the jsonData
  $(document).ready(function() {
    EG.domReady();
  });

});
