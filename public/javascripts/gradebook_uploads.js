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
  'jsx/gradebook/uploads/process_gradebook_upload',
  'vendor/slickgrid',
  'vendor/slickgrid/slick.editors',
  'jquery.instructure_forms' /* errorBox */,
  'jquery.instructure_misc_helpers' /* /\.detect/ */,
  'jquery.templateData' /* fillTemplateData */
], function(I18n, $, _, htmlEscape, processGradebookUpload, SlickGrid) {

  var uploadedGradebook = ENV.uploaded_gradebook;

  var GradebookUploader = {
    createGeneralFormatter: function (attribute) {
      return function (row, cell, value) {
        return value ? value[attribute] : "";
      }
    },

    init:function(){
      var gradebookGrid,
          $gradebook_grid = $("#gradebook_grid"),
          $gradebook_grid_header = $("#gradebook_grid_header"),
          rowsToHighlight = [],
          self = this;

      var gridData = {
        columns: [
          {
            id:"student",
            name:I18n.t('student', "Student"),
            field:"student",
            width:250,
            cssClass:"cell-title",
            formatter: self.createGeneralFormatter('name')
          }
        ],
        options: {
          enableAddRow: false,
          editable: true,
          enableColumnReorder: false,
          asyncEditorLoading: true,
          rowHeight: 30
        },
        data: []
      };

      var labelData = {
        columns: [{
          id: 'assignmentGrouping',
          name: '',
          field: 'assignmentGrouping',
          width: 250
        }],
        options: {
          enableAddRow: false,
          enableColumnReorder: false,
          asyncEditorLoading: false
        },
        data: []
      };

      delete uploadedGradebook.missing_objects;
      delete uploadedGradebook.original_submissions;

      $.each(uploadedGradebook.assignments, function(){
        var newGrade = {
          id: this.id,
          name: htmlEscape(I18n.t('To')),
          field: this.id,
          width: 125,
          editor: Slick.Editors.UploadGradeCellEditor,
          formatter: self.createGeneralFormatter('grade'),
          active: true,
          previous_id: this.previous_id,
          cssClass: "new-grade"
        };

        var conflictingGrade = {
          id: this.id + "_conflicting",
          width: 125,
          formatter: self.createGeneralFormatter('original_grade'),
          field: this.id + "_conflicting",
          name: htmlEscape(I18n.t('From')),
          cssClass: 'conflicting-grade'
        };

        var assignmentHeaderColumn = {
          id: this.id,
          width: 250,
          name: htmlEscape(this.title),
          headerCssClass: "assignment"
        };

        labelData.columns.push(assignmentHeaderColumn);
        gridData.columns.push(conflictingGrade);
        gridData.columns.push(newGrade);
      });

      $.each(uploadedGradebook.students, function(index){
        var row = {
          student   : this,
          id        : this.id
        };
        $.each(this.submissions, function(){
          var originalGrade = parseInt(this.original_grade);
              updatedGrade  = parseInt(this.grade),
              updateWillRemoveGrade = !isNaN(originalGrade) && isNaN(updatedGrade);

          if (originalGrade > updatedGrade || updateWillRemoveGrade) {
            rowsToHighlight.push({rowIndex: index, id: this.assignment_id});
          }

          row['assignmentId'] = this.assignment_id;
          row[this.assignment_id] = this;
          row[this.assignment_id + "_conflicting"] = this;
        });
        gridData.data.push(row);
        row.active = true;
      });

      // if there are still assignments with changes detected.
      if (gridData.columns.length > 1) {
        if (uploadedGradebook.unchanged_assignments) {
          $("#assignments_without_changes_alert").show();
        }
        var $gradebookGridForm = $("#gradebook_grid_form");
        $gradebookGridForm.submit(function(e){
          e.preventDefault();
          $gradebookGridForm.disableWhileLoading(
            processGradebookUpload(uploadedGradebook)
          );
        }).show();

        $(window).resize(function(){
          $gradebook_grid.height( $(window).height() - $gradebook_grid.offset().top - 150 );
          var width = ((gridData.columns.length - 1) * 125) + 250;
          $gradebook_grid.parent().width(width);
        }).triggerHandler("resize");

        gradebookGrid = new Slick.Grid($gradebook_grid, gridData.data, gridData.columns, gridData.options);
        new Slick.Grid($gradebook_grid_header, labelData.data, labelData.columns, labelData.options);
        gradebookGrid.onColumnHeaderClick = function(columnDef) { /*do nothing*/};

        var gradeReviewRow = {};

        for(var i = 0; i < rowsToHighlight.length; i++) {
          var id = rowsToHighlight[i].id,
              rowIndex = rowsToHighlight[i].rowIndex,
              rowIndex= rowsToHighlight[i].rowIndex,
              conflictingId = id + "_conflicting";

          gradeReviewRow[rowIndex] = gradeReviewRow[rowIndex] || {};
          gradeReviewRow[rowIndex][id] = 'right-highlight';
          gradeReviewRow[rowIndex][conflictingId] = 'left-highlight';
          gradebookGrid.invalidateRow(rowIndex);
        }

        gradebookGrid.setCellCssStyles("highlight-grade-change", gradeReviewRow);
        gradebookGrid.render();
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
