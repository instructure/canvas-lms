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
  'i18n!attendance',
  'jquery' /* $ */,
  'datagrid',
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.dropdownList' /* dropdownList */,
  'jquery.instructure_date_and_time' /* time_field, datetime_field */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* fragmentChange */,
  'jquery.keycodes' /* keycodes */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/position' /* /\.position\(/ */
], function(I18n, $, datagrid, htmlEscape) {

  var attendance = {
    saveKeyIndex: 0,
    toggleState: function(cell, forceState, skipSave) {
      if(cell.hasClass('false_submission')) { return; }
      var vals = cell.attr('id').split("_");
      var user_id = vals[1];
      var assignment_id = vals[2];
      cell.addClass('saving');
      var grade = "";
      if(forceState) {
        if(forceState == 'fail') {
          cell.removeClass('pass').addClass('fail');
          grade = "fail";
        } else if(forceState == 'pass') {
          cell.removeClass('fail').addClass('pass');
          grade = "pass";
        } else {
          cell.removeClass('fail').removeClass('pass');
          grade = "";
        }
      } else {
        if(cell.hasClass('pass')) {
          cell.removeClass('pass').addClass('fail');
          grade = "fail";
        } else if(cell.hasClass('fail')) {
          cell.removeClass('fail').removeClass('pass');
          grade = "";
        } else {
          cell.removeClass('fail').addClass('pass');
          grade = "pass";
        }
      }
      var key = attendance.saveKeyIndex++
      if(!skipSave) {
        setTimeout(function() {
          if(cell.data('save_key') == key) {
            var url = $.replaceTags($.replaceTags($(".grade_submission_url").attr('href'), "user_id", user_id), "assignment_id", assignment_id);
            var data = {
              'submission[assignment_id]': assignment_id,
              'submission[user_id]': user_id,
              'submission[grade]': grade
            };
            $.ajaxJSON(url, "POST", data, function(data) {
              cell.removeClass('saving');
              for(var idx in data) {
                var submission = data[idx].submission;
                var $cell = $("#submission_" + submission.user_id + "_" + submission.assignment_id);
                var key = attendance.toggleState($cell, submission.grade || "clear", true);
                attendance.clearSavingState($cell, key);
              }
            }, function(data) {
              cell.removeClass('saving');
            });
          }
        }, 1000);
      }
      cell.data('save_key', key);
      return key;
    },
    clearSavingState: function($cell, key) {
      if($cell.data('save_key') == key) {
        $cell.removeClass('saving');
        $cell.data('save_key', null);
      }
    },
    toggleColumnState: function(column, forceState) {
      var assignment_id = datagrid.cells[0 + ',' + column].attr('id').split("_")[1];
      var keys = {};
      for(var idx = 1; idx < datagrid.rows.length; idx++) {
        var key = attendance.toggleState(datagrid.cells[idx + ',' + column], forceState, true);
        keys[idx] = key;
      }
      var clearSaving = function() {
        for(var idx = 1; idx < datagrid.rows.length; idx++) {
          var key = keys[idx];
          attendance.clearSavingState(datagrid.cells[idx + ',' + column], keys[idx]);
        }
      };
      var url = $.replaceTags($(".set_default_grade_url").attr('href'), "assignment_id", assignment_id);
      var grade = forceState;
      if(grade != "pass" && grade != "fail") { grade = ""; }
      var data = {
        'assignment[default_grade]': grade,
        'assignment[overwrite_existing_grades]': '1'
      };
      $.ajaxJSON(url, "PUT", data, function(data) {
        clearSaving();
      }, function(data) {
        clearSaving();
      });
    }
  };
  $(document).ready(function() {
    var errorCount = 0;
    $(".datetime_field").datetime_field();
    $(".help_link").click(function(event) {
      event.preventDefault();
      $("#attendance_how_to_dialog").dialog({
        width: 400,
        title: I18n.t('titles.attendance_help', "Attendance Help")
      });
    });
    $(".submission").addClass('loading');
    var getClump = function(url, assignment_ids, user_ids) {
      $.ajaxJSON(url, "GET", {}, function(data) {
        for(var idx in assignment_ids) {
          for(var jdx in user_ids) {
            $("#submission_" + user_ids[jdx] + "_" + assignment_ids[idx]).removeClass('loading');
          }
        }
        for(var idx in data) {
          if(data[idx] && data[idx].submission) {
            var grade = data[idx].submission.grade;
            var $submission = $("#submission_" + data[idx].submission.user_id + "_" + data[idx].submission.assignment_id);
            $submission.removeClass('loading');
            if(grade != "pass" && grade != "fail") { grade = "clear"; }
            var key = attendance.toggleState($submission, grade, true);
            attendance.clearSavingState($submission, key);
          }
        }
      }, function() {
        if(errorCount < 5) {
          errorCount++;
          getClump(url);
        }
      });
    };
    var clump_size = Math.round(200 / ($("#attendance .student").length || 1));
    var clump = [];
    var pre = $(".gradebook_url").attr('href');
    setTimeout(function() {
      var assignment_ids = [];
      $("#attendance .assignment").each(function() {
        var id = ($(this).attr('id') || "").split("_").pop(); //.substring(11);
        assignment_ids.push(id);
      });
      $("#attendance .student").each(function() {
        var id = ($(this).attr('id') || "").split("_").pop(); //.substring(8);
        if(id) {
          clump.push(id);
        }
        if(clump.length > clump_size) {
          getClump(pre + "?init=1&submissions=1&user_ids=" + clump.join(",") + "&assignment_ids=" + assignment_ids.join(","), assignment_ids, clump);
          clump = [];
        }
      });
      if(clump.length > 0) {
        getClump(pre + "?init=1&submissions=1&user_ids=" + clump.join(",") + "&assignment_ids=" + assignment_ids.join(","), assignment_ids, clump);
      }
    }, 500);
    $("#comment_link").click(function(event) {
      event.preventDefault();
      event.stopPropagation();
    });
    $(".options_dropdown").click(function(event) {
      event.preventDefault();
    });
    $("#attendance").bind('entry_over', function(event, grid) {
      var keys = grid.cell.attr('id').split("_");
      var user_id = keys[1];
      var assignment_id = keys[2];
    }).bind('entry_out', function(event, grid) {
    }).bind('entry_click', function(event, grid) {
      grid.trueEvent.preventDefault();
      datagrid.focus(grid.cell.row, grid.cell.column);
    }).bind('entry_focus', function(event, grid) {
      if(grid.cell.row == 0) {
        var options = {};
        options['<span class="ui-icon ui-icon-pencil">&nbsp;</span> ' + htmlEscape(I18n.t('options.edit_assignment', 'Edit Assignment'))] = function() {
          location.href = "/";
        };
        options['<span class="ui-icon ui-icon-check">&nbsp;</span> ' + htmlEscape(I18n.t('options.mark_all_as_present', 'Mark Everyone Present'))] = function() {
          attendance.toggleColumnState(grid.cell.column, 'pass');
        };
        options['<span class="ui-icon ui-icon-close">&nbsp;</span> ' + htmlEscape(I18n.t('options.mark_all_as_absent', 'Mark Everyone Absent'))] = function() {
          attendance.toggleColumnState(grid.cell.column, 'fail');
        };
        options['<span class="ui-icon ui-icon-minus">&nbsp;</span> ' + htmlEscape(I18n.t('options.clear_attendance_marks', 'Clear Attendance Marks'))] = function() {
          attendance.toggleColumnState(grid.cell.column, 'clear');
        }
        grid.cell.find(".options_dropdown").dropdownList({options: options});
      } else {
        attendance.toggleState(grid.cell);
      }
      datagrid.blur();
    }).bind('entry_blur', function(event, grid) {
    });
    $(document).keycodes('return p f del', function(event) {
      if(datagrid.currentFocus || !datagrid.currentHover) {
        return;
      }
      if($(event.target).closest(".ui-dialog").length > 0) { return; }
      var $current = datagrid.currentHover;

      if(event.keyString == "return") {
        if($current.hasClass('submission')) {
          datagrid.focus($current.row, $current.column);
        }
      } else if(event.keyString == "p") {
      } else if(event.keyString == "f") {
      } else if(event.keyString == "del") {
      }

    });
    datagrid.init($("#attendance"), {
      borderSize: 2,
      onViewable: function() {
        $("#attendance_loading_message").hide();
        $(document).fragmentChange(function(event, hash) {
          if(hash.length > 1) {
            hash = hash.substring(1);
          }
          hash = hash.replace(/\/|%2F/g, "_");
          if(hash.indexOf("student") == 0 || hash.indexOf("assignment") == 0 || hash.indexOf("submission") == 0) {
            var $div = $("#" + hash),
                position = datagrid.position($div),
                row = position.row,
                col = position.column;
            datagrid.scrollTo(row, col);
            $div.trigger('mouseover');
          }
        });
      },
      onReady: function() {
      }
    });
  });
});
