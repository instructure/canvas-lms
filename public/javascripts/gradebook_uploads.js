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
var GradebookUploader;

I18n.scoped('gradebook', function(I18n) {

  GradebookUploader = {
    init:function(){
      var gradebookGrid,
          mergedGradebook = $.extend(true, {}, originalGradebook),
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

      $.each(mergedGradebook.assignments, function(){
        gridData.columns.push({
          id: this.id,
          name: $.htmlEscape(this.title),
          field: this.id,
          width:200,
          editor: NullGradeEditor,
          formatter: simpleGradeCellFormatter,
          _original: this
        });
      });

      $.each(mergedGradebook.students, function(){
        var row = {
          "student"   : this,
          "id"        : this.id,
          "_original" : this
        };
        $.each(this.submissions, function(){
          row[this.assignment_id] = this;
          row[this.assignment_id]._original = $.extend({}, this);
        });
        gridData.data.push(row);
      });

      $.each(uploadedGradebook.assignments, function(){
        var col,
            assignment = this;
        if (this.original_id) {
          col = _.detect(gridData.columns, function(column){
            return (column._original && column._original.id == assignment.original_id);
          });
          col.cssClass = "active changed";
        }
        else {
          col = {
            id: assignment.id,
            name: $.htmlEscape(assignment.title),
            field: assignment.id,
            formatter: simpleGradeCellFormatter,
            cssClass: "active new"
          };
          gridData.columns.push(col);
        }
        col.editor = GradeCellEditor;
        col.active = true;
        col._uploaded = assignment;
        col.setValueHandler = function(value, assignment, student){
          if (student[assignment.id]) {
            student[assignment.id].grade = student[assignment.id]._uploaded.grade =  value;
            //there was already an uploaded submission for this assignment, update it
          }
          else {
            //they did not upload a score for this assignment.  create a submission and link it.
            var submission = {
              grade: value,
              assignment_id: assignment.id
            };
            submission._uploaded = submission;
            var arrayLength = student._uploaded.submissions.push(submission);
            student[assignment.id] = student._uploaded.submissions[arrayLength - 1];
          }
        };

      });

      $.each(uploadedGradebook.students, function(){
        var row,
            student = this;
        if (student.original_id) {
          row = _.detect(gridData.data, function(row){
            return (row._original && row._original.id == student.original_id);
          });
        }
        else {
          row = {
            id: student.id,
            student: student
          };
          gridData.data.push(row);
        }
        $.each(student.submissions, function(){
          // when we get to here, if the student didnt have a submission for this assignment in the originalGradebook, it wont have anything in row[this.assignment_id]
          // so we check if row[this.assignment_id] is there, and if it is, extend it with this submission (so it gets a new grade).
          row[this.assignment_id] = row[this.assignment_id] ? $.extend(row[this.assignment_id], this) : this;
          if(!row[this.assignment_id]._original && this.grade) {
            row[this.assignment_id]._original = {score: null};
          }
          row[this.assignment_id]._uploaded = this;
        });
        row.active = true;
        row._uploaded = student;
      });
      // only show the columns where there were submissions that have grades that have changed.
      var oldGridDataLength = gridData.columns.length;
      gridData.columns = _.select(gridData.columns, function(col){
        return col.id === "student" || _.detect(gridData.data, function(row){
          return row[col.id] &&
                 row[col.id]._original &&
                 row[col.id]._uploaded &&
                 row[col.id]._original.score != row[col.id]._uploaded.grade;
        });
      });

      // if there are still assignments with changes detected.
      if (gridData.columns.length > 1) {
        if (gridData.columns.length < oldGridDataLength) {
          $("#assignments_without_changes_alert").show();
        }
        $("#gradebook_grid_form").submit(function(e){
          //we use this function to get rid of the infinate nesting like
          //uploadedGradebook.students[0]._original._original._original etc...
          //so that when we convert it to json we dont get an infinate loop.
          var flattenRecursiveObjects = function(i,o){
            $.each(["_original", "_uploaded"], function(i, j){
              if(o[j]){
                var flattened = $.extend({}, o[j]);
                delete o[j];
                delete flattened[j];
                o[j] = flattened;
              }
            });
          };
          $.each(uploadedGradebook.students, function(){
            $.each(this.submissions, flattenRecursiveObjects);
          });
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

      // do this because I had to use the active_assignments has many relationship because we dont want to see deleted assignments.
      // but everthing else here expects there to be an originalGradebook.assignments array.
      originalGradebook.assignments = originalGradebook.active_assignments;

      // first, figure out if there is anything that needs to be resolved
      $.each(["student", "assignment"], function(i, thing){
        var $template = $("#" + thing + "_resolution_template").remove(),
            $select   = $template.find("select");

        needingReview[thing] = [];

        $.each(uploadedGradebook[thing+"s"], function(){
          if (!this.original_id) {
            needingReview[thing].push(this);
          }
        });

        if (needingReview[thing].length) {
          $select.change(function(){
            $(this).next(".points_possible_section").css({opacity: 0});
            if($(this).val() > 0) {  //if the thing that was selected is an id( not ignore or add )
              $("#" + thing + "_resolution_template select option").removeAttr("disabled");
              $("#" + thing + "_resolution_template select").each(function(){
                $("#" + thing + "_resolution_template select").not(this).find("option[value='" + $(this).val() + "']").attr("disabled", true);
              });
            }
            else if ( $(this).val() === "new" ) {
              $(this).next(".points_possible_section").css({opacity: 1});
            }
          });

          possibilitiesToMergeWith[thing] = _.reject(originalGradebook[thing+"s"], function(thng){
            return _.detect(uploadedGradebook[thing+"s"], function(newThng){
              return newThng.original_id == thng.id;
            });
          });

          $.each(possibilitiesToMergeWith[thing], function() {
            $('<option value="' + this.id + '" >' + $.htmlEscape(this.name || this.title) + '</option>').appendTo($select);
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
              _.detect(uploadedGradebook[thing+"s"], function(thng){
                return id == thng.id;
              }).original_id = val;
            }
          });

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

})
