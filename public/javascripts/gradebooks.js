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
  'INST' /* INST */,
  'i18n!gradebook',
  'jquery' /* $ */,
  'underscore',
  'timezone',
  'compiled/userSettings',
  'datagrid',
  'compiled/grade_calculator',
  'str/htmlEscape',
  'compiled/gradebook2/Turnitin',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.dropdownList' /* dropdownList */,
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jquery.instructure_forms' /* ajaxJSONFiles, formSubmit, getFormData, formErrors, errorBox */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'jquery.instructure_misc_helpers' /* replaceTags, /\$\.size/ */,
  'jquery.instructure_misc_plugins' /* fragmentChange, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImg, loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'message_students' /* messageStudents */,
  'vendor/date' /* Date.parse */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/position' /* /\.position\(/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */
], function(round, INST, I18n, $, _, tz, userSettings, datagrid, GradeCalculator, htmlEscape, Turnitin) {

  var grading_scheme = ENV.grading_scheme;
  var readOnlyGradebook = window.readOnlyGradebook;
  var gradebook = window.gradebook;
  var speedGraderEnabled = ENV.speed_grader_enabled;
  var object_data = null;

  var $loading_gradebook_progressbar = $("#loading_gradebook_progressbar"),
      $default_grade_form = $("#default_grade_form"),
      $assignment_details_dialog = $("#assignment_details_dialog"),
      $submission_information = $("#submission_information"),
      $update_submission_form = $("#update_submission_form"),
      $publish_to_sis_form = $("#publish_to_sis_form"),
      $curve_grade_dialog = $("#curve_grade_dialog"),
      $message_students_dialog = $("#message_students_dialog"),
      $information_link = $("#information_link"),
      $total_tooltip = $("#total_tooltip").appendTo('body'),
      content_offset = $("#content").offset(),
      context_code = $("#gradebook_full_content").data('context_code'),
      ignoreUngradedSubmissions = true;
      
      
  // ==================================================
  // = begin stuff to handle showing only one section =
  // ==================================================
  var possibleSections = {},
      $courseSections  = $(".outer_student_name .course_section"),
      contextId = $("#current_context_code").text().split("_")[1],
      sectionToShow = userSettings.contextGet('grading_show_only_section');
  sectionToShow = sectionToShow && String(sectionToShow);

  $courseSections.each(function(){
    possibleSections[$(this).data('course_section_id')] = $(this).attr('title'); 
  }); 
  
  if (sectionToShow) {
    var atLeastOnePersonExistsInThisSection = false,
        keptPersonCount = 0;
    // have to clear out all of the row_xxx entries in the id_maps object,
    // because we are going to get rid of a bunch of the students
    // we will re-add them for the students we keep
    $.each(id_maps, function(k, v) {
      if (k.match('row_')) {
        delete id_maps[k];
      }
    });
    
    $('.outer_student_name .course_sections, .gradebook_table .course_sections').each(function() {
      var section_ids = $(this).data('course_section_ids').toString().split(",");
      if (section_ids.indexOf(sectionToShow) == -1) {
        $(this).closest('tr').remove();
      } else {
        var studentId = $(this).closest('.student_header').attr('id');
        if (studentId) {
          ++keptPersonCount;
          id_maps['row_' + keptPersonCount] = Number(studentId.replace('student_', ''));
        }
        atLeastOnePersonExistsInThisSection = true;
      }
    });
    if (!atLeastOnePersonExistsInThisSection) {
      alert(I18n.t('alerts.no_students_in_section', "Could not find any students in that section, falling back to showing all sections."));
      userSettings.contextRemove('grading_show_only_section');
      window.location.reload();
    }
  }
  // =============================================
  // = end stuff to handle more than one section =
  // =============================================
  
  
  gradebook = {
    hoverCount: -1,
    fileIndex: 1,
    assignmentIndexes: {},
    studentIndexes: {},
    showInfoLink: function($cell) {
      var $link = $information_link;
      if(datagrid.currentFocus) { return; }
      var $obj = $cell.find(".table_entry");
      
      if($cell.hasClass('group_total') || $cell.hasClass('final_grade')) {
        $link.hide();
        if($obj.attr('data-tip')) {
          var position = $cell.offset();
          $total_tooltip.show().find(".text").text($obj.attr('data-tip'));
          var height = $total_tooltip.outerHeight();
          $total_tooltip.css({
            left: position.left - 2,
            top: position.top - height - 3
          });
        } else {
          $total_tooltip.hide();
        }
        return;
      } else if ( !$obj.length ||
           $obj.find(".new_message,.pending_review,.turnitin").filter(":visible").length || 
           $cell.hasClass('group_total') || 
           $cell.hasClass('final_grade') 
         ) {
        $link.hide();
        $total_tooltip.hide();
        return;
      }
      $total_tooltip.hide();
      $link.appendTo($obj).show();
    },
    hideInfoLink: function() {
      $total_tooltip.hide();
      $information_link.hide();
      gradebook.hoverCount = -1;
    },
    populate: function() {
      if(gradebook.updateAllStudentGrades) {
        gradebook.updateAllStudentGrades();
      }
    },
    makeAccessible: function(){
      var $grid = $("#datagrid_data .content");
      var $studentNames = $("#datagrid_left .display_name");
      $grid
        .attr('role', 'grid')
        .prepend(function(){
          var topRowHtml = $("#datagrid_top .assignment_title").map(function(){
            return "<div role='columnheader' id='th_" + $(this).parents('.assignment_header').attr('id') + "' tabindex='-1'>" + $(this).html() + "</div>";
          }).get().join("");
          return "<div class='hidden-readable' role='row'><div role='columnheader' tabindex='-1'>" + I18n.t('student_name', "Student Name") + "</div>" + topRowHtml +"</div>";
        })
        .find(".row")
          .attr("role", "row")
          .prepend(function(index){
            return "<div id='th_" + $studentNames.eq(index).parents(".student_header").attr('id') + "' tabindex='-1' class='ui-helper-hidden-accessible' role='rowheader'>" + $studentNames.eq(index).html() + "</div>";
          });
      $grid.find(".data_cell").attr({
        "role": "gridcell",
        "tabindex": -1 ,
        "aria-labelledby": function(){
          var parts         = $(this).find(".table_entry").attr("id").split("_"),
              student_id    = parts[1],
              assignment_id = parts[2];
          return "th_assignment_"+assignment_id+" th_student_"+student_id;
        }
      });
    }
  };
  
  $(document).ready(function() {
    gradebook.pointCalculations = !$("#class_weighting_policy").attr('checked');
    var init = function() {
      $("#gradebook_full_content").hide();
      setTimeout(function() {
        $("#gradebook_table").bind('entry_over', function(event, grid) {
          if(grid.trueEvent) {
            gradebook.showInfoLink(grid.cell);
            function showTooltip(tip, skinny) {
              var position = grid.cell.offset();
              $total_tooltip.show().find(".text").html(tip);
              var height = $total_tooltip.outerHeight();
              $total_tooltip.css({
                left: position.left - (skinny ? 15 : 2),
                top: position.top - height - 3
              });
            }
            if(grid.cell.hasClass('late')) {
              showTooltip(I18n.t('tooltips.submitted_late', 'This submission was submitted late'));
            } else if(grid.cell.hasClass('dropped')) {
              showTooltip(I18n.t('tooltips.submission_dropped', 'This submission is dropped for grading purposes'));
            } else if(datagrid.columns[grid.cell.column].hidden) {
              var name = objectData(datagrid.cells['0,' + grid.cell.column]).title;
              showTooltip(htmlEscape(name) + "<br/><span style='font-size: 0.9em;'>" + I18n.t('click_to_expand', "Click to expand") + "</span>", true)
            }
          } else if(event && event.originalEvent && event.originalEvent.type && !event.originalEvent.type.match(/mouse/)) {
            grid.cell.find(".grade").focus().css('outline', 0);
          }
        }).bind('entry_out', function(event, grid) {
          gradebook.hideInfoLink();
        }).bind('entry_click', function(event, grid) {
          var $cell = grid.cell;
          if(event.originalEvent && $(event.originalEvent.target).closest(".display_name,.assignment_title").length == 0) {
            event.originalEvent.preventDefault();
          }
          if($cell.hasClass('column_header') || $cell.hasClass('row_header') || $cell.find(".grade").hasClass('hard_coded')) {
            return;
          }
          grid.cell.data('from_click', true);
          datagrid.focus($cell.row, $cell.column);
          grid.cell.data('from_click', false);
        }).bind('entry_focus', function(event, grid) {
          if(readOnlyGradebook) { 
            datagrid.blur();
            return false; 
          }
          var $obj = grid.cell.find(".table_entry"),
              $grade = $obj.find(".grade"),
              editable = true,
              val = $.trim($grade.text());
          gradebook.hideInfoLink();
          if($obj.find(".grade img.submission_icon").length > 0 && grid.cell.data('from_click')) { 
            submissionInformation(grid.cell);
            datagrid.blur();
            return;
          }
          if($grade.hasClass('hard_coded')) {
            editable = false;
          }
          if(!editable) { return; }

          if($grade.find("img.graded_icon").length) {
            val = $grade.find("img.graded_icon").attr('alt').toLowerCase();
          } else if($obj.find(".score").length > 0 && !(val && val.match(/.+%/))) {
            var submission = objectData(grid.cell);
            var grading_type = $("#outer_assignment_" + submission.assignment_id).find(".grading_type").text();
            if(grading_type == "gpa_scale"){
              val = $.trim($obj.find(".grade").text());
            }else{
              val = $.trim($obj.find(".score").text());
            }
          }
          val = $.trim(val);
          if(val == "-") {
            val = "";
          }
          var submission = objectData(grid.cell);
          if(editable) {
            var width = grid.cell.width(),
                height = grid.cell.height(),
                assignment_id = submission.assignment_id,
                $box = $("#student_grading_" + assignment_id).clone(true),
                //  todo: replace .andSelf with .addBack when JQuery is upgraded.
                $input = $box.children().andSelf().filter(".grading_value");
            $grade.hide().after($box);
            $box.css('display', 'block');
            if($input.attr('type') == 'text') {
              width -= 8;
              height -= 8;
            } else {
              width -= 2;
              height -= 2;
            }
            $box.width(width).height(height).css('margin', 1);
            $input.height(height);
            if($input[0].tagName != "SELECT" || val !== "") {
              $input.val(val);
            }
            $box.show();
            $input.focus().select();
          }
          $obj.find(".new_message,.pending_review").hide();
        }).bind('entry_blur', function(event, grid) {
          var $obj = grid.cell.find(".table_entry");
          
          $obj.find(".new_message,.pending_review.showable,.grade").show();
          $obj.find(".grading_box").remove();
          grid.cell.triggerHandler('mouseover');
          setTimeout(function() {
            gradebook.showInfoLink(grid.cell);
          }, 50);
        });
        setTimeout(moreInit, 50);
      }, 1000);
    };
    var moreInit = function() {
      $(".delete_comment_attachment_link").click(function(event) {
        event.preventDefault();
        $(this).parents(".comment_attachment").slideUp(function() {
          $(this).remove();
        });
      });
      $(".attach_comment_file_link").click(function(event) {
        event.preventDefault();
        var $attachment = $(this).parents(".add_comment").find(".comment_attachment:last").clone(true);
        $attachment.find("input").attr('name', 'attachments[' + (gradebook.fileIndex++) + '][uploaded_data]');
        $(this).parents(".add_comment").find(".comment_attachments").append($attachment);
        $attachment.slideDown();
      });
      $(".grading_value").keycodes('esc return tab', function(event) {
        event.preventDefault();
        event.stopPropagation();
        if(event.keyString == 'return' || event.keyString == 'tab') { //Code == 13 || event.keyCode == 9) {
          $(this).triggerHandler('blur', true);
          if(event.keyString == 'return') { //Code == 13) {
            datagrid.moveDown();
          } else {
            datagrid.moveRight();
          }
        } else if (event.keyString == 'esc') { //keyCode == 27) {
          // This makes it so when you press escape, the gricell gets focus back, 
          // so JAWS doesn't think we're "not in a table" 
          // First get a reference to the parent gridcell, we need to do it first because datagrid.blur(); will remove $(this) from the DOM
          var $gridcell = $(this).parents("[role='gridcell']");
          datagrid.blur();
          // after datagrid does its blur stuff. then give focus back to the girdcell
          $gridcell.focus();
        }
      });
      $(".grading_value").blur(function(event, forceUpdate) {
        var $td = $(this).parents(".table_entry").parents("div.cell");
        if($td.length > 0) {
          var $box = $(this);
          if($box.parents(".grading_box").length) {
            $box = $box.parents(".grading_box");
          }
          updateDataEntry($box, forceUpdate);
          datagrid.blur();
        }
      });
      $default_grade_form.formSubmit({
        beforeSubmit: function(data) {
          $default_grade_form.loadingImage().find(".cancel_button").attr('disabled', true);
        },
        processData: function(data) {
          var idx = 0;
          $(".table_entry.assignment_" + data.assignment_id + ":visible").each(function() {
            var $this = $(this),
                objData = objectData($this.parent()),
                pre = 'submissions[submission_' + idx + ']';
            
            if((!objData.score && objData.score !== 0) || data.overwrite_existing_grades) {
              data[pre + '[assignment_id]'] = data.assignment_id;
              data[pre + '[user_id]'] = objData.user_id;
              data[pre + '[grade]'] = data.default_grade;
              idx++;
            }
          });
          if(idx === 0) {
            alert(I18n.t('alerts.none_to_update', "None to Update"));
            return false;
          }
          return data;
        },
        success: function(data) {
          $default_grade_form.loadingImage('remove');
          for(var idx in data) {
            var submission = data[idx].submission;
            updateSubmission(submission);
            studentsToUpdate.push(submission.user_id);
          }
          alert(I18n.t('alerts.scores_updated', {'one': '1 Student score updated', 'other': '%{count} Student scores updated'}, {'count': data.length}));
          $default_grade_form.find(".cancel_button").attr('disabled', false);
          $default_grade_form.dialog('close');
        }
      }).find(".cancel_button").click(function() {
        $default_grade_form.dialog('close');
      });
      $("#gradebook_full_content,.datagrid").delegate('.assignment_dropdown', 'click', function(event) {
        var $obj                 = $(this),
            $parent              = $obj.parent(),
            extendedGradebookURL = $obj.parents(".assignment_name").find(".grade_assignment_link").attr('href'),
            $td                  = $obj.parents(".assignment_name"),
            $cell                = $(this).parents(".cell"),
            options              = {},
            columnData           = objectData($td);

        var addOption = function(icon, text, func) {
          var label = '<span class="ui-icon ui-icon-' + icon + '">&nbsp;</span> ' + text;
          options[label] = func;
        };
            
        if(!$td.hasClass('group_total') && !$td.hasClass('final_grade')) {
          if(object_data.submissions) {
            addOption('info', I18n.t('assignment_details', 'Assignment Details'), function() {
              var data = objectData($td),
                  $submissions = $(".student_assignment .assignment_" + data.assignment_id);
                  
              data.url = $td.find(".assignment_link").attr('href');
              data.cnt = 0;
              data.score_total = 0.0;
              $submissions.each(function() {
                var $submission = $(this),
                    submission = objectData($submission.parent());
                if(submission.score !== null && submission.score !== undefined && submission.score !== "") {
                  data.cnt++;
                  data.score_total += submission.score;
                  if(data.max == null || submission.score > data.max) {
                    data.max = submission.score;
                  }
                  if(data.min == null || submission.score < data.min) {
                    data.min = submission.score;
                  }
                }
              });
              data.max = data.max || 0.0;
              data.min = data.min || 0.0;
              data.average = Math.round(data.score_total * 10.0 / data.cnt) / 10.0;
              if(isNaN(data.average) || !isFinite(data.average)) {
                data.average = I18n.t('#not_applicable', "N/A");
              }
              var tally = 0, width = 0, totalWidth = 200;
              $assignment_details_dialog
                .find(".distribution").showIf(data.average && data.points_possible)
                  .find(".none_left").width(width = totalWidth * (data.min / data.points_possible)).css('left', (tally += width) - width).end()
                  .find(".some_left").width(width = totalWidth * ((data.average - data.min) / data.points_possible)).css('left', (tally += width) - width).end()
                  .find(".some_right").width(width = totalWidth * ((data.max - data.average) / data.points_possible)).css('left', (tally += width) - width - 2).end()
                  .find(".none_right").width(width = totalWidth * ((data.points_possible - data.max) / data.points_possible)).css('left', (tally += width) - width);
              $assignment_details_dialog.fillTemplateData({
                  data: data
                })
                .dialog({
                  title: I18n.beforeLabel('details', "Details") + " " + data.title
                })
                .find(".assignment_link").attr('href', data.url);
            });
          }
          if (speedGraderEnabled) {
            addOption('newwin', I18n.t('speed_grader', 'SpeedGrader'), function() {
              window.location.href = extendedGradebookURL;
            });
          }

          var muteLink = {
            elements: {
              assignments: {},
              modal: $('#mute_dialog'),
              rows: $('#datagrid_top .row, #datagrid_data .row')
            },

            init: function(){
              this.isMuted = $parent.data('muted');
              this.label = this.isMuted ?
                I18n.t('unmute_assignment', 'Unmute Assignment') :
                I18n.t('mute_assignment', 'Mute Assignment');
            },

            onClick: function(e){
              this.url = $parent.attr('href') + '/mute';
              this.isMuted ? this.updateStatus() : this.showDialog();
            },

            showDialog: function(){
              var cancelLabel = I18n.t('cancel_button', 'Cancel'),
                  muteLabel   = I18n.t('mute_assignment', 'Mute Assignment'),
                  buttons     = {};
              buttons[muteLabel]   = $.proxy(function(){
                this.updateStatus();
                this.elements.modal.dialog('close');
              }, this);
              buttons[cancelLabel] = $.proxy(function(){ this.elements.modal.dialog('close'); }, this);
              this.elements.modal.dialog({
                autoOpen: false,
                buttons: buttons,
                modal: true,
                resizable: false,
                title: this.elements.modal.data('title'),
                width: 400
              });

              this.elements.modal.dialog('open');
            },

            updateStatus: function(){
              $.ajaxJSON(this.url, 'put', { status : !this.isMuted }, $.proxy(this.onUpdate, this));
            },

            onUpdate: function(data){
              var key = 'assignment_' + data.assignment.id,
                  assignment;

              $parent.data('muted', !this.isMuted);
              if (typeof this.elements.assignments[key] === 'undefined'){
                this.elements.assignments[key] = {};
                this.elements.assignments[key].assignment = $('#' + key);
                this.elements.assignments[key].cell = this.elements.assignments[key].assignment.parent();
                this.elements.assignments[key].index = this.elements.assignments[key].cell.data('column');
                this.elements.assignments[key].column = $('.content div[data-column=' + this.elements.assignments[key].index + ']');
              }

              assignment = this.elements.assignments[key];
              this.isMuted ? this.unmuteAssignment(assignment) : this.muteAssignment(assignment);
            },

            muteAssignment: function(assignment){
              var icon = $('<a />', { 'class': 'mute_icon', title: I18n.t('teacher_muted_title', 'Assignment is muted') }).
                append($('<img />', { src: '/images/sound_mute.png', alt: '' }));

              assignment.assignment
                .find('a.assignment_link.assignment_title')
                .after(icon);
              assignment.column.width(assignment.column.width() + 20);
              this.elements.rows.width(this.elements.rows.width() + 20);
            },

            unmuteAssignment: function(assignment){
              assignment.assignment.find('.mute_icon').remove();
              assignment.column.width(assignment.column.width() - 20);
              this.elements.rows.width(this.elements.rows.width() - 20);
            }
          };

          muteLink.init();
          addOption('volume-on', muteLink.label, $.proxy(muteLink.onClick, muteLink));

          if(object_data.submissions) {
            if(!readOnlyGradebook) {
              addOption('mail-closed', I18n.t('message_students_who', 'Message Students Who...'), function() {
                var data = objectData($td),
                    title = data.title,
                    $submissions = $("#datagrid_data .assignment_" + data.id);

                var students_hash = {};
                $("#datagrid_left .student_header").each(function(i) {
                  var student = {};
                  student.id = $(this).attr('id').substring(8);
                  student.name = $(this).find(".display_name").text();
                  students_hash[student.id] = student;
                });
                $submissions.each(function() {
                  var data = objectData($(this).parent());
                  if(students_hash[data.user_id]) {
                    students_hash[data.user_id].score = data.score;
                    students_hash[data.user_id].submitted_at = data.submitted_at;
                    students_hash[data.user_id].graded_at = data.graded_at;
                  }
                });
                var students = [];
                for(var idx in students_hash) {
                  students.push(students_hash[idx]);
                }

                var hasSubmission = true;
                if (!data.submission_types || data.submission_types.match(/none|on_paper/)) {
                  hasSubmission = false;
                }
                var options = [
                  {text: I18n.t('students_who.havent_submitted_yet', "Haven't submitted yet")},
                  {text: I18n.t("students_who.havent_been_graded", "Haven't been graded")},
                  {text: I18n.t('students_who.scored_less_than', "Scored less than"), cutoff: true},
                  {text: I18n.t('students_who.scored_more_than', "Scored more than"), cutoff: true}
                ];
                if (!hasSubmission) {
                  options.splice(0, 1)
                }
                
                window.messageStudents({
                  options: options,
                  title: title,
                  points_possible: data.points_possible,
                  students: students,
                  context_code: data.context_code,
                  callback: function(selected, cutoff, students) {
                    students = $.grep(students, function($student, idx) {
                      var student = $student.user_data;
                      if(selected == I18n.t('students_who.not_submitted_yet', "Haven't submitted yet")) {
                        return !student.submitted_at;
                      } else if (selected == I18n.t("students_who.havent_been_graded", "Haven't been graded")) {
                        return student.score === null;
                      } else if(selected == I18n.t('students_who.scored_less_than', "Scored less than")) {
                        return student.score != null && student.score !== "" && cutoff != null && student.score < cutoff;
                      } else if(selected == I18n.t('students_who.scored_more_than', "Scored more than")) {
                        return student.score != null && student.score !== "" && cutoff != null && student.score > cutoff;
                      }
                    });
                    return $.map(students, function(student) { return student.user_data.id; });
                  },
                  subjectCallback: function(selected, cutoff) {
                    cutoff = cutoff || '';
                    if(selected == I18n.t('students_who.not_submitted_yet', "Haven't submitted yet")) {
                      return I18n.t('students_who.no_submission_for', 'No submission for %{assignment}', {assignment: data.title});
                    } else if (selected == I18n.t("students_who.havent_been_graded", "Haven't been graded")) {
                      return I18n.t('students_who.no_grade_for', 'No grade for %{assignment}', {assignment: data.title});
                    } else if(selected == I18n.t('students_who.scored_less_than', "Scored less than")) {
                      return I18n.t('students_who.scored_less_than_on', 'Scored less than %{cutoff} on %{assignment}', {assignment: data.title, cutoff: cutoff});
                    } else if(selected == I18n.t('students_who.scored_more_than', "Scored more than")) {
                      return I18n.t('students_who.scored_more_than_on', 'Scored more than %{cutoff} on %{assignment}', {assignment: data.title, cutoff: cutoff});
                    }
                  }
                });
              });
              addOption('check', I18n.t('set_default_grade', 'Set Default Grade'), function() {
                var data = objectData($td),
                    title = data.title;
                
                $default_grade_form.find(".assignment_title").text(title).end();
                $default_grade_form.find(".assignment_id").val(data.assignment_id);
                $default_grade_form.find(".out_of").showIf(data.points_possible || data.points_possible === '0');
                $default_grade_form.find(".points_possible").text(data.points_possible);
                var url = $.replaceTags($default_grade_form.find(".default_grade_url").attr('href'), 'id', data.id);
                url = $update_submission_form.attr('action');
                $default_grade_form.attr('action', url).attr('method', 'POST');
                var $input = $box = $("#student_grading_" + data.id).clone();
                if(!$box.hasClass('grading_value')) { $input = $box.find(".grading_value"); }
                $input.attr('name', 'default_grade').show();
                $default_grade_form.find(".grading_box_holder").empty().append($box);
                $default_grade_form.dialog({
                  width: 350,
                  height: "auto",
                  open: function() {
                    $default_grade_form.find(".grading_box").focus();
                  }
                }).dialog('option', 'title', I18n.t('default_grade_for_course', "Default Grade for %{assignment}", {'assignment': title}));
              });
              if(columnData.grading_type != 'pass_fail' && columnData.points_possible) {
                addOption('check', I18n.t('curve_grades', 'Curve Grades'), function() {
                  var data = objectData($td),
                      title = data.title;    
                  $curve_grade_dialog
                    .find(".assignment_title").text(title).end()
                    .find(".assignment_id").val(data.assignment_id).end()
                    .find(".out_of").showIf(data.points_possible || data.points_possible === '0').end()
                    .find("#middle_score").val(parseInt((data.points_possible || 0) * 0.6, 10)).end()
                    .find(".points_possible").text(data.points_possible).end()
                    .dialog({
                      width: 350,
                      height: "auto",
                      open: function() {
                        gradebook.curve();
                      }
                    }).dialog('option', 'title', I18n.t('curve_grade_for_course', "Curve Grade for %{assignment}", {'assignment': title}));
                });
              }
            }
            var data = objectData($td);
            if(data.submission_types && data.submission_types.match(/(online_upload|online_text_entry|online_url)/)) {
              addOption('disk', I18n.t('download_submissions', 'Download Submissions'), function() {
                var url = $(".download_assignment_submissions_url").attr('href');
                url = $.replaceTags(url, "assignment_id", data.assignment_id);
                try {
                  object_data['assignment_' + data.assignment_id].assignment.submissions_downloads = (data.submissions_downloads || 0) + 1;
                } catch(e) { }
                INST.downloadSubmissions(url);
              });
            }
            if(data.submissions_downloads && data.submissions_downloads > 0 && !readOnlyGradebook) {
              addOption('arrowthickstop-1-n', I18n.t('reupload_submissions', 'Re-Upload Submissions'), function() {
                var url = $("#re_upload_submissions_form").find(".re_upload_submissions_url").attr('href');
                url = $.replaceTags(url, "assignment_id", data.assignment_id);
                $("#re_upload_submissions_form").attr('action', url);
                $("#re_upload_submissions_form").dialog({
                  title: I18n.t('reupload_submission_files', "Re-Upload Submission Files"),
                  width: 350
                });
              });
            }
          }
        }
        addOption('carat-1-w', I18n.t('hide_column', 'Hide Column'), function() {
          datagrid.toggleColumn(datagrid.position($cell).column);
        });
        if($td.hasClass('group_total')) {
          var type = $td.find(".assignment_title").text();
          addOption('carat-1-w', htmlEscape(I18n.t('hide_all_things', 'Hide All %{things}', {'things': type})), function() {
            var check_id = objectData($td).assignment_group_id;
            $(".outer_assignment_name").each(function() {
              var assignment = objectData($(this));
              var group_id = assignment.assignment_group_id;
              if(check_id && (check_id == "group-" + group_id || check_id == group_id)) {
                var column = datagrid.position($("#assignment_" + assignment.id).parents(".cell")).column;
                datagrid.toggleColumn(column, false, {skipSizeGrid: true});
                datagrid.sizeGrid();
              }
            });
          });
        }
        $(this).dropdownList({
          options: options
        });
        return false;
      });
      $("#re_upload_submissions_form").submit(function() {
        var data = $(this).getFormData();
        if(!data.submissions_zip) {
          return false;
        } else if(!data.submissions_zip.match(/\.zip$/)) {
          $(this).formErrors({
            submissions_zip: I18n.t('errors.upload_as_zip', "Please upload files as a .zip")
          });
          return false;
        }
      });
      $(document).keycodes("return h i r 1 2 3 4 5 6 7 8 9 0", function(event) {
        if(datagrid.currentFocus || !datagrid.currentHover) {
          return;
        }
        if($(event.target).closest(".ui-dialog").length > 0) { return; }
        var $current = datagrid.currentHover;

        if(event.keyString == "return") {
          if($current.hasClass('student_assignment')) {
            datagrid.focus($current.row, $current.column);
          }
        } else if(event.keyString == "h") {
          datagrid.toggleColumn($current.column);
        } else if(event.keyString == "i") {
          event.preventDefault();
          if($current.hasClass('student_assignment')) {
            submissionInformation($current);
          }
        } else if(event.keyString == "r") {
          updateGrades(false);
        } else {
          if($current.hasClass('student_assignment')) {
            datagrid.focus($current.row, $current.column);
          }
        }
      });
      $("#datagrid_data").delegate("#information_link, .new_message, .pending_review, .turnitin", "click", function() {
        submissionInformation($(this).parents(".student_assignment"));
        return false;
      });
      $submission_information.find(".add_comment_link").click(function() {
        $(this).parent().find(".comment_text").css('display', 'block').focus().select();
        return false;
      });
      $submission_information.find(".cancel_button").click(function() {
        $submission_information.dialog("close");
      });
      $submission_information.find(".update_button").click(function() {
        var data = $submission_information.getTemplateData({
          textValues: ['id', 'student_id', 'assignment_id']
        });
        data.comment = $submission_information.find("textarea.comment_text").val();
        data.grade = $submission_information.find(".grading_value").val();
        data.group_comment = $submission_information.find("#group_comment_checkbox").attr('checked');
        submitDataEntry(data, true);
        $submission_information.dialog("close");
      });
      $(".refresh_grades_link").click(function() {
        updateGrades(false);
        return false;
      });
      setTimeout(function() { updateGrades(true); }, 120000);
      
      $("#hide_students_option").change(function(event) {
        var isChecked = $(this).attr('checked');
        $(".student_name")
          .find(".display_name").showIf(!isChecked).end()
          .find(".hidden_name").showIf(isChecked);
      }).change();
      $("#groups_data")
      .find(".group_weight").change(function(event) {
        var val = parseFloat($(this).val(), 10);
        $(this).val(round(val,2));
        var $group = $(this).parents(".group"),
            url = $group.find(".assignment_group_url").attr('href'),
            formData = $group.getFormData(),
            data = {};
        
        data['assignment_group[group_weight]'] = formData.group_weight;
        $.ajaxJSON(url, 'PUT', data, function(data) {
          $group.find(".group_weight").val(data.assignment_group.group_weight);
          updateGroupTotal(true);
        });
        updateGroupTotal();
      }).end()
      .find(".cancel_button").click(function() {
        $("#groups_data").dialog('close');
      }).end()
      .find("#class_weighting_policy").change(function(event) {
        var url = $(".weighting_policy_url").attr('href'),
            data = {},
            doWeighting = $(this).attr('checked'),
            $checkbox = $(this);
        
        data['course[group_weighting_scheme]'] = doWeighting ? "percent" : "equal";
        $.ajaxJSON(url, 'PUT', data, function(data) {
          $checkbox.attr('checked', data.course.group_weighting_scheme == 'percent');
          gradebook.pointCalculations = !$("#class_weighting_policy").attr('checked');
          updateGroupTotal(true);
        });
      });
      setTimeout(secondaryInit, 500);
    };
    
    var browser = navigator.appName,
        version = parseFloat(navigator.appVersion),
        sub = navigator.productSub || "20070000",
        students_count = $("#student_names .outer_student_name").length;
        
    if(isNaN(version)) { version = null; }
    var gridInit = function() {
      $("#no_students_message, #gradebook_table, .datagrid").addClass('hidden-readable');
      var fragmentCallback = function(event, hash) {
        if(hash.length > 1) {
          hash = hash.substring(1);
        }
        hash = hash.replace(/\//g, "_");
        if(hash.indexOf("student") == 0 || hash.indexOf("assignment") == 0 || hash.indexOf("submission") == 0) {
          var $div = $("#" + hash),
              position = datagrid.position($div.parent()),
              row = position.row,
              col = position.column;
          datagrid.scrollTo(row, col);
          $div.parent().trigger('mouseover');
        }
      };
      var templateHTML = $("#gradebook_entry_template").html();
      datagrid.init($("#gradebook_table"), {
        paddingBottom: $("#fixed_bottom").height(),
        templateCellHTML: function(row, col) {
          var user_id = id_maps["row_" + row],
              assignment_id = id_maps["column_" + col],
              hard_coded_class = id_maps["hard_coded_" + col] ? "hard_coded" : "";
          return templateHTML.replace(/ASSIGNMENT_ID/g, assignment_id).replace(/USER_ID/g, user_id).replace(/HARD_CODED_CLASS/g, hard_coded_class);
        },
        scroll: function() {
          $total_tooltip.hide();
        },
        onReady: function() {
          $(".table_entry.hard_coded .pct").text("%");
          object_data = object_data || {};
          object_data.grid = true;
          $(document).fragmentChange(fragmentCallback);
          $(document).fragmentChange();
          var columns = $.grep((userSettings.contextGet('hidden_columns') || []), function(e) { return e; });
          var columns_to_hide = [];
          
          if(columns.length) {
            $("#" + columns.join(',#')).parent().each(function() {
              columns_to_hide.push(this);
            });
          }
          if (!userSettings.contextGet('show_attendance')) {
            $(".cell.assignment_name.attendance").each(function() {
              columns_to_hide.push(this);
            });
          }
          function updateMutedColumnWidths(){
            var $icons = $('.mute_icon:visible'),
                $rows = $('#datagrid_data .row, #datagrid_top .row');
            $icons.each(function(i, el){
              var $el     = $(el),
                  $cell   = $el.parents('.column_header');
                  index   = $cell.data('column'),
                  $column = $('.content div[data-column= ' + index + ']');

              $column.width($column.width() + 20);
            });
            $rows.width($rows.width() + $icons.length * 20);
          }
          function nextColumn(i) {
            var column = columns_to_hide.shift();
            if(column) {
              datagrid.toggleColumn(datagrid.position($(column)).column, false, {callback: false, skipSizeGrid: true});
              if(i > 5) {
                setTimeout(function() { nextColumn(0); }, 500);
              } else {
                nextColumn(i + 1);
              }
            } else {
              datagrid.sizeGrid();
              updateMutedColumnWidths();
            }
          }
          setTimeout(function() { nextColumn(0); }, 50);
          var clump_size = INST.browser.ie ? 25 : 100;
          function moreSubmissions() {
            for(var idx = 0; idx < clump_size; idx++) {
              var item = gradebook.queuedSubmissions && gradebook.queuedSubmissions.shift();
              if(item) {
                updateSubmission(item);
              }
            }
            if(gradebook.queuedSubmissions && gradebook.queuedSubmissions.length) {
              setTimeout(moreSubmissions, 1);
            }
            else { //that means we are done loading everything, so lets start setting up the ARIA stuff
              gradebook.makeAccessible();
            }
          }
          setTimeout(moreSubmissions, 1);
        },
        tick: function() {
          $loading_gradebook_progressbar.progressbar('option', 'value', $loading_gradebook_progressbar.progressbar('option', 'value') + (25 / students_count));
        },
        toggle: function(column, show) {
          var $cell = datagrid.cells[0 + ',' + column];
          var id = $cell.children('.assignment_header').attr('id');
          var columns = $.grep((userSettings.contextGet('hidden_columns') || []), function(e) {
            return e && (!show || e != id);
          });
          if(!show) {
            columns.push(id);
          }
          columns = $.uniq(columns);
          userSettings.contextSet('hidden_columns', columns);
        }
      });
    };
    if(browser && version && (browser.match(/Netscape/ && sub < '20080000') || (browser.match(/Internet Explorer/) && version < 5))) {
      setTimeout(gridInit, 50);
    } else {
      gridInit();
    }
    var checkInit = function() {
      if(object_data && object_data.grid && object_data.assignments && object_data.students && !checkInit.initialized) {
        checkInit.initialized = true;
        $("#gradebook_table, .datagrid, #no_students_message").removeClass('hidden-readable');
        $("#loading_gradebook_message").hide();
        $(window).triggerHandler('resize');
        setTimeout(init, 500);
      }
      if(object_data && object_data.grid && object_data.assignments && object_data.students && object_data.submissions) {
        $(".student_assignment .table_entry").css('visibility', '');
        $loading_gradebook_progressbar.progressbar('option', 'value', $loading_gradebook_progressbar.progressbar('option', 'value') + 50);
        $("#sort_rows_dialog .grade_sorts").show();
        $(window).triggerHandler('resize');
        setTimeout(gradebook.populate, 1);
      } else {
        setTimeout(checkInit, 1);
      }
    };
    setTimeout(checkInit, 1);
    var ajaxInit = function() {
      var loaded = 0;
      $loading_gradebook_progressbar.progressbar('option', 'value', $loading_gradebook_progressbar.progressbar('option', 'value') + 5);
      function tick() {
        var val = $loading_gradebook_progressbar.progressbar('option', 'value') || 15;
        if(val < 85) {
          val = Math.min(val + 1, 85);
          $loading_gradebook_progressbar.progressbar('option', 'value',  val);
        }
      }
      setInterval(function() {
        if(loaded < 3) {
          tick();
        }
      }, 250);
      var pre = location.href.split("#")[0];
      pre = pre + (location.href.match(/\?/) ? "&" : "?");
      function getClump(url, clump_type, clump_size) {
        $.ajaxJSON(url, "GET", {}, function(data) {
          loaded++;
          object_data = object_data || {};
          if(clump_type == 'assignments') {
            $loading_gradebook_progressbar.progressbar('option', 'value', $loading_gradebook_progressbar.progressbar('option', 'value') + 10);
            for(var idx in data) {
              gradebook.assignmentIndexes[data[idx].assignment.id] = idx + 1;
              object_data['assignment_' + data[idx].assignment.id] = data[idx];
            }
            object_data.assignments = true;
          } else if(clump_type == 'students') {
            $loading_gradebook_progressbar.progressbar('option', 'value', $loading_gradebook_progressbar.progressbar('option', 'value') + 10);
            for(var idx in data) {
              gradebook.studentIndexes[data[idx].user.id] = idx + 1;
              object_data['student_' + data[idx].user.id] = data[idx];
            }
            object_data.students = true;
          } else {
            tick();
            var user_ids = [];
            for(var idx in data) {
              object_data['submission_' + data[idx].submission.user_id + '_' + data[idx].submission.assignment_id] = data[idx];
              updateSubmission(data[idx].submission);
              user_ids.push(data[idx].submission.user_id);
            }
            object_data.student_submissions_count = object_data.student_submissions_count || 0;
            object_data.student_submissions_count = object_data.student_submissions_count + (clump_size || 1);
            user_ids = _.uniq(user_ids);
            for(var idx in user_ids) {
              $(".table_entry.student_" + user_ids[idx]).css('visibility', '');
            }

            if(object_data.student_submissions_count >= (object_data.students_count || 1)) {
              object_data.submissions = true;
            }
          }
        }, function(data) {
          getClump.errors = getClump.errors || 0;
          getClump.errors++;
          if(getClump.errors > 10) {
            $("#loading_gradebook_status").text(I18n.t('errors.failed_to_load', "Gradebook failed to load, please try refreshing the page"));
          } else {
            setTimeout(function() { getClump(url); }, 50);
          }
        });
      };
      getClump(pre + "init=1&assignments=1", 'assignments');
      getClump(pre + "init=1&students=1", 'students');
      object_data = object_data || {};
      object_data.students_count = $("#student_names .outer_student_name").length;
      var clump_size = Math.round(200 / ($("#assignment_names .outer_assignment_name").length || 1));
      var clump = [];
      setTimeout(function() {
        if($("#student_names .outer_student_name .assignment_header").length === 0) {
          object_data.submissions = true;
          return;
        }
        $("#student_names .outer_student_name .assignment_header").each(function() {
          var id = ($(this).attr('id') || "").substring(14);
          if(id) {
            clump.push(id);
          }
          if(clump.length > clump_size) {
            getClump(pre + "init=1&submissions=1&user_ids=" + clump.join(","), "student_submissions", clump.length);
            clump = [];
          }
        });
        if(clump.length > 0) {
          getClump(pre + "init=1&submissions=1&user_ids=" + clump.join(","), "student_submissions", clump.length);
        }
      }, 1);
    };
    if(!object_data || !object_data.pre_initialized) {
      ajaxInit();
    } else {
      for(var idx in object_data) {
        if(object_data[idx].submission) {
          updateSubmission(object_data[idx].submission);
        }
      }
      object_data.assignments = true;
      object_data.students = true;
      object_data.submissions = true;
    }

    setTimeout(function() {
      gradebook.curve = function() {
        var idx = 0,
            scores = {},
            data = $curve_grade_dialog.getFormData(),
            assignment = objectData($("#assignment_" + data.assignment_id).parent()),
            points_possible = assignment.points_possible,
            users_for_score = [],
            scoreCount = 0,
            middleScore = parseInt($("#middle_score").val(), 10);
            
        $(".table_entry.assignment_" + data.assignment_id).each(function() {
          var objData = objectData($(this).parent());
          if(objData.score || data.assign_blanks) {
            scores[objData.user_id] = objData.score || 0;
          }
        });
        middleScore = (middleScore / points_possible);
        if(isNaN(middleScore)) {
          return;
        }
        for(var idx in scores) {
          var score = scores[idx];
          if(score > points_possible) { score = points_possible; }
          if(score < 0) { score = 0; }
          users_for_score[parseInt(score, 10)] = users_for_score[parseInt(score, 10)] || [];
          users_for_score[parseInt(score, 10)].push([idx, (score || 0)]);
          scoreCount++;
        }
        var breaks = [0.006, 0.012, 0.028, 0.040, 0.068, 0.106, 0.159, 0.227, 0.309, 0.401, 0.500, 0.599, 0.691, 0.773, 0.841, 0.894, 0.933, 0.960, 0.977, 0.988, 1.000];
        var interval = (1.0 - middleScore) / Math.floor(breaks.length / 2);
        var breakScores = [];
        var breakPercents = [];
        for(var idx = 0; idx < breaks.length; idx++) {
          breakPercents.push(1.0 - (interval * idx));
          breakScores.push(Math.round((1.0 - (interval * idx)) * points_possible));
        }
        var tally = 0;
        var finalScores = {};
        var currentBreak = 0;
        $("#results_list").empty();
        $("#results_values").empty();
        var final_users_for_score = [];
        for(var idx = users_for_score.length - 1; idx >= 0; idx--) {
          var users = users_for_score[idx] || [];
          var score = Math.round(breakScores[currentBreak]);
          for(var jdx in users) {
            var user = users[jdx];
            finalScores[user[0]] = score;
            if(user[1] == 0) {
              finalScores[user[0]] = 0;
            }
            finalScore = finalScores[user[0]];
            final_users_for_score[finalScore] = final_users_for_score[finalScore] || [];
            final_users_for_score[finalScore].push(user[0]);
          }
          tally += users.length;
          while(tally > (breaks[currentBreak] * scoreCount)) {
            currentBreak++;
          }
        }
        var maxCount = 0;
        for(var idx = final_users_for_score.length - 1; idx >= 0; idx--) {
          var cnt = (final_users_for_score[idx] || []).length;
          if(cnt > maxCount) { maxCount = cnt; }
        }
        var width = 15;
        var skipCount = 0;
        for(var idx = final_users_for_score.length - 1; idx >= 0; idx--) {
          if(true || final_users_for_score[idx]) {
            users = final_users_for_score[idx];
            var pct = 0;
            var cnt = 0;
            if(users || skipCount > (points_possible / 10)) {
              if(users) {
                pct = (users.length / maxCount);
                cnt = users.length;
              }
              var color = idx === 0 ? "#ee8" : "#cdf";
              $("#results_list").prepend("<td style='padding: 1px;'><div title='" + cnt + " student" + (cnt == 1 ? '' : 's') + " will get " + idx + " points' style='border: 1px solid #888; background-color: " + color + "; width: " + width + "px; height: " + (100 * pct) + "px; margin-top: " + (100 * (1 - pct)) + "px;'>&nbsp;</div></td>");
              $("#results_values").prepend("<td style='text-align: center;'>" + idx + "</td>");
              skipCount = 0;
            } else {
              skipCount++;
            }
          }
        }
        $("#results_list").prepend("<td><div style='height: 100px; position: relative; width: 30px; font-size: 0.8em;'><img src='/images/number_of_students.png' alt='# of students'/><div style='position: absolute; top: 0; right: 3px;'>" + maxCount + "</div><div style='position: absolute; bottom: 0; right: 3px;'>0</div></div></td>");
        $("#results_values").prepend("<td>&nbsp;</td>");
        return finalScores;
      };
      $("#middle_score").bind('blur change keyup focus', function() {
        gradebook.curve();
      });
      $("#assign_blanks").change(function() {
        gradebook.curve();
      });
      $assignment_details_dialog.find(".close_button").click(function() {
        $assignment_details_dialog.dialog('close');
      });
      $curve_grade_dialog.formSubmit({
        processData: function(data) {
          var cnt = 0;
          curves = gradebook.curve();
          for(var idx in curves) {
            var pre = 'submissions[submission_' + idx + ']';
            data[pre + '[assignment_id]'] = data.assignment_id;
            data[pre + '[user_id]'] = idx;
            data[pre + '[grade]'] = curves[idx];
            cnt++;
          }
          if(cnt === 0) {
            var errorBox = $curve_grade_dialog.errorBox(
              I18n.t('errors.none_to_update', 'None to Update'));

            setTimeout(function() {
              errorBox.fadeOut(function() {
                errorBox.remove();
              });
            }, 3500);

            return false;
          }
          return data;
        },
        beforeSubmit: function(data) {
          $curve_grade_dialog.loadingImage().find(".cancel_button").attr('disabled', true);
        },
        success: function(data) {
          $curve_grade_dialog.loadingImage('remove');
          for(var idx in data) {
            var submission = data[idx].submission;
            updateSubmission(submission);
            studentsToUpdate.push(submission.user_id);
          }
          alert(I18n.t('alerts.scores_updated', {'one': '1 Student score updated', 'other': '%{count} Student scores updated'}, {'count': data.length}));
          $curve_grade_dialog.find(".cancel_button").attr('disabled', false).dialog('close');
        },
        error: function(data) {
          $curve_grade_dialog.loadingImage('remove');
        }
      }).find(".cancel_button").click(function() {
        $curve_grade_dialog.dialog('close');
      });

      if (ENV.total_grade_warning) {
        $('.assignment_final-grade').not('.assignment_header').each(function() {
          $('<i/>', {
            'class': 'icon-warning',
            title: ENV.total_grade_warning
          }).prependTo(this);
        });
      }

    }, 1500);
    
    $('#gradebook_options').live('click', function(event) {
      event.preventDefault();
      event.stopPropagation();

      var options = {};
      var addOption = function(icon, text, func) {
        var label = '<span class="ui-icon ui-icon-' + icon + '" /> ' + text;
        options[label] = func;
      };

      addOption('carat-2-e-w', I18n.t('sort_columns_by', 'Sort Columns By...'), function() {
        $(".sort_gradebook").each(function() {
          $(this).attr('disabled', false).text($(this).attr('title'));
        });
        $("#sort_columns_dialog").dialog({
          autoOpen: false,
          width: 400,
          height: 300
        });
      });

      addOption('carat-2-n-s', I18n.t('sort_rows_by', 'Sort Rows By...'), function() {
        $(".sort_gradebook").each(function() {
          $(this).attr('disabled', false).text($(this).attr('title'));
        });
        $("#sort_rows_dialog").dialog({
          width: 400,
          height: 300
        });
      });

      addOption('pencil', I18n.t('set_group_weights', 'Set Group Weights'), function() {
        $("#groups_data").dialog({
          title: I18n.t('titles.assignment_groups', "Assignment Groups")
        }).show();
      });

      addOption('clock', I18n.t('view_grading_history', 'View Grading History'), function() {
        window.location.href = $(".gradebook_history_url").attr('href');
      });

      addOption('disk', I18n.t('download_scores', 'Download Scores (%{format})', {'format': '.csv'}), function() {
        window.location.href = $(".gradebook_csv_url").attr('href');
      });

      addOption('clock', I18n.t('upload_scores', 'Upload Scores (from %{format})', {'format': '.csv'}), function() {
        var dialogData = {
          bgiframe: true,
          autoOpen: false,
          modal: true,
          width: 410,
          resizable: false,
          buttons: {}
        };
        dialogData['buttons'][I18n.t('buttons.upload_data', 'Upload Data')] = function() { $(this).submit(); };
        $("#upload_modal").dialog(dialogData).dialog('open');
      });
      
      var show = $("#hide_students_option").attr('checked');
      addOption('person', show ? I18n.t('show_student_name', 'Show Student Names') : I18n.t('hide_student_name', 'Hide Student Names'), function() {
        $("#hide_students_option").attr('checked', !show).change();
      });

      addOption('check', ignoreUngradedSubmissions ? I18n.t('include_ungraded', 'Include Ungraded Assignments') : I18n.t('ignore_ungraded', 'Ignore Ungraded Assignments'), function() {
        ignoreUngradedSubmissions = !ignoreUngradedSubmissions;
        gradebook.updateAllStudentGrades(); 
      });
      
      // handle showing only one section
      if (_.size(possibleSections) > 1) {
        var sectionToShowLabel = sectionToShow ? 
          I18n.t('showing_section', 'Showing Section: %{section}', {'section': possibleSections[sectionToShow]}) : 
          I18n.t('showing_all_sections', 'Showing All Sections');
        addOption('search', sectionToShowLabel, function() {
          var dialogData = {
            modal: true,
            resizable: false,
            buttons: {}
          };
          dialogData['buttons'][I18n.t('buttons.change_section', 'Change Section')] = function() {
            var val = $("#section_to_show_dialog select").val();
            userSettings[val == "all" ? 'contextRemove' : 'contextSet']('grading_show_only_section', val);
            window.location.reload();
          };
          var $dialog = $("#section_to_show_dialog").dialog(dialogData);
          var $select = $dialog.find('select');
          $select.find('[value != all]').remove();
          for (var key in possibleSections) {
            $select.append('<option value="' + key + '" ' + (sectionToShow == key ? 'selected' : '') + ' >' + possibleSections[key] + '</option>'); 
          }
        });
      }

      if(sisPublishEnabled) {
        addOption('gear', '<a href="details#tab-grade-publishing">' + I18n.t('publish_to_sis', 'Publish grades to SIS') + '</a>', function() {});
      }

      $(this).dropdownList({
        options: options
      });
    });
    
    $(".sort_gradebook").click(function(event) {
      event.preventDefault();
      var $button = $(this);
      if($button.hasClass('by_grade') && !gradebook.finalGradesReady) {
        $button.attr('disabled', true).text(I18n.t('computing_grades', "Computing Grades..."));
        setTimeout(function() {
          if($button.filter(":visible").length > 0) {
            $button.click();
          }
        }, 1000);
        return;
      }
      $button.attr('disabled', false);
      $button.text($button.attr('title'));
      if($button.hasClass('sort_rows')) {
        sortStudentRows(function(student) {
          if($button.hasClass('by_secondary_identifier')) {
            return [student.secondary_identifier, student.display_name, student.course_section];
          } else if($button.hasClass('by_section')) {
            return [student.course_section, student.display_name, student.secondary_identifier];
          } else if($button.hasClass('by_grade_desc')) { 
            return [ -student.grade, student.display_name, student.secondary_identifier, student.course_section];
          } else if($button.hasClass('by_grade_asc')) {
            return [ student.grade, student.display_name, student.secondary_identifier, student.course_section];
          } else {
            return [student.display_name, student.secondary_identifier, student.course_section];
          }
        });
      } else {
        sortAssignmentColumns(function(assignment) {
          var list = [assignment.special_sort, assignment.date_sortable || "1050-12-12T99:99", assignment.title];
          if($button.hasClass('by_group')) {
            list.unshift(parseInt(assignment.groupData[assignment.group_id || assignment.id.toString().substring(6)], 10));
          }
          return list;
        });
      }
      $("#sort_rows_dialog").dialog('close');
      $("#sort_columns_dialog").dialog('close');
    });

    $('#content').delegate('.mute_icon', 'click.mute', function(e){
      var $el = $(e.currentTarget),
          $link = $el.siblings('a.assignment_link.assignment_title'),
          cancelLabel = I18n.t('cancel_button', 'Cancel'),
          unmuteLabel = I18n.t('unmute_button', 'Unmute Assignment'),
          buttons     = {},
          $modal      = $('#unmute_dialog'),
          $rows       = $('#datagrid_data .row, #datagrid_top .row'),
          url         = $link.attr('href') + '/mute';

      buttons[unmuteLabel] = function(){
        $modal.dialog('close');
        $.ajaxJSON(url, 'put', { status : false }, function(data){
          var key = 'assignment_' + data.assignment.id,
              $assignment = $('#' + key),
              $cell = $assignment.parent(),
              index = $cell.data('column'),
              $column = $('.content div[data-column=' + index + ']');
          $assignment.find('a.assignment_link.assignment_options').data('muted', false);
          $assignment.find('.mute_icon').remove();
          $column.width($column.width() - 20);
          $rows.width($rows.width() - 20);
        });
      };
      buttons[cancelLabel] = function(){ $modal.dialog('close'); };

      $modal.dialog({
        buttons   : buttons,
        modal     : true,
        resizable : false,
        title     : $modal.data('title'),
        width     : 400
      });
    });
  });


  function objectData($td) {
    var id = $td.data('object_id');
    if(!id) {
      id = $td.find(".table_entry,.student_header,.assignment_header").attr('id');
      id = id.replace(/^outer_/, "");
    }
    $td.data('object_id', id);
    var data = object_data[id];
    var vals = id.split(/[_-]/);
    var split = [];
    while(vals.length > 0 && isNaN(parseInt(vals[0], 10))) {
      split.push(vals.shift());
    }
    var name = split.join("_");
    if(!data) {
      split = id.split("_");
      data = {};
      if(split[0] == "submission") {
        data.user_id = split[1];
        data.assignment_id = split[2];
      }
      object_data[id] = {};
      object_data[id][split[0]] = data;
    } else {
      var result = data[name] || data['audit_student'] || data['user'];
      if(!result) {
        for(var idx in data) {
          result = data[idx];
        }
      }
      result[name + "_id"] = result.id;
      data = result;
    }
    if(name == "submission") {
      var assignment = object_data['assignment_' + data.assignment_id];
      assignment = assignment.assignment;
      data.assignment_group_id = assignment.assignment_group_id;
      data.points_possible = assignment.points_possible;
    }
    return data;
  }

  function submitDataEntry(data, fromDialog) {
    var formData = $update_submission_form.getFormData();
    var $div = $("#submission_" + data.student_id + "_" + data.assignment_id);
    var $obj = $div.parent();
    $div.loadingImage({image_size: "small"});
    updateSubmission({
      user_id: data.student_id,
      assignment_id: data.assignment_id,
      grade: data.grade
    });
    if(data.id && data.id !== "") {
      formData['submission[id]'] = data.id;
    }
    if(data.comment) {
      formData['submission[comment]'] = data.comment;
    }
    formData['submission[group_comment]'] = data.group_comment ? "1" : "0";
    formData['submission[assignment_id]'] = data.assignment_id;
    formData['submission[user_id]'] = data.student_id;
    formData['submission[grade]'] = data.grade;
    var formSuccess = function(data) {
      for(var idx in data) {
        var submission = data[idx].submission;
        updateSubmission(submission);
        updateStudentGrades(submission.user_id);
      }
      if(data.length > 1) {
        alert(I18n.t('alerts.students_updated', {'one': '1 Student Updated', 'other': '%{count} Students Updated'}, {'count': data.length}));
      }
      $div.loadingImage('remove');
    };
    var formError = function(data) {
      $div.loadingImage('remove');
    };
    if(fromDialog && $submission_information.find(".comment_attachments input[type='file']").length) {
      $.ajaxJSONFiles($update_submission_form.attr('action') + ".text", 'POST', formData, $submission_information.find(".comment_attachments input[type='file']"), formSuccess, formError);
    } else {
      $.ajaxJSON($update_submission_form.attr('action'), 'POST', formData, formSuccess, formError);
    }
  }

  var minute_timestamp = function(value) {
    var datetime = tz.parse(value);
    var timestamp = +datetime / 1000;
    return timestamp - (timestamp % 60);
  }

  function updateSubmission(submission) {
    if(!submission) { return; }
    var $submission = null;
    if(!datagrid.initialized) {
      var assignment_index = gradebook.assignmentIndexes[submission.assignment_id];
      var student_index = gradebook.studentIndexes[submission.user_id];
      var $cell = datagrid.cells[student_index + "," + assignment_index];
      $submission = $cell && $cell.find("#submission_" + submission.student_id + "_" + submission.assignment_id);
      if(!$submission || !$submission.length) {
        gradebook.queuedSubmissions = gradebook.queuedSubmissions || [];
        gradebook.queuedSubmissions.push(submission);
        return;
      }
    }
    object_data['submission_' + submission.user_id + '_' + submission.assignment_id] = {submission: submission};
    var assignment = object_data['assignment_' + submission.assignment_id];
    var assignment = assignment && assignment.assignment;
    submission.student_id = submission.user_id;
    $submission = $submission || $("#submission_" + submission.student_id + "_" + submission.assignment_id);
    $submission.css('visibility', '');
    var submission_stamp = submission && minute_timestamp(submission.submitted_at);
    var assignment_stamp = assignment && minute_timestamp(assignment.due_at);
    $submission.parent().toggleClass('late', !!(submission && submission.late));
    if(submission.grade !== "" && submission.grade == 0) {
      submission.grade = "0";
    }
    var $submission_score = $submission.find(".score"),
        $submission_pending_review = $submission.find(".pending_review"),
        $submission_turnitin = $submission.find(".turnitin"),
        $submission_grade = $submission.find(".grade");
    $submission_score.showIf(submission.score);
    
    $submission.fillTemplateData({data: submission});
    
    if(submission.submission_type != "online_quiz" || submission.workflow_state != "pending_review") {
      $submission_pending_review.remove();
    } else if(!$submission_pending_review.length) {
      $submission_grade.after($("#gradebook_urls .pending_review").clone());
      $submission_pending_review.addClass('showable').showIf(!$submission.find(".grading_value:visible").length);
    }
    var turnitin_data = Turnitin.extractData(submission);
    if(!turnitin_data) {
      $submission_turnitin.remove();
    } else if(!$submission_turnitin.length) { 
      var $img = $("#gradebook_urls .turnitin").clone();
      $img.attr('src', $img.attr('src').replace('turnitin_no_score', 'turnitin_' + turnitin_data.state + '_score'));
      $submission_grade.after($img);
      $submission_turnitin.addClass('showable').show();
    }
    $submission_score.showIf(assignment && assignment.grading_type == 'letter_grade');
    var grading_type = $("#outer_assignment_" + submission.assignment_id).find(".grading_type").text();
    if(grading_type == "pass_fail" && submission.grade && submission.grade != " - ") {
      $submission_grade.empty().append($("#submission_entry_" + submission.grade + "_image").clone());
    }
    if(submission.grade == null || submission.grade === "") {
      $submission_grade.empty().append(emptySubmissionText(submission));
    }
  }

  function emptySubmissionText(submission) {
    var result = $("#submission_" + submission.submission_type + "_image").clone().attr('id', '');
    if(result.length === 0) {
      result = " - ";
    }
    return result;
  }

  function updateDataEntry($box, forceUpdate) {
    var $input = $box;
    var $parent = $input.parents(".table_entry");
    if(!$box.hasClass('grading_value')) {
      $input = $box.find(".grading_value");
    }
    var val = $input.val();
    var sendVal = val;
    var oldVal = $.trim($parent.find(".grade").text());
    if($parent.find(".grade img").length > 0) {
      oldVal = $parent.find(".grade img").attr('alt').toLowerCase();
    }
    if(oldVal == "-") {
      oldVal = "";
    }

    if($input.hasClass('pass_fail')) {
      if(val == "pass" || val == "fail") {
        val = $("#submission_entry_" + val + "_image").clone().attr('id', '');
      }
    }
    var data = {};
    var formData = $update_submission_form.getFormData();
    var submission = objectData($parent.parent());
    data.id = submission.id || "";
    data.assignment_id = submission.assignment_id;
    data.student_id = submission.user_id;
    data.grade = sendVal;
    if(sendVal != oldVal || (sendVal && forceUpdate)) {
      submitDataEntry(data);
    }
    if(!val || val == "") {
      data.submission_type = submission.submission_type || "";
      val = emptySubmissionText(data);
    }
    $parent.find(".grade").show().empty().append(htmlEscape(val));
  }

  function toggleColumn($obj, show) {
    var assignment_id = objectData($obj).assignment_id;
    var $list = $(".assignment_" + assignment_id);
    if(show || (show !== false && $($list[0]).parent().hasClass('hidden_column'))) {
      $list.show().parent().removeClass('hidden_column');
    } else {
      $list.hide().parent().addClass('hidden_column');
    }
  }

  function populateSubmissionInformation($submission, submission) {
    var $td = $submission,
        assignment = object_data["assignment_" + submission.assignment_id].assignment,
        student_name = $("#outer_student_" + submission.user_id + " .display_name").text(),
        assignment_name = $("#outer_assignment_" + submission.assignment_id + " .display_name").text(),
        title = I18n.t('submission_information', "Submission Information"),
        $grade = $td.find(".grade"),
        $score = $td.find(".score"),
        grade = $.trim($grade.text()),
        $grade_entry = $("#student_grading_" + submission.assignment_id).clone(),
        comment = submission.comment || "",
        points_possible = submission.points_possible,
        $view = $(document.createElement('div')),
        $type = $(document.createElement('div')),
        url = $("#gradebook_urls .view_online_submission_url").attr('href');
        
    if(student_name && assignment_name) {
      title = assignment_name + ": " + student_name;
    }
    if ($grade.find("img").length > 0) {
      grade = $grade.find("img").attr('alt');
    }
    if($score.length > 0) {
      grade = $score.text();
    }
    if(grade == "_" || grade == "-") { grade = ""; }
    
    if($grade_entry[0].tagName == "SELECT") {
      $grade_entry.val(submission.grade);
    } else if(grade != "") {
      $grade_entry.val(grade);
    }
    
    url = $.replaceTags(url, 'assignment_id', submission.assignment_id);
    url = $.replaceTags(url, 'user_id', submission.user_id);
    if (speedGraderEnabled) {
      $view.append($("#submission_view_image").clone(true).removeAttr('id'));
      $view.append($(" <a href='" + url + "'>" + I18n.t('links.submission_details', "Submission Details") + "</a>"));
    }

    $type.css({textAlign: "center", fontWeight: "bold", fontSize: "1.2em", marginTop: 5});
    if(submission.submission_type && submission.submission_type != "online_quiz") {
      if(submission.submission_type == "online_url") {
        $type.append($("#submission_" + submission.submission_type + "_image").clone().removeAttr('id'));
        var url = submission.url;
        $type.append(" <a href='" + url + "' target='_new'>" + I18n.t('links.go_to_submission', "Go To Submission URL") + "</a>");
      } else if(submission.submission_type == "online_upload") {
        var url = $("#gradebook_urls .view_online_upload_url").attr('href');
        url = $.replaceTags(url, "assignment_id", submission.assignment_id);
        url = $.replaceTags(url, "user_id", submission.user_id);
        if(submission.attachments) {
          for(var idx in submission.attachments) {
            var attachment = submission.attachments[idx].attachment;
            var attachment_url = $.replaceTags(url, "attachment_id", attachment.id);
            var turnitin = submission.turnitin_data && submission.turnitin_data['attachment_' + attachment.id];
            if(turnitin) {
              var turnitin_url = $.replaceTags($.replaceTags($.replaceTags($(".turnitin_report_url").attr('href'), 'user_id', submission.user_id), 'asset_string', 'attachment_' + attachment.id), 'assignment_id', submission.assignment_id);
              var $link = $("<a/>");
              $link.attr('href', turnitin_url).addClass('turnitin_similarity_score').addClass(((turnitin && turnitin.state) || 'no') + '_score');
              $link.attr('title', I18n.t('titles.turnitin_score', 'Turnitin similarity score -- more information'));
              $link.attr('target', '_blank');
              $link.text((turnitin.similarity_score || '--') + "%");
              $type.append($link);
            }
            $type.append($("#submission_" + submission.submission_type + "_image").clone().removeAttr('id'));
            $type.append(" <a href='" + attachment_url + "'>" + htmlEscape(I18n.t('links.download_attachment', "Download %{attachment}", {'attachment': attachment.display_name})) + "</a><br/>");
          }
        }
      } else if(submission.submission_type == "online_text_entry") {
        var turnitin = submission.turnitin_data && submission.turnitin_data['submission_' + submission.id];
        if(turnitin) {
          var turnitin_url = $.replaceTags($.replaceTags($.replaceTags($(".turnitin_report_url").attr('href'), 'user_id', submission.user_id), 'asset_string', 'submission_' + submission.id), 'assignment_id', submission.assignment_id);
          var $link = $("<a/>");
          $link.attr('href', turnitin_url).addClass('turnitin_similarity_score').addClass(((turnitin && turnitin.state) || 'no') + '_score');
          $link.attr('title', I18n.t('titles.turnitin_score', 'Turnitin similarity score -- more information'));
          $link.attr('target', '_blank');
          $link.text(turnitin.similarity_score + "%");
          $type.append($link);
        }
        $type.append($("#submission_" + submission.submission_type + "_image").clone().removeAttr('id'));
        var url = $("#gradebook_urls .view_online_text_entry_url").attr('href');
        url = $.replaceTags(url, "assignment_id", submission.assignment_id);
        url = $.replaceTags(url, "user_id", submission.user_id);
        $type.append(" <a href='" + url + "' target='_new' class='view_submission_link'>" + I18n.t('links.view_submission', "View Submission") + "</a>");
      }
    } else if(submission.quiz_submission_id) {
      var url = $("#gradebook_urls .view_quiz_url").attr('href');
      url = $.replaceTags(url, "quiz_id", assignment.quiz_id);
      url = $.replaceTags(url, "user_id", submission.user_id);
      if(submission.workflow_state == "pending_review") {
        $type.append($("#submission_pending_review_image").clone().removeAttr('id'));
        $type.append(" <a href='" + url + "' target='_new'>" + I18n.t('links.finish_scoring', "Finish Scoring this Quiz") + "</a>");
      } else {
        $type.append($("#submission_quiz_image").clone().removeAttr('id'));
        $type.append(" <a href='" + url + "' target='_new'>" + I18n.t('links.view_quiz', "View this Quiz") + "</a>");
      }
    }

    $submission_information
      .find(".no_comments").hide().end()
      .find(".add_comment_link").hide().end()
      .find(".points_possible").text(points_possible || "").end()
      .find(".out_of").showIf(points_possible || points_possible === '0').end()
      .find(".grade_entry").empty().append($grade_entry.show()).end()
      .find("textarea.comment_text").show().val("").end()
      .find(".submission_details").empty().append($view).append($type).show().end()
      .find(".submission_comments").empty().end()
      .find(".comment_attachments").empty().end()
      .find(".save_buttons,.add_comment").showIf(!readOnlyGradebook).end()
      .find(".group_comment").showIf(assignment && assignment.group_category).find(":checkbox").attr('checked', false).end().end();

    if(readOnlyGradebook) {
      $submission_information.find(".grade_entry").text(grade || "-");
    }
    
    submission.student_id = submission.user_id;
    submission.id = submission.id || "";
    var late = submission.late;
    $submission_information.find(".submitted_at_box").showIf(submission.submitted_at).toggleClass('late_submission', !!late);
    submission.submitted_at_string = $.datetimeString(submission.submitted_at);
    $submission_information.fillTemplateData({
      data: submission,
      except: ['created_at', 'submission_comments', 'submission_comment', 'comment', 'attachments', 'attachment']
    });
    for(var idx in submission.submission_comments) {
      var comment = submission.submission_comments[idx].submission_comment;
      var $comment = $("#submission_comment_blank").clone(true).removeAttr('id');
      comment.posted_at = $.datetimeString(comment.created_at);
      $comment.fillTemplateData({
        data: comment,
        except: ['attachments']
      });
      if(comment.attachments) {
        for(var jdx in comment.attachments) {
          var attachment = comment.attachments[jdx].attachment;
          var $attachment = $('#submission_comment_attachment_blank').clone().removeAttr('id').show();
          attachment.assignment_id = submission.assignment_id;
          attachment.user_id = submission.user_id;
          attachment.comment_id = comment.id;
          $attachment.fillTemplateData({
            data: attachment,
            hrefValues: ['assignment_id', 'user_id', 'id', 'comment_id']
          });
          $comment.find(".attachments").append($attachment);
        }
      }
      $submission_information.find(".submission_comments").append($comment.show());
    }
    $submission_information.show().dialog({
      width: 500,
      height: "auto",
      title: title, 
      open: function() {
        $submission_information.find(".grading_value").focus().select();
        $("#gradebook").data('disable_highlight', true);
      }, close: function() {
        $("#gradebook").data('disable_highlight', false);
      }
    }).dialog('option', 'title', title);
  }

  function submissionInformation($submission) {
    var $td = $submission;
    var submission = objectData($td);
    if(submission && submission.submission_comments) {
      populateSubmissionInformation($submission, submission);
    } else {
      $("#loading_submission_details_dialog").dialog({
        title: I18n.t('titles.loading', "Loading...")
      });
      var url = $("#loading_submission_details_dialog .submission_details_url").attr('href');
      url = $.replaceTags($.replaceTags(url, 'user_id', submission.user_id), 'assignment_id', submission.assignment_id);
      // Pop up dialog with loading message
      $.ajaxJSON(url, "GET", {}, function(data) {
        $("#loading_submission_details_dialog").dialog('close');
        data.submission.submission_comments = data.submission.submission_comments || [];
        object_data["submission_" + submission.user_id + "_" + submission.assignment_id] = data;
        submission = objectData($td);
        populateSubmissionInformation($submission, submission);
      }, function(data) {
        // Failed to load message
      });
    }
  }

  var studentsToUpdate = [];
  gradebook.finalGradesReady = true;
  var studentsToInitialize = {};
  function secondaryInit() {
    gradebook.updateAllStudentGrades = function(initialize) {
      gradebook.finalGradesReady = false;
      if(initialize) {
        for(var idx in object_data) {
          if(object_data[idx].submission) {
            var submission = object_data[idx].submission;
            studentsToInitialize[submission.user_id] = studentsToInitialize[submission.user_id] || [];
            studentsToInitialize[submission.user_id].push(submission);
          }
        }
      }
      $(".outer_student_name").each(function() {
        var data = objectData($(this));
        studentsToUpdate.push(data.id);
      });
    };
    var grabStudentGrade = function() {
      if(studentsToUpdate.length > 0) {
        var id = studentsToUpdate.shift();
        if(studentsToInitialize[id]) {
          for(var idx in studentsToInitialize[id]) {
            updateSubmission(studentsToInitialize[id][idx]);
          }
          studentsToInitialize[id] = null;
        }
        updateStudentGrades(id);
      } else {
        gradebook.finalGradesReady = true;
      }
    };
    setInterval(grabStudentGrade, 100);
    gradebook.updateAllStudentGrades();
    $("html,body").scrollTop(0);
    $(".outer_assignment_name").each(function() {
      var $assignment = $(this);
      var data = objectData($assignment);
      var assignment = {
        title: data.title,
        id: data.assignment_id,
        date_sortable: data.due_at,
        group_id: data.assignment_group_id,
        special_sort: 'a'
      };
      assignment.id = assignment.id || $assignment.find(".student_header").attr('id').substring(17);
      if($assignment.hasClass('final_grade')) {
        assignment.special_sort = 'z';
        assignment.group_id = 'z';
      } else if($assignment.hasClass('group_total')) {
        var $groups = $("#groups_data .group");
        var idx = $groups.index($("#group_" + data.assignment_group_id));
        assignment.special_sort = 'y_' + idx;
      }
      $assignment.data('assignment_object', assignment);
    });
  }

  function moveAssignmentColumn(assignment_id, movement, relative_assignment_id) {
    if(movement == "first") {
      movement = "before";
      relative_assignment_id = objectData($(".outer_assignment_name:first")).id;
    } else if(movement == "last") {
      movement = "after";
      relative_assignment_id = objectData($(".outer_assignment_name:last")).id;
    }
    if(movement == "before") {
      var befores = $(".assignment_" + relative_assignment_id).parent();
      var drops = $(".assignment_" + assignment_id).parent();
      for(var i = 0; i < befores.length; i++) {
        $(befores[i]).before($(drops[i]));
      }
    } else if(movement == "after") {
      var afters = $(".assignment_" + relative_assignment_id).parent();
      var drops = $(".assignment_" + assignment_id).parent();
      for(var i = 0; i < afters.length; i++) {
        $(afters[i]).after($(drops[i]));
      }
    }
  }

  window.sortStudentRows = function(callback) {
    var $students = $(".outer_student_name");
    var students = [];
    $students.each(function() {
      var student = $(this).getTemplateData({textValues: ['display_name', 'secondary_identifier', 'course_section']});
      student.display_name = (student.display_name || 'zzzzzzz').toLowerCase();
      student.secondary_identifier = (student.secondary_identifier || 'zzzzzzz').toLowerCase();
      student.course_section = (student.course_section || 'zzzzzzz').toLowerCase();
      student.id = $(this).find(".assignment_header").attr('id').substring(14);
      student.grade = parseFloat($(".student_" + student.id + ".assignment_final-grade .grade").text()) || 0;
      students.push(student);
    });
    var sorts = [];
    for(var idx in students) {
      var s = students[idx];
      var list = callback(s);
      list.student = s;
      sorts.push(list);
    }
    sorts = sorts.sort(function(a, b) {
      for(var idx in a) {
        var a1 = a[idx], b1 = b[idx];
        if(a1 < b1)
          return -1;
        if(a1 > b1)
          return 1;
      }
      return 0;
    });
    students = [];
    for(var idx in sorts) {
      students.push(sorts[idx].student);
    }
    var new_order = [0];
    var titles = ["--"];
    $.each(students, function(i, student) {
      var $student = $("#student_" + student.id).parents(".cell");
      new_order.push(datagrid.position($student).row);
      titles.push($student.find(".display_name").text());
      return;
    });
    datagrid.reorderRows(new_order);
  };

  window.reverseRows = function() {
    var new_order = [0];
    for(var idx = datagrid.rows.length - 1; idx > 0; idx--) {
      new_order.push(idx);
    }
    datagrid.reorderRows(new_order);
  };

  window.sortAssignmentColumns = function(callback) {
    var $assignments = $(".outer_assignment_name");
    var assignments = [];
    var groupData = {};
    $("#groups_data .group").each(function(idx) {
      var id = $(this).find(".assignment_group_id").text();
      groupData[id] = idx;
    });
    $assignments.each(function() {
      var $assignment = $(this);
      var assignment = $assignment.data('assignment_object');
      assignment.groupData = groupData;
      assignments.push(assignment);
    });
    var sorts = [];
    for(var idx in assignments) {
      var a = assignments[idx];
      var list = callback(a);
      list.assignment = a;
      sorts.push(list);
    }
    sorts = sorts.sort();
    assignments = [];
    for(var idx in sorts) {
      assignments.push(sorts[idx].assignment);
    }
    var new_order = [0];
    var titles = ["--"];
    $.each(assignments, function(i, assignment) {
      var $assignment = $("#assignment_" + assignment.id).parents(".cell");
      new_order.push(datagrid.position($assignment).column);
      titles.push($assignment.find(".assignment_title").text());
      return;
    });
    datagrid.reorderColumns(new_order);
  }

  function updateGroupTotal(updateGrades) {
    var total = 0.0;
    var weighted = $("#class_weighting_policy").attr('checked');
    $("#groups_data").find(".group").each(function() {
      var weight = $(this).find(".group_weight").val();
      var val = parseFloat(weight);
      if(isNaN(val)) {
        val = 0;
      }
      if(updateGrades) {
        var group_id = $(this).getTemplateData({textValues: ['assignment_group_id']}).assignment_group_id;
        var pct = val + "%";
        var after = " of grade";
        if(!weighted) {
          pct = "";
          after = "";
        }
        $("#outer_assignment_group-" + group_id + ",#assignment_group-" + group_id)
          .find(".points_possible").text(pct).end()
          .find(".before_points_possible").text("").end()
          .find(".after_points_possible").text(after);
      }
      total += val;
    });
    $("#groups_data").find(".total_weight").text(round(total,2));
    if(updateGrades && gradebook.updateAllStudentGrades) {
      gradebook.updateAllStudentGrades();
    }
  }

  function updateStudentGrades(student_id) {
    var $submissions = $(".table_entry.student_" + student_id);
    var submissionObjects = _.chain($submissions).reject(function(s) {
      return $(s).find('.grade').hasClass('hard_coded'); // total columns
    }).map(function(s) {
      return objectData($(s).parent());
    }).value();


    var weightingScheme = $("#class_weighting_policy").attr('checked') ?
      "percent" :
      "equal";
    var groupSums = GradeCalculator.calculate(
        submissionObjects,
        ENV.assignment_groups,
        weightingScheme);

    var currentOrFinal = ignoreUngradedSubmissions ? 'current' : 'final';

    _.each(groupSums.group_sums, function(groupSum) {
      var sum = groupSum[currentOrFinal];
      var calculatedScore = sum.score / sum.possible;
      if(isNaN(calculatedScore) || !isFinite(calculatedScore)) {
        calculatedScore = 0.0;
      }
      calculatedScore = Math.round(calculatedScore * 1000.0) / 10.0;

      $("#submission_" + student_id + "_group-" + groupSum.group.id)
        .css('visibility', '')
        .attr('data-tip', 'pts: ' +  sum.score + ' / ' + sum.possible)
        .find(".grade").text(calculatedScore).end()
        .find(".score").hide().end()
        .find(".pct").text(' %').show();

      _.each(sum.submissions, function(s) {
        var $s = $("#submission_" + student_id + "_" + s.submission.assignment_id).parent();
        $s.toggleClass('dropped', !!s.drop);
      });
    });

    var finalGrade = groupSums[currentOrFinal].score / groupSums[currentOrFinal].possible;
    finalGrade = Math.round(finalGrade * 1000.0) / 10.0;
    if(isNaN(finalGrade) || !isFinite(finalGrade)) {
      finalGrade = 0;
    }

    var letterGrade = "";
    if(grading_scheme) {
      letterGrade = GradeCalculator.letter_grade(grading_scheme, finalGrade);
    }
    $("#submission_" + student_id + "_final-grade")
      .css('visibility', '')
      .attr('data-tip', gradebook.pointCalculations ? ('pts: ' + groupSums[currentOrFinal].score + ' / ' + groupSums[currentOrFinal].possible) : '')
      .find(".grade").text(finalGrade).end()
      .find(".score").hide().end()
      .find(".letter_grade").showIf(grading_scheme).text(letterGrade).end()
      .find(".pct").text(' %').show();
  }

  $(document).ready(function(){
    $(document).bind('update_student_grades', function(event, student_id) {
      updateStudentGrades(student_id);
    });
  });

  $.fn.gradebookLoading = function(action) {
    this.find(".refresh_grades_link").find(".static").showIf(action).end()
      .find(".animated").showIf(!action);
  };

  function updateGrades(refresh) {
    var url = window.location.protocol + "//" + 
              window.location.host + 
              window.location.pathname + 
              "?updated=" + lastGradebookUpdate;
    
    $("#datagrid_topleft").gradebookLoading();
    $.ajaxJSON(url, 'GET', {}, function(submissions) {
      if(refresh) {
        setTimeout(function() { updateGrades(true); }, 120000);
      }
      $("#datagrid_topleft").gradebookLoading('remove');
      var newGradebookUpdate = lastGradebookUpdate;
      for(idx in submissions) {
        var submission = submissions[idx].submission;
        submission.student_id = submission.user_id;
        if(submission.updated_at.substring(0, 19) > lastGradebookUpdate) {
          updateSubmission(submission);
          if(submission.updated_at > newGradebookUpdate) {
            newGradebookUpdate = submission.updated_at.substring(0, 19);
          }
        }
      }
      lastGradebookUpdate = newGradebookUpdate;
    }, function(data) {
      if(refresh) {
        setTimeout(function() { updateGrades(true); }, 240000);
      }
      $("#datagrid_topleft").gradebookLoading('remove');
    });
  }
});
