/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

/*global jsonData*/
import React from 'react';
import ReactDOM from 'react-dom';
import Alert from '@instructure/ui-alerts/lib/components/Alert';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import TextArea from '@instructure/ui-forms/lib/components/TextArea';
import OutlierScoreHelper from 'jsx/grading/helpers/OutlierScoreHelper';
import quizzesNextSpeedGrading from 'jsx/grading/quizzesNextSpeedGrading';
import StatusPill from 'jsx/grading/StatusPill';
import JQuerySelectorCache from 'jsx/shared/helpers/JQuerySelectorCache';
import numberHelper from 'jsx/shared/helpers/numberHelper';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import AssessmentAuditButton from 'jsx/speed_grader/AssessmentAuditTray/components/AssessmentAuditButton'
import AssessmentAuditTray from 'jsx/speed_grader/AssessmentAuditTray'
import SpeedGraderProvisionalGradeSelector from 'jsx/speed_grader/SpeedGraderProvisionalGradeSelector'
import SpeedGraderSettingsMenu from 'jsx/speed_grader/SpeedGraderSettingsMenu'
import studentViewedAtTemplate from 'jst/speed_grader/student_viewed_at';
import submissionsDropdownTemplate from 'jst/speed_grader/submissions_dropdown';
import speechRecognitionTemplate from 'jst/speed_grader/speech_recognition';
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import IconUpload from '@instructure/ui-icons/lib/Line/IconUpload'
import IconWarning from '@instructure/ui-icons/lib/Line/IconWarning'
import IconCheckMarkIndeterminate from '@instructure/ui-icons/lib/Line/IconCheckMarkIndeterminate'
import FailedUploadTreeKite from 'jsx/speed_grader/FailedUploadTreeKite'
import WaitingWristWatch from 'jsx/speed_grader/WaitingWristWatch'
import View from '@instructure/ui-layout/lib/components/View'
import Text from '@instructure/ui-elements/lib/components/Text'
import round from 'compiled/util/round';
import _ from 'underscore';
import INST from './INST';
import I18n from 'i18n!gradebook';
import natcompare from 'compiled/util/natcompare';
import $ from 'jquery';
import tz from 'timezone';
import userSettings from 'compiled/userSettings';
import htmlEscape from './str/htmlEscape';
import rubricAssessment from './rubric_assessment';
import SpeedgraderSelectMenu from './speed_grader_select_menu';
import SpeedgraderHelpers, {
  setupAnonymizableId,
  setupAnonymizableStudentId,
  setupAnonymizableUserId,
  setupAnonymizableAuthorId,
  setupAnonymousGraders,
  setupIsAnonymous,
  setupIsModerated
} from './speed_grader_helpers';
import turnitinInfoTemplate from 'jst/_turnitinInfo';
import turnitinScoreTemplate from 'jst/_turnitinScore';
import vericiteInfoTemplate from 'jst/_vericiteInfo';
import vericiteScoreTemplate from 'jst/_vericiteScore';
import 'jqueryui/draggable';
import './jquery.ajaxJSON'; /* getJSON, ajaxJSON */
import './jquery.instructure_forms'; /* ajaxJSONFiles */
import './jquery.doc_previews'; /* loadDocPreview */
import './jquery.instructure_date_and_time'; /* datetimeString */
import 'jqueryui/dialog';
import './jquery.instructure_misc_helpers'; /* replaceTags */
import './jquery.instructure_misc_plugins'; /* confirmDelete, showIf, hasScrollbar */
import './jquery.keycodes';
import './jquery.loadingImg';
import './jquery.templateData';
import './media_comments';
import 'compiled/jquery/mediaCommentThumbnail';
import 'compiled/jquery.rails_flash_notifications';
import 'jquery-getscrollbarwidth';
import './vendor/jquery.scrollTo';
import './vendor/ui.selectmenu';
import './jquery.disableWhileLoading';
import 'compiled/jquery/fixDialogButtons';

const selectors = new JQuerySelectorCache();
const SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT = 'speed_grader_comment_textarea_mount_point';
const SPEED_GRADER_SUBMISSION_COMMENTS_DOWNLOAD_MOUNT_POINT = 'speed_grader_submission_comments_download_mount_point';
const SPEED_GRADER_SETTINGS_MOUNT_POINT = 'speed_grader_settings_mount_point';
const ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT = 'speed_grader_assessment_audit_button_mount_point'
const ASSESSMENT_AUDIT_TRAY_MOUNT_POINT = 'speed_grader_assessment_audit_tray_mount_point'

let isAnonymous
let anonymousGraders
let anonymizableId
let anonymizableUserId
let anonymizableStudentId
let anonymizableAuthorId
let isModerated

let $window
let $full_width_container
let $left_side
let $resize_overlay
let $right_side
let $width_resizer
let $gradebook_header
let $grading_box_selected_grader
let assignmentUrl
let $rightside_inner
let $moderation_bar
let $moderation_tabs_div
let $moderation_tabs
let $moderation_tab_2nd
let $moderation_tab_final
let $new_mark_container
let $new_mark_link
let $new_mark_link_menu_item
let $new_mark_copy_link1
let $new_mark_copy_link2
let $new_mark_copy_link2_menu_item
let $new_mark_final_link
let $new_mark_final_link_menu_item
let $not_gradeable_message
let $comments
let $comment_blank
let $comment_attachment_blank
let $add_a_comment
let $add_a_comment_submit_button
let $add_a_comment_textarea
let $comment_attachment_input_blank
let fileIndex
let $add_attachment
let $submissions_container
let $iframe_holder
let $avatar_image
let $x_of_x_students
let $grded_so_far
let $average_score
let $this_student_does_not_have_a_submission
let $this_student_has_a_submission
let $grade_container
let $grade
let $score
let $deduction_box
let $points_deducted
let $final_grade
let $average_score_wrapper
let $submission_details
let $multiple_submissions
let $submission_late_notice
let $submission_not_newest_notice
let $enrollment_inactive_notice
let $enrollment_concluded_notice
let $submission_files_container
let $submission_files_list
let $submission_attachment_viewed_at
let $submission_file_hidden
let $assignment_submission_turnitin_report_url
let $assignment_submission_originality_report_url
let $assignment_submission_vericite_report_url
let $assignment_submission_resubmit_to_vericite_url
let $rubric_holder
let $rubric_full_resizer_handle
let $no_annotation_warning
let $comment_submitted
let $comment_submitted_message
let $comment_saved
let $comment_saved_message
let $selectmenu
let browserableCssClasses
let snapshotCache
let sectionToShow
let header
let studentLabel
let groupLabel
let gradeeLabel
let utils
let sessionTimer
let isAdmin
let showSubmissionOverride
let provisionalGraderDisplayNames
let EG
const customProvisionalGraderLabel = I18n.t('Custom')
const anonymousAssignmentDetailedReportTooltip = I18n.t(
  'Cannot view detailed reports for anonymous assignments until grades are unmuted.'
)

function setupHandleFragmentChanged () {
  window.addEventListener('hashchange', EG.handleFragmentChanged);
}

function teardownHandleFragmentChanged () {
  window.removeEventListener('hashchange', EG.handleFragmentChanged);
}

function setupBeforeLeavingSpeedgrader () {
  window.addEventListener('beforeunload', EG.beforeLeavingSpeedgrader);
}

function teardownBeforeLeavingSpeedgrader () {
  window.removeEventListener('beforeunload', EG.beforeLeavingSpeedgrader);
}

function unexcuseSubmission (grade, submission, assignment) {
  return grade === "" && submission.excused && assignment.grading_type === "pass_fail";
}

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
    return settingVal === true || settingVal === "true" || ENV.force_anonymous_grading
  }
};

function sectionSelectionOptions (courseSections, groupGradingModeEnabled = false, selectedSectionId = null) {
  if (courseSections.length <= 1 || groupGradingModeEnabled) {
    return [];
  }

  let selectedSectionName = I18n.t('All Sections');
  const sectionOptions = [
    {
      [anonymizableId]: 'section_all',
      data: {
        'section-id': "all"
      },
      name: I18n.t('Show all sections'),
      className: {
        raw: 'section_all'
      },
      anonymizableId
    }
  ];

  courseSections.forEach((section) => {
    if (section.id === selectedSectionId) {
      selectedSectionName = section.name;
    }

    sectionOptions.push({
      [anonymizableId]: `section_${section.id}`,
      data: {
        "section-id": section.id
      },
      name: I18n.t('Change section to %{sectionName}', { sectionName: section.name }),
      className: {
        raw: `section_${section.id} ${ selectedSectionId === section.id ? 'selected' : '' }`
      },
      anonymizableId
    });
  });

  return [
    {
      name: `Showing: ${selectedSectionName}`,
      options: sectionOptions
    }
  ];
}

function mergeStudentsAndSubmission() {
  jsonData.studentsWithSubmissions = jsonData.context.students;
  jsonData.studentMap = {};
  jsonData.studentEnrollmentMap = {};
  jsonData.studentSectionIdsMap = {};
  jsonData.submissionsMap = {};

  jsonData.context.enrollments.forEach((enrollment) => {
    const enrollmentAnonymizableUserId = enrollment[anonymizableUserId]
    jsonData.studentEnrollmentMap[enrollmentAnonymizableUserId] = jsonData.studentEnrollmentMap[enrollmentAnonymizableUserId] || [];
    jsonData.studentSectionIdsMap[enrollmentAnonymizableUserId] = jsonData.studentSectionIdsMap[enrollmentAnonymizableUserId] || {};

    jsonData.studentEnrollmentMap[enrollmentAnonymizableUserId].push(enrollment);
    jsonData.studentSectionIdsMap[enrollmentAnonymizableUserId][enrollment.course_section_id] = true;
  });

  jsonData.submissions.forEach((submission) => {
    jsonData.submissionsMap[submission[anonymizableUserId]] = submission;
  });

  // need to presort by anonymous_id for anonymous assignments so that the index property can be consistent
  if (isAnonymous) jsonData.studentsWithSubmissions.sort((a, b) => a.anonymous_id > b.anonymous_id ? 1 : -1)

  jsonData.studentsWithSubmissions.forEach((student, index) => {
    /* eslint-disable no-param-reassign */
    student.enrollments = jsonData.studentEnrollmentMap[student[anonymizableId]];
    student.section_ids = Object.keys(jsonData.studentSectionIdsMap[student[anonymizableId]]);
    student.submission = jsonData.submissionsMap[student[anonymizableId]];
    student.submission_state = SpeedgraderHelpers.submissionState(student, ENV.grading_role);
    student.index = index;
    /* eslint-enable no-param-reassign */

    jsonData.studentMap[student[anonymizableId]] = student;
  });

  // handle showing students only in a certain section.
  if (!jsonData.GROUP_GRADING_MODE) {
    if (ENV.new_gradebook_enabled) {
      sectionToShow = ENV.selected_section_id
    } else {
      sectionToShow = userSettings.contextGet('grading_show_only_section')
    }
  }

  if (sectionToShow) {
    sectionToShow = sectionToShow.toString()
    var tempArray  = $.grep(jsonData.studentsWithSubmissions, function(student, i){
      return $.inArray(sectionToShow, student.section_ids) != -1;
    });
    if (tempArray.length) {
      jsonData.studentsWithSubmissions = tempArray;
    } else {
      alert(I18n.t('alerts.no_students_in_section', "Could not find any students in that section, falling back to showing all sections."));
      EG.changeToSection('all')
    }
  }

  switch(userSettings.get("eg_sort_by")) {
    case 'submitted_at': {
      window.jsonData.studentsWithSubmissions.sort(EG.compareStudentsBy(student => {
        const submittedAt = student && student.submission && student.submission.submitted_at;
        if (submittedAt) {
          return +tz.parse(submittedAt);
        } else {
          // puts the unsubmitted assignments at the bottom
          return Number.NaN;
        }
      }));
      break;
    }

    case 'submission_status': {
      const states = {
        "not_graded": 1,
        "resubmitted": 2,
        "not_submitted": 3,
        "graded": 4,
        "not_gradeable": 5
      };
      window.jsonData.studentsWithSubmissions.sort(EG.compareStudentsBy(student => (
        student && states[SpeedgraderHelpers.submissionState(student, ENV.grading_role)]
      )));
      break;
    }

    // The list of students is sorted alphabetically on the server by student last name.
    default: {
      // sorting for isAnonymous occurred earlier before setting up studentMap
      if (!isAnonymous && utils.shouldHideStudentNames()) {
        window.jsonData.studentsWithSubmissions.sort(EG.compareStudentsBy(student => student.submission.id))
      }
    }
  }
}

