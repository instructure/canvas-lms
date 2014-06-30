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
  'i18n!gradebook',
  'jquery',
  'underscore',
  'str/htmlEscape',
  'vendor/slickgrid-googlecode/slick.grid',
  'vendor/slickgrid-googlecode/slick.editors',
  'jquery.instructure_forms' /* errorBox */,
  'jquery.instructure_misc_helpers' /* /\.detect/ */,
  'jquery.templateData' /* fillTemplateData */
], function(I18n, $, _, htmlEscape, SlickGrid) {

  var GradebookUploader = {
    init:function(){
      var gradebookGrid,
          $gradebook_grid = $("#gradebook_grid"),
          gridData = {
            columns: [
              {
                id:"student",
                name:I18n.t('student', "Student"),
                field:"student",
                width:250,
                cssClass:"cell-title",
                editor:StudentNameEditor,
                validator:requiredFieldValidator,
                formatter: StudentNameFormatter
              }
            ],
            options: {
              enableAddRow: false,
              enableColumnReorder: false,
              asyncEditorLoading: true
            },
            data: []
          };
      delete uploadedGradebook.missing_objects;
      delete uploadedGradebook.original_submissions;

      $.each(uploadedGradebook.assignments, function(){
        var col = {
          id: this.id,
          name: htmlEscape(this.title),
          field: this.id,
          width:200,
          editor: GradeCellEditor,
          formatter: simpleGradeCellFormatter,
          active: true,
          previous_id: this.previous_id
        };
        gridData.columns.push(col);
        if (this.previous_id) {
          col.cssClass = "active changed"
        } else {
          col.cssClass = "active new"
        }
        col.setValueHandler = function(value, assignment, student){
          if (student[assignment.id]) {
            student[assignment.id].grade = value;
            //there was already an uploaded submission for this assignment, update it
          } else {
            //they did not upload a score for this assignment. create a submission and link it.
            var submission = {
              grade: value,
              assignment_id: assignment.id
            };
            var arrayLength = student.submissions.push(submission);
            student[assignment.id] = student.submissions[arrayLength - 1];
          }
        };
      });

      $.each(uploadedGradebook.students, function(){
        var row = {
          student   : this,
          id        : this.id
        };
        $.each(this.submissions, function(){
          row[this.assignment_id] = this;
        });
        gridData.data.push(row);
        row.active = true;
      });

      // if there are still assignments with changes detected.
      if (gridData.columns.length > 1) {
        if (uploadedGradebook.unchanged_assignments) {
          $("#assignments_without_changes_alert").show();
        }
        $("#gradebook_grid_form").submit(function(e){
          $(this).find("input[name='json_data_to_submit']").val(JSON.stringify(uploadedGradebook));
        }).show();

        $(window).resize(function(){
          $gradebook_grid.height( $(window).height() - $gradebook_grid.offset().top - 50 );
        }).triggerHandler("resize");
        gradebookGrid = new SlickGrid($gradebook_grid, gridData.data, gridData.columns, gridData.options);
        gradebookGrid.onColumnHeaderClick = function(columnDef) { /*do nothing*/};
      }
      else {
        $("#no_changes_detected").show();
      }
    },

    handleThingsNeedingToBeResolved: function(){
      var needingReview = {},
          possibilitiesToMergeWith = {};

      // first, figure out if there is anything that needs to be resolved
      $.each(["student", "assignment"], function(i, thing){
        var $template = $("#" + thing + "_resolution_template").remove(),
            $select   = $template.find("select");

        needingReview[thing] = [];

        $.each(uploadedGradebook[thing+"s"], function(){
          if (!this.previous_id) {
            needingReview[thing].push(this);
          }
        });

        if (needingReview[thing].length) {
          $select.change(function(){
            $(this).next(".points_possible_section").css({opacity: 0});
            if($(this).val() > 0) {  //if the thing that was selected is an id( not ignore or add )
              $("#" + thing + "_resolution_template select option").removeAttr("disabled");
              $("#" + thing + "_resolution_template select").each(function(){
                 if($(this).val() != "ignore" ) {
                 	$("#" + thing + "_resolution_template select").not(this).find("option[value='" + $(this).val() + "']").attr("disabled", true);
                 }
              });
            }
            else if ( $(this).val() === "new" ) {
              $(this).next(".points_possible_section").css({opacity: 1});
            }
          });

          $.each(uploadedGradebook.missing_objects[thing + 's'], function() {
            $('<option value="' + this.id + '" >' + htmlEscape(this.name || this.title) + '</option>').appendTo($select);
          });

          $.each(needingReview[thing], function(i, record){
            $template
              .clone(true)
              .fillTemplateData({
                iterator: record.id,
                data: {
                  name: record.name,
                  title: record.title,
                  points_possible: record.points_possible
                }
              })
              .appendTo("#gradebook_importer_resolution_section ." + thing + "_section table tbody")
              .show()
              .find("input.points_possible")
              .change(function(){
                record.points_possible = $(this).val();
              });
          });
          $("#gradebook_importer_resolution_section, #gradebook_importer_resolution_section ." + thing + "_section").show();
        }

      });
  // end figuring out if thigs need to be resolved

      if ( needingReview.student.length || needingReview.assignment.length ) {
        // if there are things that need to be resolved, set up stuff for that form
        $("#gradebook_importer_resolution_section").submit(function(e){
          var returnFalse = false;
          e.preventDefault();

          $(this).find("select").each(function(){
            if( !$(this).val() ) {
              returnFalse = true;
              $(this).errorBox(I18n.t('errors.select_an_option', "Please select an option"));
              return false;
            }
          });
          if(returnFalse) return false;

          $(this).find("select").each(function(){
            var $select = $(this),
                parts = $select.attr("name").split("_"),
                thing = parts[0],
                id = parts[1],
                val = $select.val();

            switch(val){
            case "new":
              //do nothing
              break;
            case "ignore":
              //remove the entry from the uploaded gradebook
              for (var i in uploadedGradebook[thing+"s"]) {
                if (id == uploadedGradebook[thing+"s"][i].id) {
                  uploadedGradebook[thing+"s"].splice(i, 1);
                  break;
                }
              }
              break;
            default:
              //merge
              var obj = _.detect(uploadedGradebook[thing+"s"], function(thng){
                return id == thng.id;
              });
              obj.id = obj.previous_id = val;
              if (thing === 'assignment') {
                // find the original grade for this assignment for each student
                $.each(uploadedGradebook['students'], function() {
                  var student = this;
                  var submission = _.detect(student.submissions, function(thng) {
                    return thng.assignment_id == id;
                  });
                  submission.assignment_id = val;
                  var original_submission = _.detect(uploadedGradebook.original_submissions, function(sub) {
                    return sub.user_id == student.id && sub.assignment_id == val;
                  });
                  if (original_submission) {
                    submission.original_grade = original_submission.score;
                  }
                });
              } else if (thing === 'student') {
                // find the original grade for each assignment for this student
                $.each(obj.submissions, function() {
                  var submission = this;
                  var original_submission = _.detect(uploadedGradebook.original_submissions, function(sub) {
                    return sub.user_id == obj.id && sub.assignment_id == submission.assignment_id;
                  });
                  if (original_submission) {
                    submission.original_grade = original_submission.score;
                  }
                });
              }
            }
          });

          // remove assignments that have no changes
          var indexes_to_delete = [];
          $.each(uploadedGradebook.assignments, function(index){
            if(uploadedGradebook.assignments[index].previous_id && _.all(uploadedGradebook.students, function(student){
              var submission = student.submissions[index];
              return submission.original_grade == submission.grade || (!submission.original_grade && !submission.grade);
            })) {
              indexes_to_delete.push(index);
            }
          });
          _.each(indexes_to_delete.reverse(), function(index) {
            uploadedGradebook.assignments.splice(index, 1);
            $.each(uploadedGradebook.students, function() {
              this.submissions.splice(index, 1);
            });
          });
          if (indexes_to_delete.length != 0) {
            uploadedGradebook.unchanged_assignments = true;
          }

          $(this).hide();
          GradebookUploader.init();

        });
      }
      else {
        // if there is nothing that needs to resolved, just skip to initialize slick grid.
        GradebookUploader.init();
      }
    }
  };
  return GradebookUploader;
});