function initDropdown(){
  var hideStudentNames = utils.shouldHideStudentNames();
  $("#hide_student_names").attr('checked', hideStudentNames);

  const optionsArray = jsonData.studentsWithSubmissions.map(student => {
    const {submission_state, submission} = student
    let {name} = student
    const className = SpeedgraderHelpers.classNameBasedOnStudent({submission_state, submission})
    if (hideStudentNames || isAnonymous) {
      name = I18n.t("Student %{number}", {number: student.index + 1})
    }

    return {[anonymizableId]: student[anonymizableId], anonymizableId, name, className};
  })

  const sectionSelectionOptionList = sectionSelectionOptions(
    jsonData.context.active_course_sections,
    jsonData.GROUP_GRADING_MODE,
    sectionToShow
  );

  $selectmenu = new SpeedgraderSelectMenu(sectionSelectionOptionList.concat(optionsArray));
  $selectmenu.appendTo("#combo_box_container", (event) => {
    const newStudentOrSection = $(event.target).val()

    if (newStudentOrSection && newStudentOrSection.match(/^section_(\d+|all)$/)) {
      const sectionId = newStudentOrSection.replace(/^section_/, '');
      EG.changeToSection(sectionId)
    } else {
      EG.handleStudentChanged();
    }
  });

  if (jsonData.context.active_course_sections.length && jsonData.context.active_course_sections.length > 1 && !jsonData.GROUP_GRADING_MODE) {
    const $selectmenu_list = $selectmenu.data('selectmenu').list;
    const $menu = $("#section-menu");

    $menu.find('ul').append($.raw($.map(jsonData.context.active_course_sections, function(section, i){
      return '<li><a class="section_' + section.id + '" data-section-id="'+ section.id +'" href="#">'+ htmlEscape(section.name) +'</a></li>';
    }).join('')));

    $menu.insertBefore($selectmenu_list).bind('mouseenter mouseleave', function(event){
      $(this)
        .toggleClass('ui-selectmenu-item-selected ui-selectmenu-item-focus ui-state-hover', event.type == 'mouseenter')
        .find('ul').toggle(event.type == 'mouseenter');
    })
      .find('ul')
      .hide()
      .menu()
      .delegate('a', 'click mousedown', function(){
        EG.changeToSection($(this).data('section-id'))
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

function setupHeader () {
  return {
    elements: {
      mute: {
        icon: $('#mute_link i'),
        label: $('#mute_link .mute_label'),
        link: $('#mute_link'),
        modal: $('#mute_dialog')
      },
      unmute: {
        modal: $('#unmute_dialog')
      },
      nav: $gradebook_header.find('#prev-student-button, #next-student-button'),
      settings: { form: $('#settings_form') }
    },
    courseId: utils.getParam('courses'),
    assignmentId: utils.getParam('assignment_id'),
    init () {
      this.muted = this.elements.mute.link.data('muted');
      this.addEvents();
      this.createModals();
      return this;
    },
    addEvents () {
      this.elements.nav.click($.proxy(this.toAssignment, this));
      this.elements.mute.link.click($.proxy(this.onMuteClick, this));

      this.elements.settings.form.submit(this.submitSettingsForm.bind(this));
    },
    createModals () {
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
          class: 'btn-primary btn-mute',
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
      this.elements.unmute.modal.dialog({
        autoOpen: false,
        buttons: [{
          text: I18n.t('Cancel'),
          click: $.proxy(function () {
            this.elements.unmute.modal.dialog('close');
          }, this)
        }, {
          text: I18n.t('Unmute Assignment'),
          class: 'btn-primary btn-unmute',
          click: $.proxy(function () {
            this.toggleMute();
            this.elements.unmute.modal.dialog('close');
          }, this)
        }],
        modal: true,
        resizable: false,
        title: this.elements.unmute.modal.data('title'),
        width: 400
      });
    },

    toAssignment (e) {
      e.preventDefault();
      const classes = e.target.getAttribute("class").split(" ");
      if (_.contains(classes, "prev")) {
        EG.prev();
      } else if (_.contains(classes, "next")) {
        EG.next();
      }
    },

    keyboardShortcutInfoModal () {
      var questionMarkKeyDown = $.Event('keydown', { keyCode: 191 });
      $(document).trigger(questionMarkKeyDown);
    },

    submitSettingsForm (e) {
      e.preventDefault();

      userSettings.set('eg_sort_by', $('#eg_sort_by').val());
      if (!ENV.force_anonymous_grading) {
        userSettings.set('eg_hide_student_names', $("#hide_student_names").prop('checked'));
      }

      $(e.target).find(".submit_button").attr('disabled', true).text(I18n.t('buttons.saving_settings', "Saving Settings..."));
      const gradeByQuestion = $("#enable_speedgrader_grade_by_question").prop('checked');
      $.post(ENV.settings_url, {
        enable_speedgrader_grade_by_question: gradeByQuestion
      }).then(function() {
        SpeedgraderHelpers.reloadPage();
      });
    },

    showSettingsModal (event) {
      if (event) {
        event.preventDefault()
      }
      this.elements.settings.form.dialog('open')
    },

    onMuteClick (e) {
      e.preventDefault();
      if (this.muted) {
        this.elements.unmute.modal.dialog('open');
      } else {
        this.elements.mute.modal.dialog('open');
      }
    },

    muteUrl () {
      return '/courses/' + this.courseId + '/assignments/' + this.assignmentId + '/mute';
    },

    toggleMute () {
      this.muted = !this.muted;
      const label = this.muted ? I18n.t('unmute_assignment', 'Unmute Assignment') : I18n.t('mute_assignment', 'Mute Assignment'),
        action = this.muted ? 'mute' : 'unmute',
        actions = {
          /* Mute action */
          mute () {
            this.elements.mute.icon.removeClass("icon-unmuted").addClass("icon-muted");
            $.ajaxJSON(this.muteUrl(), 'put', { status: true }, $.proxy(function() {
              this.elements.mute.label.text(label);
            }, this));
          },

          /* Unmute action */
          unmute () {
            this.elements.mute.icon.removeClass("icon-muted").addClass("icon-unmuted");
            $.ajaxJSON(this.muteUrl(), 'put', { status: false }, $.proxy(function() {
              this.elements.mute.label.text(label);
            }, this));
          }
        };

      actions[action].apply(this);
    }
  };
}

function unmountCommentTextArea () {
  const node = document.getElementById(SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT);
  ReactDOM.unmountComponentAtNode(node);
}

function renderProgressIcon (attachment) {
  const mountPoint = document.getElementById('react_pill_container');
  let icon = [];
  switch(attachment.workflow_state) {
    case 'pending_upload':
      icon = [<IconUpload />, I18n.t("Uploading Submission")];
      break;
    case 'errored':
      icon = [<IconWarning />, I18n.t("Submission Failed to Submit")];
      break;
    case 'processed':
      break;
    default:
      icon = [<IconCheckMarkIndeterminate />, I18n.t("No File Submitted")];
  };

  ReactDOM.render((
    <Tooltip tip={ icon[1] }>
      { icon[0] }
    </Tooltip>
  ), mountPoint);
}

function renderCommentTextArea () {
  // unmounting is a temporary workaround for INSTUI-870 to allow
  // for textarea minheight to be reset
  unmountCommentTextArea();
  function textareaRef (textarea) {
    $add_a_comment_textarea = $(textarea);
  }

  const textAreaProps = {
    height: '4rem',
    id: 'speed_grader_comment_textarea',
    label: <ScreenReaderContent>
      {I18n.t('Add a Comment')}
    </ScreenReaderContent>,
    placeholder: I18n.t('Add a Comment'),
    resize: 'vertical',
    textareaRef
  };

  ReactDOM.render(
    <TextArea {...textAreaProps} />,
    document.getElementById(SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT)
  );
}

function initCommentBox(){
  renderCommentTextArea();

  $(".media_comment_link").click(function(event) {
    event.preventDefault();
    if ($(".media_comment_link").hasClass('ui-state-disabled')) {
      return;
    }
    $("#media_media_recording").show().find(".media_recording").mediaComment('create', 'any', function(id, type) {
      $("#media_media_recording").data('comment_id', id).data('comment_type', type);
      EG.addSubmissionComment();
    }, function() {
      EG.revertFromFormSubmit();
    }, true);
  });

  $("#media_recorder_container a").live('click', hideMediaRecorderContainer);

  // handle speech to text for browsers that can (right now only chrome)
  function browserSupportsSpeech(){
    return 'webkitSpeechRecognition' in window;
  }
  if (browserSupportsSpeech()){
    var recognition = new webkitSpeechRecognition();
    var messages = {
      "begin": I18n.t('begin_record_prompt', 'Click the "Record" button to begin.'),
      "allow": I18n.t('allow_message', 'Click the "Allow" button to begin recording.'),
      "recording": I18n.t('recording_message', 'Recording...'),
      "recording_expired": I18n.t('recording_expired_message', 'Speech recognition has expired due to inactivity. Click the "Stop" button to use current text for comment or "Cancel" to discard.'),
      "mic_blocked": I18n.t('mic_blocked_message', 'Permission to use microphone is blocked. To change, go to chrome://settings/contentExceptions#media-stream'),
      "no_speech": I18n.t('nodetect_message', 'No speech was detected. You may need to adjust your microphone settings.')
    }
    configureRecognition(recognition);
    $(".speech_recognition_link").click(function(){
      if ($(".speech_recognition_link").hasClass('ui-state-disabled')) {
        return false;
      }
      $(speechRecognitionTemplate({
        message: messages.begin
      }))
        .dialog({
          title: I18n.t('titles.click_to_record', "Speech to Text"),
          minWidth: 450,
          minHeight: 200,
          dialogClass: "no-close",
          buttons: [{
            'class': 'dialog_button',
            text: I18n.t('buttons.dialog_buttons', "Cancel"),
            click: function(){
              recognition.stop();
              $(this).dialog('close').remove();
            }
          },
                    {
                      id: 'record_button',
                      'class': 'dialog_button',
                      'aria-label': I18n.t('dialog_button.aria_record', "Click to record"),
                      recording: false,
                      html: "<div></div>",
                      click: function(){
                        var $this = $(this)
                        processSpeech($this);
                      }
                    }],
          close: function(){
            recognition.stop();
            $(this).dialog('close').remove();
          }
        })
      return false;
    });
    // show the div that contains the button because it is hidden from browsers that dont support speech
    $(".speech_recognition_link").closest('div.speech-recognition').show();

    var processSpeech = function ($this){
      if ($('#record_button').attr("recording") == "true"){
        recognition.stop();
        var current_comment = $('#final_results').html() + $('#interim_results').html()
        $add_a_comment_textarea.val(formatComment(current_comment));
        $this.dialog('close').remove();
      }
      else {
        recognition.start();
        $('#dialog_message').text(messages.allow)
      }
    }

    var formatComment = function (current_comment){
      return current_comment.replace(/<p><\/p>/g, '\n\n').replace(/<br>/g, '\n');
    }

    function configureRecognition (recognition) {
      recognition.continuous = true;
      recognition.interimResults = true;
      var final_transcript = '';

      recognition.onstart = function(){
        $('#dialog_message').text(messages.recording);
        $('#record_button').attr("recording", true).attr("aria-label", I18n.t('dialog_button.aria_stop', 'Hit "Stop" to end recording.'))
      }

      recognition.onresult = function(event){
        var interim_transcript = '';
        for (var i = event.resultIndex; i < event.results.length; i++){
          if (event.results[i].isFinal){
            final_transcript += event.results[i][0].transcript;
            $('#final_results').html(linebreak(final_transcript))
          }
          else {
            interim_transcript += event.results[i][0].transcript;
          }
          $('#interim_results').html(linebreak(interim_transcript))
        }
      }

      recognition.onaudiostart = function(event){
        //this call is required for onaudioend event to trigger
      }

      recognition.onaudioend = function(event){
        if ($('#final_results').text() != '' || $('#interim_results').text() != ''){
          $('#dialog_message').text(messages.recording_expired);
        }
      }

      recognition.onend = function(event){
        final_transcript = '';
      }

      recognition.onerror = function(event){
        if (event.error == 'not-allowed') {
          $('#dialog_message').text(messages.mic_blocked);
        }
        else if (event.error = 'no-speech'){
          $('#dialog_message').text(messages.no_speech);
        }
        $('#record_button').attr("recording", false).attr("aria-label", I18n.t('dialog_button.aria_record_reset', "Click to record"));
      }

      // xsslint safeString.function linebreak
      function linebreak(transcript){
        return htmlEscape(transcript).replace(/\n\n/g, '<p></p>').replace(/\n/g, '<br>');
      }
    }
  }
}

function hideMediaRecorderContainer(){
  $("#media_media_recording").hide().removeData('comment_id').removeData('comment_type');
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
  const selectMenu = selectors.get('#rubric_assessments_select');

  return $.grep(EG.currentStudent.rubric_assessments, (n) => (
    n.id == selectMenu.val()
  ))[0];
}

function assessmentBelongsToCurrentUser(assessment) {
  if (!assessment) {
    return false
  }

  if (anonymousGraders) {
    return ENV.current_anonymous_id === assessment.anonymous_assessor_id
  } else {
    return ENV.current_user_id === assessment.assessor_id
  }
}

function handleSelectedRubricAssessmentChanged({validateEnteredData = true} = {}) {
  // This function is triggered both when we assess a student and when we switch
  // students. In the former case, we want populateNewRubricSummary to check the
  // data we entered and show an alert if the grader tried to assign more points
  // to an outcome than it allows (and the course does not allow extra credit).
  // In the latter case, because this function is called *before* the editing
  // data is switched over to the new student, we don't want to perform the
  // comparison since it could result in specious alerts being shown.
  const editingData = validateEnteredData ? rubricAssessment.assessmentData($("#rubric_full")) : null
  const selectedAssessment = getSelectedAssessment()
  rubricAssessment.populateNewRubricSummary(
    $("#rubric_summary_holder .rubric_summary"),
    selectedAssessment,
    jsonData.rubric_association,
    editingData
  );

  let showEditButton = true
  if (isModerated) {
    showEditButton = !selectedAssessment || assessmentBelongsToCurrentUser(selectedAssessment)
  }
  $('#rubric_assessments_list_and_edit_button_holder .edit').showIf(showEditButton)
}

function initRubricStuff(){
  $("#rubric_summary_container .button-container").appendTo("#rubric_assessments_list_and_edit_button_holder").find('.edit').text(I18n.t('edit_view_rubric', "View Rubric"));

  $(".toggle_full_rubric, .hide_rubric_link").click(function(e){
    e.preventDefault();
    EG.toggleFullRubric();
  });

  selectors.get('#rubric_assessments_select').change(() => {
    handleSelectedRubricAssessmentChanged();
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
      selectors.get('#rubric_full').width(windowWidth - offset.left);
      $rubric_full_resizer_handle.css("left","0");
    },
    stop: function(event, ui) {
      event.stopImmediatePropagation();
    }
  });

  $(".save_rubric_button").click(function() {
    var $rubric = $(this).parents("#rubric_holder").find(".rubric");
    var data = rubricAssessment.assessmentData($rubric);
    if (ENV.grading_role == 'moderator' || ENV.grading_role == 'provisional_grader') {
      data['provisional'] = '1';
      if (ENV.grading_role == 'moderator' && EG.current_prov_grade_index == 'final') {
        data['final'] = '1';
      }
    }
    if (isAnonymous) {
      // FIXME: data['rubric_assessment[user_id]'] should not contain anonymous_id,
      // figure out how to fix the keys elsewhere
      data[`rubric_assessment[${anonymizableUserId}]`] = data['rubric_assessment[user_id]'];
      delete data['rubric_assessment[user_id]'];
      data.graded_anonymously = true;
    } else {
      data.graded_anonymously = utils.shouldHideStudentNames();
    }
    var url = $(".update_rubric_assessment_url").attr('href');
    var method = "POST";
    EG.toggleFullRubric('close');

    var promise = $.ajaxJSON(url, method, data, function(response) {
      var found = false;
      if(response && response.rubric_association) {
        rubricAssessment.updateRubricAssociation($rubric, response.rubric_association);
        delete response.rubric_association;
      }
      for (let i = 0; i < EG.currentStudent.rubric_assessments.length; i++) {
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
        const student = EG.setOrUpdateSubmission(response.artifact);
        student.rubric_assessments = $.map(submissionAndAssessment.rubric_assessments, function(ra){return ra.rubric_assessment;});
        EG.updateSelectMenuStatus(student);
      });

      EG.showGrade();
      EG.showDiscussion();
      EG.showRubric();
      EG.updateStatsInHeader();
    });

    $rubric_holder.disableWhileLoading(promise, {
      buttons: {
        '.save_rubric_button': 'Saving...'
      }
    });
  });
}

function initKeyCodes () {
  const keycodeOptions = {
    keyCodes: 'j k p n c r g',
    ignore: 'input, textarea, embed, object'
  };
  $window.keycodes(keycodeOptions, (event) => {
    event.preventDefault();
    event.stopPropagation();
    const { keyString } = event;

    if (keyString === "k" || keyString === "p") {
      EG.prev(); // goto Previous Student
    } else if(keyString === "j" || keyString === "n") {
      EG.next(); // goto Next Student
    } else if(keyString === "c") {
      $add_a_comment_textarea.focus(); // add comment
    } else if(keyString === "g") {
      $grade.focus(); // focus on grade
    } else if(keyString === "r") {
      EG.toggleFullRubric(); // focus rubric
    }
  });
}

function initGroupAssignmentMode() {
  if (jsonData.GROUP_GRADING_MODE) {
    gradeeLabel = groupLabel;
  }
}

function refreshGrades (cb) {
  const courseId = ENV.course_id;
  const assignmentId = EG.currentStudent.submission.assignment_id;
  const studentId = EG.currentStudent.submission[anonymizableUserId];
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}.json?include[]=submission_history`
  const currentStudentIDAsOfAjaxCall = EG.currentStudent[anonymizableId];
  $.getJSON(url, (submission) => {
    if (currentStudentIDAsOfAjaxCall === EG.currentStudent[anonymizableId]) {
      EG.currentStudent.submission = submission;
      EG.currentStudent.submission_state = SpeedgraderHelpers.submissionState(EG.currentStudent, ENV.grading_role);
      EG.showGrade();
      EG.updateSelectMenuStatus(EG.currentStudent);
      if (cb) {
        cb(submission)
      }
    }
  });
}

$.extend(INST, {
  refreshGrades: refreshGrades,
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

function rubricAssessmentToPopulate () {
  const assessment = getSelectedAssessment();
  const userIsNotAssessor = !!assessment && assessment.assessor_id !== ENV.current_user_id;
  const userCanAssess = isAssessmentEditableByMe(assessment);

  if (userIsNotAssessor && !userCanAssess) {
    return { ...assessment, data: [] };
  }

  return assessment;
}

function renderSubmissionCommentsDownloadLink(submission) {
  const mountPoint = document.getElementById(SPEED_GRADER_SUBMISSION_COMMENTS_DOWNLOAD_MOUNT_POINT);
  if (isAnonymous) {
    mountPoint.innerHTML = '';
  } else {
    mountPoint.innerHTML =
      `<a href="/submissions/${htmlEscape(submission.id)}/comments.pdf" target="_blank">${htmlEscape(I18n.t('Download Submission Comments'))}</a>`;
  }
  return mountPoint;
}

// Public Variables and Methods
EG = {
  currentStudent: null,
  refreshGrades,

  domReady: function(){
    $moderation_tabs_div.tabs({
      activate: function(event, ui) {
        var index = ui.newTab.data('pg-index')
        if (index != 'final') {
          index = parseInt(index);
        }
        EG.showProvisionalGrade(index);
      }
    });
    $moderation_tabs.each(function(index) {
      if (index == 2) index = "final"; // this will make it easier to identify the final mark

      $(this).find('a').click(function(e) {
        e.preventDefault();
        EG.showProvisionalGrade(index);
      });
      $('<i class="icon-check selected_icon"></i>').prependTo($(this).find('.mark_title'));
      $('<button class="Button" role="button"></button>').text(I18n.t('Select')).appendTo($(this)).on('click keyclick', function(){
        EG.selectProvisionalGrade(index);
      });
    });
    $new_mark_link.click(function(e){ e.preventDefault(); EG.newProvisionalGrade('new', 1)} );
    $new_mark_final_link.click(function(e){ e.preventDefault(); EG.newProvisionalGrade('new', 'final')} );
    $new_mark_copy_link1.click(function(e){ e.preventDefault(); EG.newProvisionalGrade('copy', 0)} );
    $new_mark_copy_link2.click(function(e){ e.preventDefault(); EG.newProvisionalGrade('copy', 1)} );

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

    if (ENV.can_comment_on_submission) {
      initCommentBox()
    }

    EG.initComments();
    header.init();
    initKeyCodes();

    $('.dismiss_alert').click(function(e){
      e.preventDefault();
      $(this).closest(".alert").hide();
    });

    setupHandleFragmentChanged()
    $('#eg_sort_by').val(userSettings.get('eg_sort_by'));
    $('#submit_same_score').click(function(e) {
      // By passing true as the second argument, we're telling
      // handleGradeSubmit to use the existing previous submission score
      // for the current grade.
      EG.handleGradeSubmit(e, true);
      e.preventDefault();
    });

    setupBeforeLeavingSpeedgrader()
  },

  jsonReady: function(){
    isAnonymous = setupIsAnonymous(jsonData)
    isModerated = setupIsModerated(jsonData)
    anonymousGraders = setupAnonymousGraders(jsonData)
    anonymizableId = setupAnonymizableId(isAnonymous)
    anonymizableUserId = setupAnonymizableUserId(isAnonymous)
    anonymizableStudentId = setupAnonymizableStudentId(isAnonymous)
    anonymizableAuthorId = setupAnonymizableAuthorId(isAnonymous)

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
      EG.handleFragmentChanged();
    }
  },

  skipRelativeToCurrentIndex: function(offset){
    const {length: students} = jsonData.studentsWithSubmissions
    const newIndex = (this.currentIndex() + offset + students) % students;

    this.goToStudent(jsonData.studentsWithSubmissions[newIndex][anonymizableId])
  },

  next: function(){
    this.skipRelativeToCurrentIndex(1);
    var studentInfo = this.getStudentNameAndGrade();
    $("#aria_name_alert").text(studentInfo);
  },

  prev: function(){
    this.skipRelativeToCurrentIndex(-1);
    var studentInfo = this.getStudentNameAndGrade();
    $("#aria_name_alert").text(studentInfo);
  },

  getStudentNameAndGrade: (student = EG.currentStudent) => {
    let studentName;
    if (utils.shouldHideStudentNames()) {
      studentName = I18n.t('student_index', "Student %{index}", { index: student.index + 1 });
    } else {
      studentName = student.name;
    }

    const submissionStatus = SpeedgraderHelpers.classNameBasedOnStudent(student);
    return `${studentName} - ${submissionStatus.formatted}`;
  },

  toggleFullRubric: function(force){
    const rubricFull = selectors.get('#rubric_full');
    // if there is no rubric associated with this assignment, then the edit
    // rubric thing should never be shown.  the view should make sure that
    // the edit rubric html is not even there but we also want to make sure
    // that pressing "r" wont make it appear either
    if (!jsonData.rubric_association){ return false; }

    if (rubricFull.filter(":visible").length || force === "close") {
      $("#grading").show().height("auto");
      rubricFull.fadeOut();
      $(".toggle_full_rubric").focus()
    } else {
      rubricFull.fadeIn();
      $("#grading").hide();
      this.refreshFullRubric();
      rubricFull.find('.rubric_title .title').focus()
    }
  },

  refreshFullRubric: function() {
    const rubricFull = selectors.get('#rubric_full');
    if (!jsonData.rubric_association) { return; }
    if (!rubricFull.filter(":visible").length) { return; }

    const container = rubricFull.find(".rubric")
    rubricAssessment.populateNewRubric(container, rubricAssessmentToPopulate(), jsonData.rubric_association)
    $("#grading").height(rubricFull.height());
  },

  handleFragmentChanged () {
    var hash;
    try {
      // get rid of the first character "#" of the hash
      hash = JSON.parse(decodeURIComponent(document.location.hash.substr(1)));
    } catch(e) {}
    if (!hash) {
      hash = {};
    }

    // if anonymous, don't bother with rep_for_student because group assignments are disabled with anonymous
    // moderated marking, otherwise use the group representative if possible
    let representativeOrStudentId = {
      true: hash[anonymizableStudentId],
      false: jsonData.context.rep_for_student[hash[anonymizableStudentId]] || hash[anonymizableStudentId]
    }[isAnonymous]

    // choose the first ungraded student if the requested one doesn't exist
    if (!jsonData.studentMap[representativeOrStudentId]) {
      var ungradedStudent = _(jsonData.studentsWithSubmissions)
        .find(function(s) {
          return s.submission &&
            s.submission.workflow_state != 'graded' &&
            s.submission.submission_type;
        });
      representativeOrStudentId = (ungradedStudent || jsonData.studentsWithSubmissions[0])[anonymizableId];
    }

    if (hash.provisional_grade_id) {
      EG.selected_provisional_grade_id = hash.provisional_grade_id;
    } else if (hash.add_review) {
      EG.add_review = true;
    }
    EG.goToStudent(representativeOrStudentId);
  },

  goToStudent (studentIdentifier) {
    const hideStudentNames = utils.shouldHideStudentNames();
    const student = jsonData.studentMap[studentIdentifier]

    if (student) {
      $selectmenu.selectmenu("value", student[anonymizableId]);
      if (!this.currentStudent || this.currentStudent[anonymizableId] !== student[anonymizableId]) {
        // manually tell $selectmenu to fire the change event
        $selectmenu.change();
      }

      if (hideStudentNames || isAnonymous || !student.avatar_path) {
        $avatar_image.hide()
      } else {
        // If there's any kind of delay in loading the user's avatar, it's
        // better to show a blank image than the previous student's image.
        const $new_image = $avatar_image.clone().show();
        $avatar_image.after($new_image.attr('src', student.avatar_path)).remove();
        $avatar_image = $new_image;
      }
    }
  },

  currentIndex: function(){
    return $.inArray(this.currentStudent, jsonData.studentsWithSubmissions);
  },

  handleStudentChanged: function(){
    // Save any draft comments before loading the new student
    if ($add_a_comment_textarea.hasClass('ui-state-disabled')) {
      $add_a_comment_textarea.val('');
    } else {
      EG.addSubmissionComment(true);
    }

    const selectMenuValue = $selectmenu.val();
    // calling _.values on a large collection could be slow, that's why we're fetching from studentMap first
    this.currentStudent = jsonData.studentMap[selectMenuValue] || _.values(jsonData.studentsWithSubmissions)[0];

    const hash = {[anonymizableStudentId]: this.currentStudent[anonymizableId]}
    document.location.hash = `#${encodeURIComponent(JSON.stringify(hash))}`

    // On the switch to a new student, clear the state of the last
    // question touched on the previous student.
    INST.lastQuestionTouched = null;

    if ((ENV.grading_role == 'provisional_grader' && this.currentStudent.submission_state == 'not_graded')
        || ENV.grading_role == 'moderator') {

      $(".speedgrader_alert").hide();
      $submission_not_newest_notice.hide();
      $submission_late_notice.hide();
      $full_width_container.removeClass("with_enrollment_notice");
      $enrollment_inactive_notice.hide();
      $enrollment_concluded_notice.hide();
      selectors.get('#closed_gp_notice').hide()

      EG.setGradeReadOnly(true); // disabling now will keep it from getting undisabled unintentionally by disableWhileLoading
      if (ENV.grading_role == 'moderator' && this.currentStudent.submission_state == 'not_graded') {
        this.currentStudent.submission.grade = null; // otherwise it may be tricked into showing the wrong submission_state
      }

      // check whether we still can give a provisional grade
      $full_width_container.disableWhileLoading(this.fetchProvisionalGrades());
    } else {
      this.showStudent();
    }
  },

  setCurrentStudentRubricAssessments () {
    // currentStudent.rubric_assessments only includes assessments submitted
    // by the current user, so if the viewer is a moderator, get other
    // graders' assessments from their provisional grades.
    const provisionalAssessments = []

    // If the moderator has just saved a new assessment, this array will have
    // entries not present elsewhere, so don't clobber them.
    const currentAssessmentsById = {}
    if (this.currentStudent.rubric_assessments) {
      this.currentStudent.rubric_assessments.forEach(assessment => {
        currentAssessmentsById[assessment.id] = true
      })
    }

    currentStudentProvisionalGrades().forEach(grade => {
      // TODO: decide what to do if a provisional grade contains multiple
      // assessments (currently we're not sure if this can actually happen
      // for a moderated assignment).
      if (grade.rubric_assessments && grade.rubric_assessments.length > 0) {
        // Add the assessor display name to the assessment while we have easy
        // access to the provisional grade data
        const assessment = grade.rubric_assessments[0]
        assessment.assessor_name = provisionalGraderDisplayNames[grade.provisional_grade_id]
        if (!currentAssessmentsById[assessment.id]) {
          provisionalAssessments.push(assessment)
        }
      }
    })

    if (provisionalAssessments.length > 0) {
      if (!this.currentStudent.rubric_assessments) {
        this.currentStudent.rubric_assessments = []
      }

      this.currentStudent.rubric_assessments = this.currentStudent.rubric_assessments.concat(provisionalAssessments)
    }

    if (anonymousGraders) {
      this.currentStudent.rubric_assessments.sort((a, b) => natcompare.strings(a.anonymous_assessor_id, b.anonymous_assessor_id))
    }
  },

  showStudent: function(){
    $rightside_inner.scrollTo(0);
    if (this.currentStudent.submission_state == 'not_gradeable' && ENV.grading_role == "provisional_grader") {
      $rightside_inner.hide();
      $not_gradeable_message.show();
    } else {
      $not_gradeable_message.hide();
      $rightside_inner.show();
    }
    if (ENV.grading_role == "moderator") {
      this.renderProvisionalGradeSelector({showingNewStudent: true})
      this.setCurrentStudentRubricAssessments()

      this.current_prov_grade_index = null;
      this.removeModerationBarAndShowSubmission();

      const selectedGrade = currentStudentProvisionalGrades().find(grade => grade.selected);
      if (selectedGrade) {
        this.setActiveProvisionalGradeFields({
          label: provisionalGraderDisplayNames[selectedGrade.provisional_grade_id],
          grade: selectedGrade
        });
      } else {
        this.setActiveProvisionalGradeFields();
      }
    } else {
      // showSubmissionOverride is optionally set if the user is
      // using the quizzes.next lti tool. Rather than reload the tool based
      // on a new URL, it just dispatches a message to tell the tool to
      // change itself
      var changeSubmission = showSubmissionOverride || this.showSubmission.bind(this);
      changeSubmission(this.currentStudent.submission);
    }
  },

  showSubmission: function(){
    this.showGrade();
    this.showDiscussion();
    this.showRubric({validateEnteredData: false});
    this.updateStatsInHeader();
    this.showSubmissionDetails();
    this.refreshFullRubric();
  },

  removeModerationBarAndShowSubmission() {
    $full_width_container.removeClass("with_moderation_tabs")
    $moderation_bar.hide()
    this.showSubmission()
    this.setReadOnly(false)
  },

  updateModerationTabs: function() {
    if (!this.currentStudent.submission) return;
    var prov_grades = this.currentStudent.submission.provisional_grades;

    this.updateModerationTab($moderation_tabs.eq(0), prov_grades && prov_grades[0]);
    this.updateModerationTab($moderation_tabs.eq(1), prov_grades && prov_grades[1]);
    this.updateModerationTab($moderation_tab_final, this.currentStudent.submission.final_provisional_grade);
  },

  updateModerationTab: function($tab, prov_grade) {
    var CHOSEN_GRADE_MESSAGE = I18n.t('This is the currently chosen grade for this student.');
    var $srMessage = $('<span class="selected_sr_message screenreader-only"></span>').text(CHOSEN_GRADE_MESSAGE);
    if (prov_grade && prov_grade.selected) {
      $tab.addClass('selected');
      // Remove an old message, should it be there
      $tab.find('.selected_sr_message').remove();
      $tab.find('.mark_title').prepend($srMessage);
    } else {
      $tab.removeClass('selected');
      $tab.find('.selected_sr_message').remove();
    }

    if (prov_grade && prov_grade.provisional_grade_id) {
      $tab.removeClass('pending');
    } else {
      $tab.addClass('pending');
    }

    var $mark_grade = $tab.find('.mark_grade');
    if (prov_grade && prov_grade.score) {
      $mark_grade.html(htmlEscape(I18n.n(prov_grade.score) + '/' + I18n.n(window.jsonData.points_possible)));
    } else {
      $mark_grade.empty();
    }
  },

  showProvisionalGrade: function(idx) {
    if (this.current_prov_grade_index != idx) {

      this.current_prov_grade_index = idx;
      var prov_grade;
      if (idx == 'final') {
        prov_grade = this.currentStudent.submission.final_provisional_grade;
      } else {
        prov_grade = this.currentStudent.submission.provisional_grades[idx];
      }

      // merge in the provisional attributes
      $.extend(this.currentStudent.submission, prov_grade);

      this.currentStudent.rubric_assessments = prov_grade.rubric_assessments;
      this.currentStudent.provisional_crocodoc_urls = prov_grade.crocodoc_urls;
      this.showSubmission();

      // set read-only if needed
      this.setReadOnly(prov_grade.readonly);
    }
  },

  newProvisionalGrade: function(type, index) {
    if (type == 'new')  {
      var new_mark = {
        'grade': null,
        'score': null,
        'graded_at': null,
        'final': false,
        'grade_matches_current_submission': true,
        'scorer_id': ENV.current_user_id,
        'rubric_assessments': []
      };
      if (index == 1) {
        this.currentStudent.submission.provisional_grades.push(new_mark);
      } else if (index == 'final') {
        this.currentStudent.submission.final_provisional_grade = new_mark;
      }
      this.removeModerationBarAndShowSubmission();
    } else if (type == 'copy') {
      if (!this.currentStudent.submission.final_provisional_grade ||
          confirm(I18n.t("Are you sure you want to copy to the final mark? This will overwrite the existing mark."))) {
        var grade_to_copy = this.currentStudent.submission.provisional_grades[index];
        $full_width_container.disableWhileLoading(
          $.ajaxJSON($.replaceTags(ENV.provisional_copy_url, {provisional_grade_id: grade_to_copy.provisional_grade_id}), "POST",  {}, function(data) {
            $.each(EG.currentStudent.submission.provisional_grades, function(i, pg) { pg.selected = false; });

            EG.currentStudent.submission.final_provisional_grade = data;
            EG.currentStudent.submission_state =
              SpeedgraderHelpers.submissionState(EG.currentStudent, ENV.grading_role);
            EG.current_prov_grade_index = null;
            this.removeModerationBarAndShowSubmission();
            EG.updateModerationTabs();
            $moderation_tab_final.focus();
          })
        );
      }
    }
  },

  selectProvisionalGrade: function(index) {
    var prov_grade, $tab;
    if (index == 'final') {
      prov_grade = this.currentStudent.submission.final_provisional_grade;
      $tab = $moderation_tab_final
    } else {
      prov_grade = this.currentStudent.submission.provisional_grades[index];
      $tab = $moderation_tabs.eq(index);
    }
    $full_width_container.disableWhileLoading(
      $.ajaxJSON($.replaceTags(ENV.provisional_select_url, {provisional_grade_id: prov_grade.provisional_grade_id}), "PUT",  {}, function(data) {
        $.each(EG.currentStudent.submission.provisional_grades, function(i, pg) { pg.selected = false; });
        if (EG.currentStudent.submission.final_provisional_grade) {
          EG.currentStudent.submission.final_provisional_grade.selected = false;
        }
        prov_grade.selected = true;
        EG.updateModerationTabs();
        $tab.focus();
      })
    );
  },

  setGradeReadOnly: function(readonly) {
    if (readonly) {
      $grade.addClass('ui-state-disabled').attr('readonly', true).attr('aria-disabled', true).prop('disabled', true);
    } else {
      $grade.removeClass('ui-state-disabled').removeAttr('aria-disabled').removeAttr('readonly').removeProp('disabled');
    }
  },

  setUpAssessmentAuditTray() {
    const bindRef = ref => {
      EG.assessmentAuditTray = ref
    }

    const tray = <AssessmentAuditTray ref={bindRef} />
    ReactDOM.render(tray, document.getElementById(ASSESSMENT_AUDIT_TRAY_MOUNT_POINT))

    const onClick = () => {
      const {submission} = this.currentStudent

      EG.assessmentAuditTray.show({
        assignment: {
          gradesPublishedAt: jsonData.grades_published_at,
          id: ENV.assignment_id,
          pointsPossible: jsonData.points_possible
        },
        courseId: ENV.course_id,
        submission: {
          id: submission.id,
          score: submission.score
        }
      })
    }

    const button = <AssessmentAuditButton onClick={onClick} />
    ReactDOM.render(button, document.getElementById(ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT))
  },

  tearDownAssessmentAuditTray() {
    ReactDOM.unmountComponentAtNode(document.getElementById(ASSESSMENT_AUDIT_TRAY_MOUNT_POINT))
    ReactDOM.unmountComponentAtNode(document.getElementById(ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT))
    EG.assessmentAuditTray = null
  },

  setReadOnly: function(readonly) {
    if (readonly) {
      EG.setGradeReadOnly(true);
      $comments.find(".delete_comment_link").hide();
      $add_a_comment.hide();
    } else {
      // $grade will be disabled/enabled in showGrade()
      // $comments will be reconstructed
      $add_a_comment.show();
    }
  },

  populateTurnitin: function(submission, assetString, turnitinAsset, $turnitinScoreContainer, $turnitinInfoContainer, isMostRecent) {
    var $turnitinSimilarityScore = null;
    const showLegacyResubmit = isMostRecent && !submission.has_plagiarism_tool;

    // build up new values based on this asset
    if (turnitinAsset.status == 'scored' || (turnitinAsset.status == null && turnitinAsset.similarity_score != null)) {
      const urlContainer = SpeedgraderHelpers.urlContainer(
        submission,
        $assignment_submission_turnitin_report_url,
        $assignment_submission_originality_report_url
      )
      const reportUrl = $.replaceTags(
        urlContainer.attr('href'),
        {
          [anonymizableUserId]: submission[anonymizableUserId],
          asset_string: assetString
        }
      )
      const tooltip = I18n.t('Similarity Score - See detailed report')

      $turnitinScoreContainer.html(turnitinScoreTemplate({
        state: (turnitinAsset.state || 'no') + '_score',
        reportUrl,
        tooltip,
        score: turnitinAsset.similarity_score + '%'
      }));
    } else if (turnitinAsset.status) {
      // status == 'error' or status == 'pending'
      var pendingTooltip = I18n.t('turnitin.tooltip.pending', 'Similarity Score - Submission pending'),
      errorTooltip = I18n.t('turnitin.tooltip.error', 'Similarity Score - See submission error details');
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
                                      'This file is still being processed by the plagiarism detection tool associated with the assignment. Please check back later to see the score.'),
      defaultErrorMessage = I18n.t('turnitin.error_message',
                                   'There was an error submitting to the similarity detection service. Please try resubmitting the file before contacting support.');
      var $turnitinInfo = $(turnitinInfoTemplate({
        assetString: assetString,
        message: (turnitinAsset.status == 'error' ? (turnitinAsset.public_error_message || defaultErrorMessage) : defaultInfoMessage),
        showResubmit: showLegacyResubmit
      }));
      $turnitinInfoContainer.append($turnitinInfo);

      if (showLegacyResubmit) {
        const resubmitUrl = SpeedgraderHelpers.plagiarismResubmitUrl(submission, anonymizableUserId)
        $('.turnitin_resubmit_button').on('click', (e) => { SpeedgraderHelpers.plagiarismResubmitHandler(e, resubmitUrl) });
      }
    }
  },
  populateVeriCite: function(submission, assetString, vericiteAsset, $vericiteScoreContainer, $vericiteInfoContainer, isMostRecent) {
    var $vericiteSimilarityScore = null;

    // build up new values based on this asset
    if (vericiteAsset.status == 'scored' || (vericiteAsset.status == null && vericiteAsset.similarity_score != null)) {
      let reportUrl
      let tooltip
      if (!isAnonymous) {
        reportUrl = $.replaceTags(
          $assignment_submission_vericite_report_url.attr('href'),
          { user_id: submission.user_id, asset_string: assetString }
        )
        tooltip = I18n.t('VeriCite Similarity Score - See detailed report')
      } else {
        tooltip = anonymousAssignmentDetailedReportTooltip
      }

      $vericiteScoreContainer.html(vericiteScoreTemplate({
        state: (vericiteAsset.state || 'no') + '_score',
        reportUrl,
        tooltip,
        score: vericiteAsset.similarity_score + '%'
      }));
    } else if (vericiteAsset.status) {
      // status == 'error' or status == 'pending'
      var pendingTooltip = I18n.t('vericite.tooltip.pending', 'VeriCite Similarity Score - Submission pending'),
      errorTooltip = I18n.t('vericite.tooltip.error', 'VeriCite Similarity Score - See submission error details');
      $vericiteSimilarityScore = $(vericiteScoreTemplate({
        state: 'submission_' + vericiteAsset.status,
        reportUrl: '#',
        tooltip: (vericiteAsset.status == 'error' ? errorTooltip : pendingTooltip),
        icon: '/images/turnitin_submission_' + vericiteAsset.status + '.png'
      }));
      $vericiteScoreContainer.append($vericiteSimilarityScore);
      $vericiteSimilarityScore.click(function(event) {
        event.preventDefault();
        $vericiteInfoContainer.find('.vericite_'+assetString).slideToggle();
      });

      var defaultInfoMessage = I18n.t('vericite.info_message',
                                      'This file is still being processed by VeriCite. Please check back later to see the score'),
      defaultErrorMessage = I18n.t('vericite.error_message',
                                   'There was an error submitting to VeriCite. Please try resubmitting the file before contacting support');
      var $vericiteInfo = $(vericiteInfoTemplate({
        assetString: assetString,
        message: (vericiteAsset.status == 'error' ? (vericiteAsset.public_error_message || defaultErrorMessage) : defaultInfoMessage),
        showResubmit: vericiteAsset.status == 'error' && isMostRecent
      }));
      $vericiteInfoContainer.append($vericiteInfo);

      if (vericiteAsset.status == 'error' && isMostRecent) {
        const resubmitUrl = $.replaceTags(
          $assignment_submission_resubmit_to_vericite_url.attr('href'),
          { user_id: submission[anonymizableUserId] }
        )
        $vericiteInfo.find('.vericite_resubmit_button').click(function(event) {
          event.preventDefault();
          $(this).attr('disabled', true)
            .text(I18n.t('vericite.resubmitting', 'Resubmitting...'));

          $.ajaxJSON(resubmitUrl, "POST", {}, function() {
            SpeedgraderHelpers.reloadPage();
          });
        });
      }
    }
  },

  handleSubmissionSelectionChange: function(){
    clearInterval(sessionTimer);

    function currentIndex (context, submissionToViewVal) {
      if (submissionToViewVal) {
        return Number(submissionToViewVal);
      } else if (context.currentStudent &&
        context.currentStudent.submission &&
        context.currentStudent.submission.currentSelectedIndex ) {

        return context.currentStudent.submission.currentSelectedIndex;
      }
      return 0;
    };

    const $submission_to_view = $("#submission_to_view")
    const submissionToViewVal = $submission_to_view.val()
    const currentSelectedIndex = currentIndex(this, submissionToViewVal)
    const submissionHolder = this.currentStudent && this.currentStudent.submission
    const submissionHistory = submissionHolder && submissionHolder.submission_history
    const isMostRecent = submissionHistory && submissionHistory.length - 1 === currentSelectedIndex
    const inlineableAttachments = []
    const browserableAttachments = []

    let submission = {}
    if (submissionHistory && submissionHistory[currentSelectedIndex]) {
      submission = submissionHistory[currentSelectedIndex].submission || submissionHistory[currentSelectedIndex]
    }

    var turnitinEnabled = submission.turnitin_data && (typeof submission.turnitin_data.provider === 'undefined');
    var vericiteEnabled = submission.turnitin_data && submission.turnitin_data.provider === 'vericite';

    SpeedgraderHelpers.plagiarismResubmitButton(
      submission.has_originality_score,
      $('#plagiarism_platform_info_container')
    )

    if (!submission.has_originality_score) {
      const resubmitUrl = SpeedgraderHelpers.plagiarismResubmitUrl(submission, anonymizableUserId)
      $('#plagiarism_resubmit_button').off('click')
      $('#plagiarism_resubmit_button').on('click', (e) => { SpeedgraderHelpers.plagiarismResubmitHandler(e, resubmitUrl) })
    }

    if(vericiteEnabled){
      var $vericiteScoreContainer = $grade_container.find(".turnitin_score_container").empty(),
      $vericiteInfoContainer = $grade_container.find(".turnitin_info_container").empty(),
      assetString = 'submission_' + submission.id,
      vericiteAsset = vericiteEnabled && submission.turnitin_data && submission.turnitin_data[assetString];
      // There might be a previous submission that was text_entry, but the
      // current submission is an upload. The vericite asset for the text
      // entry would still exist
      if (vericiteAsset && submission.submission_type == 'online_text_entry') {
        EG.populateVeriCite(submission, assetString, vericiteAsset, $vericiteScoreContainer, $vericiteInfoContainer, isMostRecent);
      }
    }else{
      //default to TII
      var $turnitinScoreContainer = $grade_container.find(".turnitin_score_container").empty(),
      $turnitinInfoContainer = $grade_container.find(".turnitin_info_container").empty(),
      assetString = 'submission_' + submission.id,
      turnitinAsset = turnitinEnabled && submission.turnitin_data && submission.turnitin_data[assetString];
      // There might be a previous submission that was text_entry, but the
      // current submission is an upload. The turnitin asset for the text
      // entry would still exist
      if (turnitinAsset && submission.submission_type == 'online_text_entry') {
        EG.populateTurnitin(submission, assetString, turnitinAsset, $turnitinScoreContainer, $turnitinInfoContainer, isMostRecent);
      }
    }

    //handle the files
    $submission_files_list.empty();
    $turnitinInfoContainer = $("#submission_files_container .turnitin_info_container").empty();
    $vericiteInfoContainer = $("#submission_files_container .turnitin_info_container").empty();
    $.each(submission.versioned_attachments || [], function(i,a){
      var attachment = a.attachment;
      if ((attachment.crocodoc_url || attachment.canvadoc_url) && EG.currentStudent.provisional_crocodoc_urls) {
        let urlInfo = _.find(EG.currentStudent.provisional_crocodoc_urls, function(url) {
          return url.attachment_id == attachment.id;
        })
        attachment.provisional_crocodoc_url = urlInfo.crocodoc_url;
        attachment.provisional_canvadoc_url = urlInfo.canvadoc_url;
      } else {
        attachment.provisional_crocodoc_url = null;
        attachment.provisional_canvadoc_url = null;
      }
      if (attachment.crocodoc_url ||
          attachment.canvadoc_url ||
          $.isPreviewable(attachment.content_type, 'google')) {
        inlineableAttachments.push(attachment);
      }

      let viewedAtHTML = ''
      if (!jsonData.anonymize_students || isAdmin) {
        viewedAtHTML = studentViewedAtTemplate({
          viewed_at: $.datetimeString(attachment.viewed_at)
        })
      }
      $submission_attachment_viewed_at.html($.raw(viewedAtHTML));

      if (browserableCssClasses.test(attachment.mime_class)) {
        browserableAttachments.push(attachment);
      }
      const anonymizableSubmissionIdKey = isAnonymous ? 'anonymousId' : 'submissionId';
      var $submission_file = $submission_file_hidden.clone(true).fillTemplateData({
        data: {
          [anonymizableSubmissionIdKey]: submission[anonymizableUserId],
          attachmentId: attachment.id,
          display_name: attachment.display_name,
          attachmentWorkflow: attachment.workflow_state
        },
        hrefValues: [anonymizableSubmissionIdKey, 'attachmentId']
      }).appendTo($submission_files_list)
        .find('a.display_name')
        .data('attachment', attachment)
        .click(function(event){
          event.preventDefault();
          EG.loadSubmissionPreview($(this).data('attachment'), null);
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
      turnitinAsset = turnitinEnabled && submission.turnitin_data && submission.turnitin_data[assetString];
      if (turnitinAsset) {
        EG.populateTurnitin(submission, assetString, turnitinAsset, $turnitinScoreContainer, $turnitinInfoContainer, isMostRecent);
      }
      $vericiteScoreContainer = $submission_file.find(".turnitin_score_container");
      assetString = 'attachment_' + attachment.id;
      vericiteAsset = vericiteEnabled && submission.turnitin_data && submission.turnitin_data[assetString];
      if (vericiteAsset) {
        EG.populateVeriCite(submission, assetString, vericiteAsset, $vericiteScoreContainer, $vericiteInfoContainer, isMostRecent);
      }

      renderProgressIcon(attachment);
    });

    $submission_files_container.showIf(submission.versioned_attachments && submission.versioned_attachments.length);

    var preview_attachment = null;
    if (submission.submission_type != 'discussion_topic') {
      preview_attachment = inlineableAttachments[0] || browserableAttachments[0];
    }

    // load up a preview of one of the attachments if we can.
    this.loadSubmissionPreview(preview_attachment, submission);
    renderSubmissionCommentsDownloadLink(submission);

    // if there is any submissions after this one, show a notice that they are not looking at the newest
    $submission_not_newest_notice.showIf($submission_to_view.filter(":visible").find(":selected").nextAll().length);

    $submission_late_notice.showIf(submission['late']);
    $full_width_container.removeClass("with_enrollment_notice");
    $enrollment_inactive_notice.showIf(
      _.any(jsonData.studentMap[this.currentStudent[anonymizableId]].enrollments, (enrollment) => {
        if(enrollment.workflow_state === 'inactive') {
          $full_width_container.addClass("with_enrollment_notice");
          return true;
        }
        return false;
      })
    );

    const isConcluded = EG.isStudentConcluded(this.currentStudent[anonymizableId]);
    $enrollment_concluded_notice.showIf(isConcluded);

    const gradingPeriod = jsonData.gradingPeriods[(submissionHolder || {}).grading_period_id]
    const isClosedForSubmission = !!gradingPeriod && gradingPeriod.is_closed
    selectors.get('#closed_gp_notice').showIf(isClosedForSubmission)
    SpeedgraderHelpers.setRightBarDisabled(isConcluded);
    EG.setGradeReadOnly((typeof submissionHolder != "undefined" &&
                         submissionHolder.submission_type === "online_quiz") ||
                        isConcluded ||
                        (isClosedForSubmission && !isAdmin));

    if (isConcluded || isClosedForSubmission) {
      $full_width_container.addClass("with_enrollment_notice");
    }
  },

  isStudentConcluded (student) {
    if (!jsonData.studentMap) {
      return false;
    }

    return _.any(jsonData.studentMap[student].enrollments, (enrollment) =>
      enrollment.workflow_state === 'completed'
    );
  },

  refreshSubmissionsToView: function(){
    let innerHTML
    let s = this.currentStudent.submission;
    let submissionHistory;
    let noSubmittedAt;
    let selectedIndex;

    if (s && s.submission_history && s.submission_history.length > 0) {
      submissionHistory = s.submission_history;
      noSubmittedAt = I18n.t('no_submission_time', 'no submission time');
      selectedIndex = parseInt($('#submission_to_view').val() ||
                               submissionHistory.length - 1,
                               10);
      var templateSubmissions = _(submissionHistory).map(function(o, i) {
        // The submission objects nested in the submission_history array
        // can have two different shapes, because the `this.currentStudent.submission`
        // can come from two different API endpoints.
        //
        // Shape one:
        //
        // ```
        // [{
        //   submission: {
        //     grade: 100,
        //     ...other submission keys
        //   }
        // }]
        // ```
        //
        // Shape two:
        //
        // ```
        // [{
        //   grade: 100,
        //   ...other submission keys
        // }]
        // ```
        //
        // This little dance here is to make sure we can accommodate both.
        if (Object.prototype.hasOwnProperty.call(o, 'submission')) {
          s = o.submission;
        } else {
          s = o
        }

        var grade;

        if (s.grade && (s.grade_matches_current_submission ||
                        s.show_grade_in_dropdown)) {
          grade = GradeFormatHelper.formatGrade(s.grade);
        }

        return {
          value: i,
          late: s.late,
          missing: s.missing,
          selected: selectedIndex === i,
          submittedAt: $.datetimeString(s.submitted_at) || noSubmittedAt,
          grade: grade
        };
      });

      innerHTML = submissionsDropdownTemplate({
        showSubmissionStatus: !jsonData.anonymize_students || isAdmin,
        singleSubmission: submissionHistory.length == 1,
        submissions: templateSubmissions,
        linkToQuizHistory: jsonData.too_many_quiz_submissions,
        quizHistoryHref: $.replaceTags(ENV.quiz_history_url,
                                       {user_id: this.currentStudent[anonymizableId]})
      });
    }
    $multiple_submissions.html($.raw(innerHTML));
    StatusPill.renderPills();
  },

  showSubmissionDetails: function(){
    // if there is a submission
    var currentSubmission = this.currentStudent.submission;
    if (currentSubmission && currentSubmission.workflow_state !== 'unsubmitted') {
      this.refreshSubmissionsToView();
      var lastIndex = currentSubmission.submission_history.length - 1;
      $("#submission_to_view option:eq(" + lastIndex + ")").attr("selected", "selected");
      $submission_details.show();
    } else { // there's no submission
      $submission_details.hide();
    }
    this.handleSubmissionSelectionChange();
  },

  updateStatsInHeader: function(){
    var outOf = '';
    var percent;
    var gradedStudents = $.grep(window.jsonData.studentsWithSubmissions, function (s) {
      return (s.submission_state === 'graded' || s.submission_state === 'not_gradeable');
    });

    $x_of_x_students.text(
      I18n.t('%{x}/%{y}', {
        x: I18n.n(EG.currentIndex() + 1),
        y: I18n.n(this.totalStudentCount())
      })
    );
    $("#gradee").text(gradeeLabel);

    var scores = $.map(gradedStudents , function(s){
      return s.submission.score;
    });

    if (scores.length) { //if there are some submissions that have been graded.
      $average_score_wrapper.show();
      var avg = function (arr) {
        var sum = 0;
        for (var i = 0, j = arr.length; i < j; i++) {
          sum += arr[i];
        }
        return sum / arr.length;
      }
      var roundWithPrecision = function (number, precision) {
        precision = Math.abs(parseInt(precision, 10)) || 0;
        var coefficient = Math.pow(10, precision);
        return Math.round(number*coefficient)/coefficient;
      }

      if (window.jsonData.points_possible) {
        percent = I18n.n(
          Math.round(100 * (avg(scores) / window.jsonData.points_possible)),
          { percentage: true }
        );

        outOf = [' / ', I18n.n(window.jsonData.points_possible), ' (', percent, ')'].join('');
      }

      $average_score.text([I18n.n(roundWithPrecision(avg(scores), 2)) + outOf].join(''));
    }
    else { //there are no submissions that have been graded.
      $average_score_wrapper.hide();
    }

    $grded_so_far.text(
      I18n.t('portion_graded', '%{x}/%{y}', {
        x: I18n.n(gradedStudents.length),
        y: I18n.n(window.jsonData.context.students.length)
      })
    );
  },

  totalStudentCount: function(){
    if (sectionToShow) {
      return _.filter(jsonData.context.students, function(student) {return _.contains(student.section_ids, sectionToShow)}).length;
    } else {
      return jsonData.context.students.length;
    };
  },

  progressSubmissionPreview (attachment) {
    if (attachment === undefined) {
      return [
        <FailedUploadTreeKite />,
        I18n.t("Upload Failed"),
        I18n.t("Please have the student submit the file again")
      ]
    } else {
      return [
        <WaitingWristWatch />,
        I18n.t("Uploading"),
        I18n.t("Canvas is attempting to retreive the submissions. Please check back again later.")
      ]
    }
  },

  loadSubmissionPreview: function(attachment, submission) {
    clearInterval(sessionTimer);
    $submissions_container.children().hide();
    $(".speedgrader_alert").hide();
    if (!this.currentStudent.submission ||
        !this.currentStudent.submission.submission_type ||
        this.currentStudent.submission.workflow_state === 'unsubmitted') {
      $this_student_does_not_have_a_submission.show();
      this.emptyIframeHolder()
    } else if (this.currentStudent.submission && this.currentStudent.submission.submitted_at && jsonData.context.quiz && jsonData.context.quiz.anonymous_submissions) {
      $this_student_has_a_submission.show();
    } else if (attachment) {
      this.renderAttachment(attachment);
    } else if (submission && submission.submission_type === 'basic_lti_launch') {
      this.renderLtiLaunch($iframe_holder, ENV.lti_retrieve_url, submission.external_tool_url || submission.url);
    } else if (this.canDisplaySpeedGraderImagePreview(jsonData.context, attachment, submission)){
        this.emptyIframeHolder()
        const mountPoint = document.getElementById('iframe_holder');
        mountPoint.style = "";
        const state = this.progressSubmissionPreview(attachment);
        ReactDOM.render((
          <View margin="large" display="block" as="div" textAlign="center">
            { state[0] }
            <Text weight="bold" size="large" as="div">
              { state[1] }
            </Text>
            <Text size="medium" as="div">
              { state[2] }
            </Text>
          </View>
        ), mountPoint);
    } else {
      this.renderSubmissionPreview();
    }
  },

  canDisplaySpeedGraderImagePreview (context, attachment, submission) {
    const type = submission.submission_type;
    return !context.quiz &&
           (type !== 'online_text_entry' && type !== 'media_recording' && type !== 'online_url') &&
           attachment === undefined &&
           (submission !== undefined || attachment.workflow_state === 'pending_upload')
  },

  emptyIframeHolder: function(elem) {
    elem = elem || $iframe_holder
    elem.empty();
  },

  //load in the iframe preview.  if we are viewing a past version of the file pass the version to preview in the url
  renderSubmissionPreview (domElement = 'iframe') {
    // TODO: this is duplicate code from line 1972 and should be removed
    if (!this.currentStudent.submission) {
      $this_student_does_not_have_a_submission.show();
      return
    }
    this.emptyIframeHolder()
    const {context_id: courseId} = jsonData
    const {assignment_id: assignmentId} = this.currentStudent.submission
    const anonymizableSubmissionId = this.currentStudent.submission[anonymizableUserId]
    const resourceSegment = isAnonymous ? 'anonymous_submissions' : 'submissions'
    const iframePreviewVersion = SpeedgraderHelpers.iframePreviewVersion(this.currentStudent.submission)
    const hideStudentNames = utils.shouldHideStudentNames() ? "&hide_student_name=1" : ""
    const queryParams = `${iframePreviewVersion}${hideStudentNames}`
    const src =
      `/courses/${courseId}/assignments/${assignmentId}/${resourceSegment}/${anonymizableSubmissionId}?preview=true${queryParams}`
    const iframe = SpeedgraderHelpers.buildIframe(htmlEscape(src), {frameborder: 0, allowfullscreen: true}, domElement)
    $iframe_holder.html($.raw(iframe)).show();
  },

  renderLtiLaunch: function($div, urlBase, externalToolUrl) {
    this.emptyIframeHolder()
    var launchUrl = urlBase + '&url=' + encodeURIComponent(externalToolUrl);
    var iframe = SpeedgraderHelpers.buildIframe(htmlEscape(launchUrl), {
      className: 'tool_launch',
      allowfullscreen: true
    });
    $div.html(
      $.raw(iframe)
    ).show();
  },

  generateWarningTimings (numHours) {
    const sessionLimit = numHours * 60 * 60 * 1000;
    return [
      sessionLimit - (10 * 60 * 1000),
      sessionLimit - (5 * 60 * 1000),
      sessionLimit - (2 * 60 * 1000),
      sessionLimit - (1 * 60 * 1000)
    ];
  },

  displayExpirationWarnings (aggressiveWarnings, numHours, message) {
    const start = new Date();
    const sessionLimit = numHours * 60 * 60 * 1000;
    sessionTimer = window.setInterval(() => {
      const elapsed = new Date() - start;
      if (elapsed > sessionLimit) {
        SpeedgraderHelpers.reloadPage();
      } else if (elapsed > aggressiveWarnings[0]) {
        $.flashWarning(message);
        aggressiveWarnings.shift();
      }
    }, 1000);
  },

  renderAttachment: function(attachment) {
    // show the crocodoc doc if there is one
    // then show the google attachment if there is one
    // then show the first browser viewable attachment if there is one
    this.emptyIframeHolder()
    var previewOptions = {
      height: '100%',
      id: "speedgrader_iframe",
      mimeType: attachment.content_type,
      attachment_id: attachment.id,
      submission_id: this.currentStudent.submission.id,
      attachment_view_inline_ping_url: attachment.view_inline_ping_url,
      attachment_preview_processing: attachment.workflow_state == 'pending_upload' || attachment.workflow_state == 'processing'
    };

    if (!attachment.hijack_crocodoc_session && attachment.submitted_to_crocodoc && !attachment.crocodoc_url) {
      $("#crocodoc_pending").show();
    }
    const canvadocMessage = I18n.t('canvadoc_expiring',
                                   'Your Canvas DocViewer session is expiring soon.  Please ' +
                                   'reload the window to avoid losing any work.');

    if (attachment.crocodoc_url) {
      if (!attachment.hijack_crocodoc_session) {
        const crocodocMessage = I18n.t('crocodoc_expiring',
                                       'Your Crocodoc session is expiring soon.  Please reload ' +
                                       'the window to avoid losing any work.');
        const aggressiveWarnings = this.generateWarningTimings(1)
        this.displayExpirationWarnings(aggressiveWarnings, 1, crocodocMessage);
      } else {
        const aggressiveWarnings = this.generateWarningTimings(10)
        this.displayExpirationWarnings(aggressiveWarnings, 10, canvadocMessage);
      }

      $iframe_holder.show().loadDocPreview($.extend(previewOptions, {
        crocodoc_session_url: (attachment.provisional_crocodoc_url || attachment.crocodoc_url)
      }));
    } else if (attachment.canvadoc_url) {
      const aggressiveWarnings = this.generateWarningTimings(10)
      this.displayExpirationWarnings(aggressiveWarnings, 10, canvadocMessage);

      $iframe_holder.show().loadDocPreview($.extend(previewOptions, {
        canvadoc_session_url: (attachment.provisional_canvadoc_url || attachment.canvadoc_url),
        iframe_min_height: 0
      }));
    } else if ($.isPreviewable(attachment.content_type, 'google')) {
      if (!INST.disableCrocodocPreviews) $no_annotation_warning.show();

      const currentStudentIDAsOfAjaxCall = this.currentStudent[anonymizableId]
      previewOptions = $.extend(previewOptions, {
        ajax_valid: _.bind(function() {
          return currentStudentIDAsOfAjaxCall === this.currentStudent[anonymizableId];
        }, this)});
      $iframe_holder.show().loadDocPreview(previewOptions);
    } else if (browserableCssClasses.test(attachment.mime_class)) {
      // xsslint safeString.identifier iframeHolderContents
      const iframeHolderContents = this.attachmentIframeContents(attachment);
      $iframe_holder.html(iframeHolderContents).show();
    }
  },

  attachmentIframeContents (attachment, domElement = 'iframe') {
    let contents;
    const genericSrc = unescape($submission_file_hidden.find('.display_name').attr('href'));

    const anonymizableSubmissionIdToken = isAnonymous ? 'anonymousId' : 'submissionId';
    const src = genericSrc
      .replace(`{{${anonymizableSubmissionIdToken}}}`, this.currentStudent.submission[anonymizableUserId])
      .replace('{{attachmentId}}', attachment.id);

    if (attachment.mime_class === 'image') {
      contents = `<img src="${htmlEscape(src)}" style="max-width:100%;max-height:100%;">`;
    } else {
      contents = SpeedgraderHelpers.buildIframe(htmlEscape(src), { frameborder: 0, allowfullscreen: true }, domElement);
    }

    return $.raw(contents);
  },

  showRubric ({validateEnteredData = true} = {}) {
    const selectMenu = selectors.get('#rubric_assessments_select');
    //if this has some rubric_assessments
    if (jsonData.rubric_association) {
      ENV.RUBRIC_ASSESSMENT.assessment_user_id = this.currentStudent[anonymizableId];

      const isModerator = ENV.grading_role === 'moderator'
      const selectMenuOptions = []

      const assessmentsByMe = EG.currentStudent.rubric_assessments
        .filter(assessment => assessmentBelongsToCurrentUser(assessment))
      if (assessmentsByMe.length > 0) {
        assessmentsByMe.forEach(assessment => {
          const displayName = isModerator ? customProvisionalGraderLabel : assessment.assessor_name
          selectMenuOptions.push({ id: assessment.id, name: displayName })
        })
      } else if (isModerator) {
        // Moderators can create a custom assessment if they don't have one
        selectMenuOptions.push({ id: '', name: customProvisionalGraderLabel })
      }

      const assessmentsByOthers = EG.currentStudent.rubric_assessments
        .filter(assessment => !assessmentBelongsToCurrentUser(assessment))

      assessmentsByOthers.forEach(assessment => {
        // Display anonymous graders as "Grader 1 Rubric" (but don't use the
        // "Rubric" suffix for named graders)
        let displayName = assessment.assessor_name
        if (anonymousGraders) {
          displayName += ' Rubric'
        }

        selectMenuOptions.push({ id: assessment.id, name: displayName })
      });

      selectMenu.find("option").remove();
      selectMenuOptions.forEach(option => {
        selectMenu.append(`<option value="${htmlEscape(option.id)}">${htmlEscape(option.name)}</option>`)
      })

      let idToSelect = ''
      if (assessmentsByMe.length > 0) {
        idToSelect = assessmentsByMe[0].id
      } else {
        const gradingAssessment = EG.currentStudent.rubric_assessments
          .find(assessment => assessment.assessment_type === 'grading')

        if (gradingAssessment) {
          idToSelect = gradingAssessment.id
        }
      }

      selectMenu.val(idToSelect)
      $("#rubric_assessments_list").showIf(isModerator || selectMenu.find("option").length > 1);

      handleSelectedRubricAssessmentChanged({validateEnteredData});
    }
  },

  renderCommentAttachment: function (comment, attachmentData, incomingOpts) {
    var defaultOpts = {
      commentAttachmentBlank: $comment_attachment_blank
    };
    var opts = _.extend({}, defaultOpts, incomingOpts);
    var attachment = attachmentData.attachment ? attachmentData.attachment : attachmentData;
    var attachmentElement = opts.commentAttachmentBlank.clone(true);

    attachment.comment_id = comment.id;
    attachment.submitter_id = EG.currentStudent[anonymizableId];

    attachmentElement = attachmentElement.fillTemplateData({
      data: attachment,
      hrefValues: ['comment_id', 'id', 'submitter_id']
    });
    attachmentElement.find('a').addClass(attachment.mime_class);

    return attachmentElement;
  },

  addCommentDeletionHandler: function (commentElement, comment) {
    var that = this;

    // this is really poorly decoupled but over in
    // speed_grader.html.erb these rubricAssessment. variables are
    // set.  what this is saying is: if I am able to grade this
    // assignment (I am administrator in the course) or if I wrote
    // this comment... and if the student isn't concluded
    const isConcluded = EG.isStudentConcluded(EG.currentStudent[anonymizableId]);
    const commentIsDeleteableByMe = (
      ENV.RUBRIC_ASSESSMENT.assessment_type === 'grading' ||
      ENV.RUBRIC_ASSESSMENT.assessor_id === comment[anonymizableAuthorId]
    ) && !isConcluded;

    commentElement.find('.delete_comment_link').click(function (_event) {
      $(this).parents('.comment').confirmDelete({
        url: '/submission_comments/' + comment.id,
        message: I18n.t('Are you sure you want to delete this comment?'),
        success: function (_data) {
          var updatedComments = [];

          // Let's remove this comment from the client-side cache
          if (that.currentStudent.submission && that.currentStudent.submission.submission_comments) {
            updatedComments = _.reject(
              that.currentStudent.submission.submission_comments,
              function (item) {
                var submissionComment = item.submission_comment || item;
                return submissionComment.id === comment.id;
              }
            );

            that.currentStudent.submission.submission_comments = updatedComments;
          }

          // and also remove it from the DOM
          $(this).slideUp(function () {
            $(this).remove();
          });
        }
      });
    }).showIf(commentIsDeleteableByMe);
  },

  addCommentSubmissionHandler: function (commentElement, comment) {
    var that = this;

    const isConcluded = EG.isStudentConcluded(EG.currentStudent[anonymizableId]);
    commentElement.find('.submit_comment_button').click(function (_event) {
      var updateUrl = '';
      var updateData = {};
      var updateAjaxOptions = {};
      var commentUpdateSucceeded = function (data) {
        var updatedComments = [];
        var $replacementComment = that.renderComment(data.submission_comment);
        $replacementComment.show();
        commentElement.replaceWith($replacementComment);

        updatedComments = _.map(that.currentStudent.submission.submission_comments,
                                function (item) {
                                  var submissionComment = item.submission_comment || item;

                                  if (submissionComment.id === comment.id) {
                                    return data.submission_comment;
                                  }

                                  return submissionComment;
                                }
                               );

        that.currentStudent.submission.submission_comments = updatedComments;
      };
      var commentUpdateFailed = function (_jqXHR, _textStatus) {
        $.flashError(I18n.t('Failed to submit draft comment'));
      };
      var confirmed = confirm(I18n.t('Are you sure you want to submit this comment?'));

      if (confirmed) {
        updateUrl = '/submission_comments/' + comment.id;
        updateData = { submission_comment: { draft: 'false' } };
        updateAjaxOptions = { url: updateUrl, data: updateData, dataType: 'json', type: 'PATCH' };

        $.ajax(updateAjaxOptions).done(commentUpdateSucceeded).fail(commentUpdateFailed);
      }
    }).showIf(comment.publishable && !isConcluded);
  },

  renderComment: function (commentData, incomingOpts) {
    var self = this;
    var comment = commentData;
    var spokenComment = '';
    var submitCommentButtonText = '';
    var deleteCommentLinkText = '';
    var hideStudentName = false;
    var defaultOpts = {
      commentBlank: $comment_blank,
      commentAttachmentBlank: $comment_attachment_blank
    };
    var opts = _.extend({}, defaultOpts, incomingOpts);
    var commentElement = opts.commentBlank.clone(true);

    // Serialization seems to have changed... not sure if it's changed everywhere, though...
    if (comment.submission_comment) { comment = commentData.submission_comment; }

    // don't render private comments when viewing a group assignment
    if (!comment.group_comment_id && window.jsonData.GROUP_GRADING_MODE) return undefined;

    // For screenreaders
    spokenComment = comment.comment.replace(/\s+/, ' ');

    comment.posted_at = $.datetimeString(comment.created_at);

    hideStudentName = opts.hideStudentNames && window.jsonData.studentMap[comment[anonymizableAuthorId]];
    if (hideStudentName) {
      const { index } = window.jsonData.studentMap[comment[anonymizableAuthorId]];
      comment.author_name = I18n.t('Student %{position}', { position: index + 1 });
    }
    // anonymous commentors
    if (comment.author_name == null) {
      const {provisional_grade_id} = EG.currentStudent.submission.provisional_grades.find(pg =>
        pg.anonymous_grader_id === comment.anonymous_id
      )
      if (provisionalGraderDisplayNames == null || provisionalGraderDisplayNames[provisional_grade_id] == null) {
        this.setupProvisionalGraderDisplayNames()
      }
      comment.author_name = provisionalGraderDisplayNames[provisional_grade_id]
    }
    commentElement = commentElement.fillTemplateData({ data: comment });

    if (comment.draft) {
      commentElement.addClass('draft');
      submitCommentButtonText = I18n.t('Submit comment: %{commentText}', { commentText: spokenComment });
      commentElement.find('.submit_comment_button').attr('aria-label', submitCommentButtonText);
    } else {
      commentElement.find('.draft-marker').remove();
      commentElement.find('.submit_comment_button').remove();
    }

    commentElement.find('span.comment').html($.raw(htmlEscape(comment.comment).replace(/\n/g, '<br />')));

    deleteCommentLinkText = I18n.t('Delete comment: %{commentText}', { commentText: spokenComment });
    commentElement.find('.delete_comment_link .screenreader-only').text(deleteCommentLinkText);

    if (comment.avatar_path && !hideStudentName) {
      commentElement.find('.avatar').attr('src', comment.avatar_path).show();
    }

    if (comment.media_comment_type && comment.media_comment_id) {
      commentElement.find('.play_comment_link').data(comment).show();
    }

    // TODO: Move attachment handling into a separate function
    $.each((comment.cached_attachments || comment.attachments || []), function (_index, attachment) {
      var attachmentElement = self.renderCommentAttachment(comment, attachment, opts);

      commentElement.find('.comment_attachments').append($(attachmentElement).show());
    });

    /* Submit a comment and Delete a comment listeners */

    this.addCommentDeletionHandler(commentElement, comment);
    this.addCommentSubmissionHandler(commentElement, comment);

    return commentElement;
  },

  showDiscussion: function () {
    var that = this;
    var commentRenderingOptions = {
      hideStudentNames: utils.shouldHideStudentNames(),
      commentBlank: $comment_blank,
      commentAttachmentBlank: $comment_attachment_blank
    };

    $comments.html('');

    if (this.currentStudent.submission && this.currentStudent.submission.submission_comments) {
      $.each(this.currentStudent.submission.submission_comments, function (i, comment) {
        var commentElement = that.renderComment(comment, commentRenderingOptions);

        if (commentElement) {
          $comments.append($(commentElement).show());
          const $commentLink = $comments.find('.play_comment_link').last();
          $commentLink.data('author', comment.author_name);
          $commentLink.data('created_at', comment.posted_at);
          $commentLink.mediaCommentThumbnail('normal');
        }
      });
    }
    $comments.scrollTop(9999999);  // the scrollTop part forces it to scroll down to the bottom so it shows the most recent comment.
  },

  revertFromFormSubmit: ({draftComment = null, errorSubmitting = false} = {}) => {
    // This is to continue existing behavior of creating finalized comments by default
    if (draftComment === undefined) {
      draftComment = false;
    }

    EG.showDiscussion();
    renderCommentTextArea();
    $add_a_comment.find(":input").prop("disabled", false);

    if (draftComment) {
      // Show a different message when auto-saving a draft comment
      $comment_saved.show();
      $comment_saved_message.attr("tabindex",-1).focus();
    } else if (!errorSubmitting) {
      $comment_submitted.show();
      $comment_submitted_message.attr("tabindex",-1).focus();
    }
    $add_a_comment_submit_button.text(I18n.t('submit', "Submit"));
  },

  addSubmissionComment: function(draftComment){
    // This is to continue existing behavior of creating finalized comments by default
    if (draftComment === undefined) {
      draftComment = false;
    }

    $comment_submitted.hide();
    $comment_saved.hide();
    if (
      !$.trim($add_a_comment_textarea.val()).length &&
        !$("#media_media_recording").data('comment_id') &&
        !$add_a_comment.find("input[type='file']:visible").length
    ) {
      // that means that they did not type a comment, attach a file or record any media. so dont do anything.
      return false;
    }
    const url = `${assignmentUrl}/${isAnonymous ? 'anonymous_' : ''}submissions/${EG.currentStudent[anonymizableId]}`
    var method = "PUT";
    var formData = {
      'submission[assignment_id]': jsonData.id,
      'submission[group_comment]': ($("#submission_group_comment").attr('checked') ? "1" : "0"),
      'submission[comment]': $add_a_comment_textarea.val(),
      'submission[draft_comment]': draftComment,
      [`submission[${anonymizableId}]`]: EG.currentStudent[anonymizableId]
    };
    if ($("#media_media_recording").data('comment_id')) {
      $.extend(formData, {
        'submission[media_comment_type]': $("#media_media_recording").data('comment_type'),
        'submission[media_comment_id]': $("#media_media_recording").data('comment_id')
      });
    }
    if (ENV.grading_role == 'moderator' || ENV.grading_role == 'provisional_grader') {
      formData['submission[provisional]'] = true;
      if (ENV.grading_role == 'moderator' && EG.current_prov_grade_index == 'final') { // final mark
        formData['submission[final]'] = true;
      }
    }

    function formSuccess(submissions) {
      $.each(submissions, function(){
        EG.setOrUpdateSubmission(this.submission);
      });
      EG.revertFromFormSubmit({draftComment});
      window.setTimeout(function() {
        $rightside_inner.scrollTo($rightside_inner[0].scrollHeight, 500);
      });
    }

    const formError = (data, _xhr, _textStatus, _errorThrown) => {
      EG.handleGradingError(data);
      EG.revertFromFormSubmit({errorSubmitting: true});
    }

    if($add_a_comment.find("input[type='file']:visible").length) {
      $.ajaxJSONFiles(url + ".text", method, formData, $add_a_comment.find("input[type='file']:visible"), formSuccess, formError);
    } else {
      $.ajaxJSON(url, method, formData, formSuccess, formError);
    }

    $("#comment_attachments").empty();
    $add_a_comment.find(":input").prop("disabled", true);
    $add_a_comment_submit_button.text(I18n.t('buttons.submitting', "Submitting..."));
    hideMediaRecorderContainer();
  },

  setOrUpdateSubmission: function(submission){
    // find the student this submission belongs to and update their
    // submission with this new one, if they dont have a submission,
    // set this as their submission.
    const student = jsonData.studentMap[submission[anonymizableUserId]];
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

    student.submission_state = SpeedgraderHelpers.submissionState(student, ENV.grading_role);
    if (ENV.grading_role == "moderator") {
      // sync with current provisional grade
      var prov_grade;
      if (this.current_prov_grade_index == 'final') {
        prov_grade = student.submission.final_provisional_grade;
      } else {
        prov_grade = student.submission.provisional_grades && student.submission.provisional_grades[this.current_prov_grade_index];
      }
      if (prov_grade) {
        if (!prov_grade.provisional_grade_id) {
          prov_grade.provisional_grade_id = submission.provisional_grade_id; // populate a new prov_grade's id
          this.updateModerationTabs();
          if (this.current_prov_grade_index == 1) {
            $new_mark_copy_link2_menu_item.show(); // show the copy link now
          }
        }
        prov_grade.score = submission.score;
        prov_grade.grade = submission.grade;
        prov_grade.rubric_assessments = student.rubric_assessments;
        prov_grade.submission_comments = submission.submission_comments;
      }
    }

    return student;
  },

  // If the second argument is passed as true, the grade used will
  // be the existing score from the previous submission.  This
  // should only be called from the anonymous function attached so
  // #submit_same_score.
  handleGradeSubmit: function(e, use_existing_score){
    if (EG.isStudentConcluded(EG.currentStudent[anonymizableId])) {
      EG.showGrade();
      return;
    }

    const url = $(".update_submission_grade_url").attr('href')
    const method = $(".update_submission_grade_url").attr('title')
    const formData = {
      'submission[assignment_id]': jsonData.id,
      [`submission[${anonymizableUserId}]`]: EG.currentStudent[anonymizableId],
      'submission[graded_anonymously]': isAnonymous ? true : utils.shouldHideStudentNames()
    };

    var grade = SpeedgraderHelpers.determineGradeToSubmit(
      use_existing_score,
      EG.currentStudent,
      $grade
    );

    if (grade.toUpperCase() === "EX") {
      formData["submission[excuse]"] = true;
    } else if (unexcuseSubmission(grade, EG.currentStudent.submission, jsonData)) {
      formData["submission[excuse]"] = false;
    } else if (use_existing_score) {
      // If we're resubmitting a score, pass it as a raw score not grade.
      // This allows percentage grading types to be handled correctly.
      formData['submission[score]'] = grade;
    } else {
      // Any manually entered grade is a grade.
      formData['submission[grade]'] = EG.formatGradeForSubmission(grade);
    }
    if (ENV.grading_role == 'moderator' || ENV.grading_role == 'provisional_grader') {
      formData['submission[provisional]'] = true;
      if (ENV.grading_role == 'moderator' && EG.current_prov_grade_index == 'final') {
        formData['submission[final]'] = true;
      }
    }

    const submissionSuccess = submissions => {
      var pointsPossible = jsonData.points_possible;
      var score = submissions[0].submission.score;

      if (!submissions[0].submission.excused) {
        var outlierScoreHelper = new OutlierScoreHelper(score, pointsPossible);
        if(outlierScoreHelper.hasWarning()) {
          $.flashWarning(outlierScoreHelper.warningMessage());
        }
      }

      $.each(submissions, function(){
        // setOrUpdateSubmission returns the student it just updated.
        // This is only operating on a subset of people, so it should
        // be fairly fast to call updateSelectMenuStatus for each one.
        const student = EG.setOrUpdateSubmission(this.submission);
        EG.updateSelectMenuStatus(student);
      });
      EG.refreshSubmissionsToView();
      $multiple_submissions.change();
      EG.showGrade();

      if (ENV.grading_role === 'moderator' && currentStudentProvisionalGrades().length > 0) {
        // This is the ID of the possibly-new grade that the server returned
        const newProvisionalGradeId = submissions[0].submission.provisional_grade_id;
        const existingGrade = currentStudentProvisionalGrades().find(
          provisionalGrade => provisionalGrade.provisional_grade_id === newProvisionalGradeId
        );

        // If it's not a new grade but an existing one, update the grade to match
        if (existingGrade) {
          existingGrade.grade = grade;
          existingGrade.score = score;
        }

        EG.submitSelectedProvisionalGrade(newProvisionalGradeId, !existingGrade);
        EG.setActiveProvisionalGradeFields({grade: existingGrade, label: customProvisionalGraderLabel});
      }
    };

    const submissionError = (data, _xhr, _textStatus, _errorThrown) => {
      EG.handleGradingError(data)

      let selectedGrade
      if (ENV.grading_role === 'moderator') {
        selectedGrade = currentStudentProvisionalGrades().find(provisionalGrade => provisionalGrade.selected)
      }

      // Revert to the previously selected provisional grade (if we're moderating) or
      // the last valid value (if not moderating or no provisional grade was chosen)
      if (selectedGrade) {
        EG.setActiveProvisionalGradeFields({
          grade: selectedGrade,
          label: provisionalGraderDisplayNames[selectedGrade.provisional_grade_id]
        })
      } else {
        EG.showGrade()
      }
    };

    $.ajaxJSON(url, method, formData, submissionSuccess, submissionError);
  },

  showGrade: function() {
    const submission = EG.currentStudent.submission || {};
    let grade

    if (submission.grading_type === 'pass_fail' || ['complete', 'incomplete', 'pass', 'fail'].indexOf(submission.grade) > -1) {
      $grade.val(submission.grade);
    } else {
      grade = EG.getGradeToShow(submission, ENV.grading_role);
      $grade.val(grade.entered);
    }

    if (submission.points_deducted) {
      $deduction_box.removeClass('hidden');
      $points_deducted.text(grade.pointsDeducted);
      $final_grade.text(grade.adjusted);
    } else {
      $deduction_box.addClass('hidden');
    }

    $('#submit_same_score').hide();
    if (typeof submission !== 'undefined' && submission.entered_score !== null) {
      $score.text(I18n.n(round(submission.entered_score, round.DEFAULT)));
      if (!submission.grade_matches_current_submission) {
        $('#submit_same_score').show();
      }
    } else {
      $score.text("");
    }

    if (ENV.grading_role == 'moderator') {
      EG.updateModerationTabs();
    }

    EG.updateStatsInHeader();
  },

  updateSelectMenuStatus: function(student) {
    if (!student) return;
    const isCurrentStudent = student === EG.currentStudent;
    const newStudentInfo = EG.getStudentNameAndGrade(student)
    $selectmenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId});
  },

  isGradingTypePercent: function () {
    return ENV.grading_type === 'percent';
  },

  shouldParseGrade: function () {
    return EG.isGradingTypePercent() || ENV.grading_type === 'points';
  },

  formatGradeForSubmission: function (grade) {
    if (grade === '') {
      return grade;
    }

    var formattedGrade = grade;

    if (EG.shouldParseGrade()) {
      // Percent sign could be located on left or right, with or without space
      // https://en.wikipedia.org/wiki/Percent_sign
      formattedGrade = grade.replace(/%/g, '');
      formattedGrade = numberHelper.parse(formattedGrade);
      formattedGrade = round(formattedGrade, 2).toString();

      if (EG.isGradingTypePercent()) {
        formattedGrade += '%';
      }
    }

    return formattedGrade;
  },

  getGradeToShow: function(submission, grading_role) {
    const grade = { entered: '' };

    if (submission) {
      if (submission.excused) {
        grade.entered = 'EX';
      } else {
        if (submission.points_deducted !== '' && !isNaN(submission.points_deducted)) {
          grade.pointsDeducted = I18n.n(-submission.points_deducted);
        }

        let enteredScore = submission.entered_score;
        let enteredGrade = submission.entered_grade;

        if (submission.provisional_grade_id) {
          enteredScore = submission.score;
          enteredGrade = submission.grade;
        }

        if (enteredScore != null && (['moderator', 'provisional_grader'].includes(grading_role))) {
          grade.entered = GradeFormatHelper.formatGrade(round(enteredScore, 2));
          grade.adjusted = GradeFormatHelper.formatGrade(round(submission.score, 2));
        } else if (submission.entered_grade != null) {
          if (enteredGrade !== '' && !isNaN(enteredGrade)) {
            grade.entered = GradeFormatHelper.formatGrade(round(enteredGrade, 2));
            grade.adjusted = GradeFormatHelper.formatGrade(round(submission.grade, 2));
          } else {
            grade.entered = GradeFormatHelper.formatGrade(enteredGrade);
            grade.adjusted = GradeFormatHelper.formatGrade(submission.grade);
          }
        }
      }
    }

    return grade;
  },

  initComments: function(){
    $add_a_comment_submit_button.click(function(event) {
      event.preventDefault();
      if ($add_a_comment_submit_button.hasClass('ui-state-disabled')) {
        return;
      }
      EG.addSubmissionComment();
    });
    $add_attachment.click(function(event) {
      event.preventDefault();
      if (($add_attachment).hasClass('ui-state-disabled')) {
        return;
      }
      var $attachment = $comment_attachment_input_blank.clone(true);
      $attachment.find("input").attr('name', 'attachments[' + fileIndex + '][uploaded_data]');
      fileIndex++;
      $("#comment_attachments").append($attachment.show());
    });
    $comment_attachment_input_blank.find("a").click(function(event) {
      event.preventDefault();
      $(this).parents(".comment_attachment_input").remove();
    });
    $right_side.delegate(".play_comment_link", 'click', function() {
      if($(this).data('media_comment_id')) {
        $(this).parents(".comment").find(".media_comment_content")
          .show()
          .mediaComment('show', $(this).data('media_comment_id'), $(this).data('media_comment_type'), this)
      }
      return false; // so that it doesn't hit the $("a.instructure_inline_media_comment").live('click' event handler
    });
  },

  // Note: do not use compareStudentsBy if your dataset includes 0.
  compareStudentsBy: function (f) {
    const secondaryAttr = isAnonymous ? 'anonymous_id' : 'sortable_name'

    return function (studentA, studentB) {
      var a = f(studentA);
      var b = f(studentB);

      if ((!a && !b) || a === b) {
        // sort isn't guaranteed to be stable, so we need to sort by name in case of tie
        return natcompare.strings(studentA[secondaryAttr], studentB[secondaryAttr]);
      } else if (!a || a > b) {
        return 1;
      }

      return -1;
    };
  },

  beforeLeavingSpeedgrader (e) {
    // Submit any draft comments that need submitting
    EG.addSubmissionComment(true)

    if (window.opener && window.opener.updateGrades && $.isFunction(window.opener.updateGrades)) {
      window.opener.updateGrades()
    }

    function userNamesWithPendingQuizSubmission () {
      return $.map(snapshotCache, snapshot =>
        snapshot && $.map(jsonData.context.students, student =>
          (snapshot === student) && student.name
        )[0]
      )
    }

    function hasPendingQuizSubmissions () {
      let ret = false
      const submissions = userNamesWithPendingQuizSubmission()
      if (submissions.length) {
        for (let i = 0, max = submissions.length; i < max; i++){
          if (submissions[i] !== false) { ret = true }
        }
      }
      return ret
    }

    function hasUnsubmittedComments () {
      return $.trim($add_a_comment_textarea.val()) !== ""
    }

    if (hasPendingQuizSubmissions()) {
      e.returnValue = I18n.t(
        "The following students have unsaved changes to their quiz submissions:\n\n" +
        "%{users}\nContinue anyway?", {users: userNamesWithPendingQuizSubmission().join('\n ')}
      )
      return e.returnValue;
    } else if (hasUnsubmittedComments()) {
      e.returnValue = I18n.t(
        "If you would like to keep your unsubmitted comments, please save them before navigating away from this page."
      )
      return e.returnValue;
    }
    teardownHandleFragmentChanged()
    teardownBeforeLeavingSpeedgrader()
    return undefined
  },

  handleGradingError (data={}) {
    const errorCode = data.errors && data.errors.error_code

    // If the grader entered an invalid provisional grade, revert it without
    // showing an explicit error
    if (errorCode === 'PROVISIONAL_GRADE_INVALID_SCORE') {
      return;
    }

    let errorMessage
    if (errorCode === 'MAX_GRADERS_REACHED') {
      errorMessage = I18n.t('The maximum number of graders has been reached for this assignment.');
    } else if (errorCode === 'PROVISIONAL_GRADE_MODIFY_SELECTED') {
      errorMessage = I18n.t('The grade you entered has been selected and can no longer be changed.');
    } else {
      errorMessage = I18n.t('An error occurred updating this assignment.');
    }

    $.flashError(errorMessage);
  },

  // (This *should* properly be called selectProvisionalGrade, but it has a
  // different name to avoid confusion with the method on the EG object with
  // that name. This one is only called when Anonymous Moderated Marking is
  // on, meaning we don't need to update the moderation tab.)
  submitSelectedProvisionalGrade (provisionalGradeId, refetchOnSuccess=false) {
    const selectGradeUrl = $.replaceTags(
      ENV.provisional_select_url,
      { provisional_grade_id: provisionalGradeId }
    );

    const submitSucceeded = (data) => {
      const selectedProvisionalGradeId = data.selected_provisional_grade_id;
      // Update the "selected" field on our grades manually. No need to bother
      // the server solely to verify the new selections.
      currentStudentProvisionalGrades().forEach(grade => {
        grade.selected = grade.provisional_grade_id === selectedProvisionalGradeId;
      })

      if (refetchOnSuccess) {
        // If this involved submitting a new provisional grade, re-fetch the
        // list of grades so we have a real data structure for the new one
        this.fetchProvisionalGrades();
      } else {
        // Otherwise we just selected an existing grade and didn't change
        // anything, so go ahead and re-render
        this.renderProvisionalGradeSelector();
      }
    }

    $.ajaxJSON(selectGradeUrl, 'PUT', {}, submitSucceeded);
  },

  setupProvisionalGraderDisplayNames() {
    provisionalGraderDisplayNames = {};
    let provisionalGrades = currentStudentProvisionalGrades();

    provisionalGrades.forEach((grade) => {
      if (grade.readonly) {
        const displayName = grade.anonymous_grader_id
          ? ENV.anonymous_identities[grade.anonymous_grader_id].name
          : grade.scorer_name;
        provisionalGraderDisplayNames[grade.provisional_grade_id] = displayName;
      } else {
        provisionalGraderDisplayNames[grade.provisional_grade_id] = customProvisionalGraderLabel;
      }
    });
  },

  fetchProvisionalGrades() {
    const {course_id: courseId, assignment_id: assignmentId} = ENV;
    const resourceSegment = isAnonymous ? 'anonymous_provisional_grades' : 'provisional_grades';
    const resourceUrl = `/api/v1/courses/${courseId}/assignments/${assignmentId}/${resourceSegment}/status`;

    let status_url = `${resourceUrl}?${anonymizableStudentId}=${EG.currentStudent[anonymizableId]}`
    if (ENV.grading_role === 'moderator') {
      status_url += "&last_updated_at="
      if (EG.currentStudent.submission) {
        status_url += EG.currentStudent.submission.updated_at;
      }
    }

    // Check with the API ("hit the API" sounds so brutish) to get the updated
    // list of provisional grades. We return this so that disableWhileLoading
    // has access to the Deferred object.
    return $.getJSON(status_url, {}, EG.onProvisionalGradesFetched)
  },

  onProvisionalGradesFetched (data) {
    EG.currentStudent.needs_provisional_grade = data.needs_provisional_grade;

    if (ENV.grading_role === 'moderator' && data.provisional_grades) {
      if (!EG.currentStudent.submission) EG.currentStudent.submission = {}
      EG.currentStudent.submission.provisional_grades = data.provisional_grades;
      EG.currentStudent.submission.updated_at = data.updated_at;
      EG.currentStudent.submission.final_provisional_grade = data.final_provisional_grade;
    }

    EG.currentStudent.submission_state = SpeedgraderHelpers.submissionState(EG.currentStudent, ENV.grading_role);
    EG.showStudent();
  },

  setActiveProvisionalGradeFields({label='', grade=null} = {}) {
    $grading_box_selected_grader.text(label);

    const submission = EG.currentStudent.submission || {};
    if (grade !== null) {
      // If the moderator has selected their own custom grade
      // (i.e., the selected grade isn't read-only) and has
      // excused this submission, show that instead of the
      // provisional grade's score
      if (!grade.readonly && submission.excused) {
        $grade.val('EX')
        $score.text('')
      } else {
        $grade.val(grade.grade);
        $score.text(grade.score);
      }
    }
  },

  handleProvisionalGradeSelected ({selectedGrade, isNewGrade=false} = {}) {
    if (selectedGrade) {
      const selectedGradeId = selectedGrade.provisional_grade_id;

      this.submitSelectedProvisionalGrade(selectedGradeId);
      this.setActiveProvisionalGradeFields({
        grade: selectedGrade,
        label: provisionalGraderDisplayNames[selectedGradeId]
      });
    } else if (isNewGrade) {
      // If this is a "new" grade with no value, don't submit anything to the
      // server. This will only happen when the moderator selects a custom
      // grade for a given student for the first time (since no provisional grade
      // object exists yet). If/when the grade text field gets updated,
      // handleGradeSubmit will fire, create the new object, and re-fetch the
      // provisional grades from the server.
      this.setActiveProvisionalGradeFields({label: customProvisionalGraderLabel});

      // For now, set the grader fields appropriately and mark the grades we have
      // as not-selected until we get the new one.
      currentStudentProvisionalGrades().forEach(grade => {
        grade.selected = false;
      });
      this.renderProvisionalGradeSelector();
    }
  },

  renderProvisionalGradeSelector ({showingNewStudent=false} = {}) {
    const mountPoint = document.getElementById('grading_details_mount_point');
    const provisionalGrades = currentStudentProvisionalGrades();

    // Only show the selector if the current student has at least one grade from
    // a provisional grader (i.e., not the moderator).
    if (!provisionalGrades.some(grade => grade.readonly)) {
      ReactDOM.unmountComponentAtNode(mountPoint);
      return;
    }

    if (showingNewStudent) {
      this.setupProvisionalGraderDisplayNames();
    }

    const props = {
      gradingType: ENV.grading_type,
      onGradeSelected: params => {
        this.handleProvisionalGradeSelected(params)
      },
      pointsPossible: jsonData.points_possible,
      provisionalGraderDisplayNames,
      provisionalGrades
    }

    const gradeSelector = <SpeedGraderProvisionalGradeSelector {...props} />
    ReactDOM.render(gradeSelector, mountPoint)
  },

  changeToSection (sectionId) {
    // Update the selected section in old gradebook
    if (sectionId === 'all') {
      // We're removing all filters and resetting to default
      userSettings.contextRemove('grading_show_only_section');
    } else {
      userSettings.contextSet('grading_show_only_section', sectionId);
    }

    // ...and in new gradebook
    if (ENV.settings_url) {
      $.post(ENV.settings_url, { selected_section_id: sectionId }, () => { SpeedgraderHelpers.reloadPage() })
    } else {
      SpeedgraderHelpers.reloadPage();
    }
  }
}

function getGradingPeriods() {
  var dfd = $.Deferred();
  // treating failure as a success here since grading periods 404 when not
  // enabled
  $.ajaxJSON("/api/v1/courses/" + ENV.course_id + "/grading_periods",
             "GET", {},
             function(response) { dfd.resolve(response.grading_periods); },
             function() { dfd.resolve([]); },
             {skipDefaultError: true}
            );

  return dfd;
}

function setupSpeedGrader(gradingPeriods, speedGraderJsonResponse) {
  var speedGraderJSON = speedGraderJsonResponse[0];
  speedGraderJSON.gradingPeriods = _.indexBy(gradingPeriods, 'id')
  window.jsonData = speedGraderJSON;
  EG.jsonReady();
}

function speedGraderJSONErrorFn (data, _xhr, _textStatus, _errorThrown) {
  if (data.status === 504) {
    const alertProps = {
      variant: 'error',
      dismissible: false
    };
    const alertMessage = I18n.t(
      'Something went wrong. Please try refreshing the page. If the problem persists, there may be too many records on "%{assignmentTitle}" to load SpeedGrader.',
      { assignmentTitle: ENV.assignment_title }
    );
    ReactDOM.render(
      <Alert {...alertProps}>
        {alertMessage}
      </Alert>,
      document.getElementById('speed_grader_timeout_alert')
    );
  }
}

function setupSelectors() {
  // PRIVATE VARIABLES AND FUNCTIONS
  // all of the $ variables here are to speed up access to dom nodes,
  // so that the jquery selector does not have to be run every time.
  $add_a_comment = $('#add_a_comment')
  $add_a_comment_submit_button = $add_a_comment.find('button:submit')
  $add_a_comment_textarea = $(`#${SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT}`)
  $add_attachment = $('#add_attachment')
  $assignment_submission_originality_report_url = $('#assignment_submission_originality_report_url')
  $assignment_submission_resubmit_to_vericite_url = $('#assignment_submission_resubmit_to_vericite_url')
  $assignment_submission_turnitin_report_url = $('#assignment_submission_turnitin_report_url')
  $assignment_submission_vericite_report_url = $('#assignment_submission_vericite_report_url')
  $avatar_image = $('#avatar_image')
  $average_score = $('#average_score')
  $average_score_wrapper = $('#average-score-wrapper')
  $comment_attachment_blank = $('#comment_attachment_blank').removeAttr('id').detach()
  $comment_attachment_input_blank = $('#comment_attachment_input_blank').detach()
  $comment_blank = $('#comment_blank').removeAttr('id').detach()
  $comment_saved = $('#comment_saved')
  $comment_saved_message = $('#comment_saved_message')
  $comment_submitted = $('#comment_submitted')
  $comment_submitted_message = $('#comment_submitted_message')
  $comments = $('#comments')
  $deduction_box = $('#deduction-box')
  $enrollment_concluded_notice = $('#enrollment_concluded_notice')
  $enrollment_inactive_notice = $('#enrollment_inactive_notice')
  $final_grade = $('#final-grade')
  $full_width_container = $('#full_width_container')
  $grade_container = $('#grade_container')
  $grade = $grade_container.find('input, select')
  $gradebook_header = $('#gradebook_header')
  $grading_box_selected_grader = $('#grading-box-selected-grader')
  $grded_so_far = $('#x_of_x_graded')
  $iframe_holder = $('#iframe_holder')
  $left_side = $('#left_side')
  $moderation_bar = $('#moderation_bar')
  $moderation_tabs = $('#moderation_tabs > ul > li')
  $moderation_tab_2nd = $moderation_tabs.eq(1)
  $moderation_tab_final = $moderation_tabs.eq(2)
  $moderation_tabs_div = $('#moderation_tabs')
  $multiple_submissions = $('#multiple_submissions')
  $new_mark_container = $('#new_mark_container')
  $new_mark_copy_link1 = $('#new_mark_copy_link1')
  $new_mark_copy_link2 = $('#new_mark_copy_link2')
  $new_mark_copy_link2_menu_item = $new_mark_copy_link2.parent()
  $new_mark_final_link = $('#new_mark_final_link')
  $new_mark_final_link_menu_item = $new_mark_final_link.parent()
  $new_mark_link = $('#new_mark_link')
  $new_mark_link_menu_item = $new_mark_link.parent()
  $no_annotation_warning = $('#no_annotation_warning')
  $not_gradeable_message = $('#not_gradeable_message')
  $points_deducted = $('#points-deducted')
  $resize_overlay = $('#resize_overlay')
  $right_side = $('#right_side')
  $rightside_inner = $('#rightside_inner')
  $rubric_full_resizer_handle = $('#rubric_full_resizer_handle')
  $rubric_holder = $('#rubric_holder')
  $score = $grade_container.find('.score')
  $selectmenu = null
  $submission_attachment_viewed_at = $('#submission_attachment_viewed_at_container')
  $submission_details = $('#submission_details')
  $submission_file_hidden = $('#submission_file_hidden').removeAttr('id').detach()
  $submission_files_container = $('#submission_files_container')
  $submission_files_list = $('#submission_files_list')
  $submission_late_notice = $('#submission_late_notice')
  $submission_not_newest_notice = $('#submission_not_newest_notice')
  $submissions_container = $('#submissions_container')
  $this_student_does_not_have_a_submission = $('#this_student_does_not_have_a_submission').hide()
  $this_student_has_a_submission = $('#this_student_has_a_submission').hide()
  $width_resizer = $('#width_resizer')
  $window = $(window)
  $x_of_x_students = $('#x_of_x_students_frd')
  assignmentUrl = $('#assignment_url').attr('href')
  browserableCssClasses = /^(image|html|code)$/
  fileIndex = 1
  gradeeLabel = studentLabel
  groupLabel = I18n.t('group', 'Group')
  isAdmin = _.include(ENV.current_user_roles, 'admin');
  snapshotCache = {}
  studentLabel = I18n.t('student', 'Student')
  header = setupHeader()
}

function renderSettingsMenu () {
  function showKeyboardShortcutsModal () {
    // need to place at end of execution queue to make focus work properly
    setTimeout(header.keyboardShortcutInfoModal.bind(header), 0)
  }

  function showOptionsModal () {
    // need to place at end of execution queue to make focus work properly
    setTimeout(header.showSettingsModal.bind(header), 0)
  }

  const props =  {
    assignmentID: ENV.assignment_id,
    courseID: ENV.course_id,
    helpURL: ENV.help_url,
    openOptionsModal: showOptionsModal,
    openKeyboardShortcutsModal: showKeyboardShortcutsModal,
    showModerationMenuItem: ENV.grading_role === 'moderator',
    showHelpMenuItem: ENV.show_help_menu_item
  }

  const settingsMenu = <SpeedGraderSettingsMenu {...props} />
  ReactDOM.render(settingsMenu, document.getElementById(SPEED_GRADER_SETTINGS_MOUNT_POINT))
}

// Helper function that guard against provisional_grades being null, allowing
// Anonymous Moderated Marking-related moderation code to forgo that check
// when considering provisional grades.
function currentStudentProvisionalGrades () {
  return EG.currentStudent.submission.provisional_grades || [];
}

export default {
  setup () {
    setupSelectors()
    renderSettingsMenu()

    if (ENV.can_view_audit_trail) {
      EG.setUpAssessmentAuditTray()
    }

    function registerQuizzesNext (overriddenShowSubmission) {
      showSubmissionOverride = overriddenShowSubmission;
    }
    quizzesNextSpeedGrading(EG, $iframe_holder, registerQuizzesNext, refreshGrades, window);

    // fire off the request to get the jsonData
    window.jsonData = {};
    const speedGraderJSONUrl = `${window.location.pathname}.json${window.location.search}`;
    const speedGraderJsonDfd = $.ajaxJSON(speedGraderJSONUrl, 'GET', null, null, speedGraderJSONErrorFn);

    $.when(getGradingPeriods(), speedGraderJsonDfd).then(setupSpeedGrader);

    //run the stuff that just attaches event handlers and dom stuff, but does not need the jsonData
    $(document).ready(function() {
      EG.domReady();
    });
  },

  teardown() {
    if (ENV.can_view_audit_trail) {
      EG.tearDownAssessmentAuditTray()
    }

    teardownHandleFragmentChanged()
    teardownBeforeLeavingSpeedgrader()
  },

  EG
};
