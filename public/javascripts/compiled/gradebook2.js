(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  I18n.scoped('gradebook2', function(I18n) {
    var Gradebook;
    return this.Gradebook = Gradebook = (function() {
      function Gradebook(options) {
        this.options = options;
        this.showCommentDialog = __bind(this.showCommentDialog, this);
        this.unhighlightColumns = __bind(this.unhighlightColumns, this);
        this.highlightColumn = __bind(this.highlightColumn, this);
        this.calculateStudentGrade = __bind(this.calculateStudentGrade, this);
        this.groupTotalFormatter = __bind(this.groupTotalFormatter, this);
        this.staticCellFormatter = __bind(this.staticCellFormatter, this);
        this.cellFormatter = __bind(this.cellFormatter, this);
        this.gotSubmissionsChunk = __bind(this.gotSubmissionsChunk, this);
        this.gotStudents = __bind(this.gotStudents, this);
        this.gotAssignmentGroups = __bind(this.gotAssignmentGroups, this);
        this.chunk_start = 0;
        this.students = {};
        this.rows = [];
        this.filterFn = function(student) {
          return true;
        };
        this.sortFn = function(student) {
          return student.display_name;
        };
        this.init();
        this.includeUngradedAssignments = false;
      }
      Gradebook.prototype.init = function() {
        if (this.options.assignment_groups) {
          return this.gotAssignmentGroups(this.options.assignment_groups);
        }
        return $.ajaxJSON(this.options.assignment_groups_url, "GET", {}, this.gotAssignmentGroups);
      };
      Gradebook.prototype.gotAssignmentGroups = function(assignment_groups) {
        var assignment, group, _i, _j, _len, _len2, _ref;
        this.assignment_groups = {};
        this.assignments = {};
        for (_i = 0, _len = assignment_groups.length; _i < _len; _i++) {
          group = assignment_groups[_i];
          $.htmlEscapeValues(group);
          this.assignment_groups[group.id] = group;
          _ref = group.assignments;
          for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
            assignment = _ref[_j];
            $.htmlEscapeValues(assignment);
            if (assignment.due_at) {
              assignment.due_at = $.parseFromISO(assignment.due_at);
            }
            this.assignments[assignment.id] = assignment;
          }
        }
        if (this.options.sections) {
          return this.gotStudents(this.options.sections);
        }
        return $.ajaxJSON(this.options.sections_and_students_url, "GET", {}, this.gotStudents);
      };
      Gradebook.prototype.gotStudents = function(sections) {
        var assignment, id, section, student, _i, _j, _len, _len2, _name, _ref, _ref2, _ref3;
        this.sections = {};
        this.rows = [];
        for (_i = 0, _len = sections.length; _i < _len; _i++) {
          section = sections[_i];
          $.htmlEscapeValues(section);
          this.sections[section.id] = section;
          _ref = section.students;
          for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
            student = _ref[_j];
            $.htmlEscapeValues(student);
            student.computed_current_score || (student.computed_current_score = 0);
            student.computed_final_score || (student.computed_final_score = 0);
            student.secondary_identifier = student.sis_login_id || student.login_id;
            this.students[student.id] = student;
            student.section = section;
            _ref2 = this.assignments;
            for (id in _ref2) {
              assignment = _ref2[id];
              student[_name = "assignment_" + id] || (student[_name] = {
                assignment_id: id,
                user_id: student.id
              });
            }
            this.rows.push(student);
          }
        }
        this.sections_enabled = sections.length > 1;
        _ref3 = this.students;
        for (id in _ref3) {
          student = _ref3[id];
          student.display_name = "<div class='student-name'>" + student.name + "</div>";
          if (this.sections_enabled) {
            student.display_name += "<div class='student-section'>" + student.section.name + "</div>";
          }
        }
        this.initGrid();
        this.buildRows();
        return this.getSubmissionsChunk();
      };
      Gradebook.prototype.buildRows = function() {
        var i, id, sortables, student, _len, _ref, _ref2;
        this.rows.length = 0;
        sortables = {};
        _ref = this.students;
        for (id in _ref) {
          student = _ref[id];
          student.row = -1;
          if (this.filterFn(student)) {
            this.rows.push(student);
            sortables[student.id] = this.sortFn(student);
          }
        }
        this.rows.sort(function(a, b) {
          if (sortables[a.id] < sortables[b.id]) {
            return -1;
          } else if (sortables[a.id] > sortables[b.id]) {
            return 1;
          } else {
            return 0;
          }
        });
        _ref2 = this.rows;
        for (i = 0, _len = _ref2.length; i < _len; i++) {
          student = _ref2[i];
          student.row = i;
        }
        this.multiGrid.removeAllRows();
        this.multiGrid.updateRowCount();
        return this.multiGrid.render();
      };
      Gradebook.prototype.sortBy = function(sort) {
        this.sortFn = (function() {
          switch (sort) {
            case "display_name":
              return function(student) {
                return student.display_name;
              };
            case "section":
              return function(student) {
                return student.section.name;
              };
            case "grade_desc":
              return function(student) {
                return -student.computed_current_score;
              };
            case "grade_asc":
              return function(student) {
                return student.computed_current_score;
              };
          }
        })();
        return this.buildRows();
      };
      Gradebook.prototype.getSubmissionsChunk = function(student_id) {
        var assignment, id, params, student, students;
        if (this.options.submissions) {
          return this.gotSubmissionsChunk(this.options.submissions);
        }
        students = this.rows.slice(this.chunk_start, this.chunk_start + this.options.chunk_size);
        params = {
          student_ids: (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = students.length; _i < _len; _i++) {
              student = students[_i];
              _results.push(student.id);
            }
            return _results;
          })(),
          assignment_ids: (function() {
            var _ref, _results;
            _ref = this.assignments;
            _results = [];
            for (id in _ref) {
              assignment = _ref[id];
              _results.push(id);
            }
            return _results;
          }).call(this),
          response_fields: ['user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission']
        };
        if (students.length > 0) {
          return $.ajaxJSON(this.options.submissions_url, "GET", params, this.gotSubmissionsChunk);
        }
      };
      Gradebook.prototype.gotSubmissionsChunk = function(student_submissions) {
        var data, student, submission, _i, _j, _len, _len2, _ref;
        for (_i = 0, _len = student_submissions.length; _i < _len; _i++) {
          data = student_submissions[_i];
          student = this.students[data.user_id];
          student.submissionsAsArray = [];
          _ref = data.submissions;
          for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
            submission = _ref[_j];
            if (submission.submitted_at) {
              submission.submitted_at = $.parseFromISO(submission.submitted_at);
            }
            student["assignment_" + submission.assignment_id] = submission;
            student.submissionsAsArray.push(submission);
          }
          student.loaded = true;
          this.multiGrid.removeRow(student.row);
          this.calculateStudentGrade(student);
        }
        this.multiGrid.render();
        this.chunk_start += this.options.chunk_size;
        return this.getSubmissionsChunk();
      };
      Gradebook.prototype.cellFormatter = function(row, col, submission) {
        var assignment;
        if (!this.rows[row].loaded) {
          return this.staticCellFormatter(row, col, '');
        } else if (!(submission != null ? submission.grade : void 0)) {
          return this.staticCellFormatter(row, col, '-');
        } else {
          assignment = this.assignments[submission.assignment_id];
          if (!(assignment != null)) {
            return this.staticCellFormatter(row, col, '');
          } else {
            if (assignment.grading_type === 'points' && assignment.points_possible) {
              return SubmissionCell.out_of.formatter(row, col, submission, assignment);
            } else {
              return (SubmissionCell[assignment.grading_type] || SubmissionCell).formatter(row, col, submission, assignment);
            }
          }
        }
      };
      Gradebook.prototype.staticCellFormatter = function(row, col, val) {
        return "<div class='cell-content gradebook-cell'>" + val + "</div>";
      };
      Gradebook.prototype.groupTotalFormatter = function(row, col, val, columnDef, student) {
        var gradeToShow, percentage, res;
        if (val == null) {
          return '';
        }
        gradeToShow = val[this.includeUngradedAssignments ? 'final' : 'current'];
        percentage = (gradeToShow.score / gradeToShow.possible) * 100;
        percentage = Math.round(percentage * 10) / 10;
        if (isNaN(percentage)) {
          percentage = 0;
        }
        if (!gradeToShow.possible) {
          percentage = '-';
        } else {
          percentage += "%";
        }
        res = "<div class=\"gradebook-cell\">\n  " + (columnDef.field === 'total_grade' ? '' : '<div class="gradebook-tooltip">' + gradeToShow.score + ' / ' + gradeToShow.possible + '</div>') + "\n  " + percentage + "\n</div>";
        return res;
      };
      Gradebook.prototype.calculateStudentGrade = function(student) {
        var group, result, _i, _len, _ref;
        if (student.loaded) {
          result = INST.GradeCalculator.calculate(student.submissionsAsArray, this.assignment_groups, 'percent');
          _ref = result.group_sums;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            group = _ref[_i];
            student["assignment_group_" + group.group.id] = {
              current: group.current,
              'final': group['final']
            };
          }
          return student["total_grade"] = {
            current: result.current,
            'final': result['final']
          };
        }
      };
      Gradebook.prototype.highlightColumn = function(columnIndexOrEvent) {
        var match;
        if (isNaN(columnIndexOrEvent)) {
          match = columnIndexOrEvent.currentTarget.className.match(/c\d+/);
          if (match) {
            columnIndexOrEvent = match.toString().replace('c', '');
          }
        }
        return this.$grid.find('.slick-header-column:eq(' + columnIndexOrEvent + ')').addClass('hovered-column');
      };
      Gradebook.prototype.unhighlightColumns = function() {
        return this.$grid.find('.hovered-column').removeClass('hovered-column');
      };
      Gradebook.prototype.showCommentDialog = function() {
        $('<div>TODO: show comments and stuff</div>').dialog();
        return false;
      };
      Gradebook.prototype.onGridInit = function() {
        var tooltipTexts;
        tooltipTexts = {};
        this.$grid = $('#gradebook_grid').fillWindowWithMe({
          alsoResize: '#gradebook_students_grid',
          onResize: __bind(function() {
            return this.multiGrid.resizeCanvas();
          }, this)
        }).delegate('.slick-cell', 'mouseenter.gradebook focusin.gradebook', this.highlightColumn).delegate('.slick-cell', 'mouseleave.gradebook focusout.gradebook', this.unhighlightColumns).delegate('.gradebook-cell', 'hover.gradebook', function() {
          return $(this).toggleClass('hover');
        }).delegate('.gradebook-cell-comment', 'click.gradebook', this.showCommentDialog);
        $('#grid-options').click(function(event) {
          event.preventDefault();
          return $('#sort_rows_dialog').dialog('close').dialog({
            width: 400,
            height: 300
          });
        });
        if (!this.sections_enabled) {
          $('#sort_rows_dialog .by_section').hide();
        }
        return $('#sort_rows_dialog button.sort_rows').click(function() {
          gradebook.sortBy($(this).data('sort_by'));
          return $('#sort_rows_dialog').dialog('close');
        });
      };
      Gradebook.prototype.initGrid = function() {
        var $widthTester, assignment, grids, group, html, id, minWidth, options, outOfFormatter, testWidth, _ref, _ref2;
        $widthTester = $('<span style="padding:10px" />').appendTo('#content');
        testWidth = function(text, minWidth) {
          return Math.max($widthTester.text(text).outerWidth(), minWidth);
        };
        this.columns = [
          {
            id: 'student',
            name: "<a href='javascript:void(0)' id='grid-options'>Options</a>",
            field: 'display_name',
            width: 150,
            cssClass: "meta-cell"
          }, {
            id: 'secondary_identifier',
            name: 'secondary ID',
            field: 'secondary_identifier',
            width: 100,
            cssClass: "meta-cell secondary_identifier_cell"
          }
        ];
        _ref = this.assignments;
        for (id in _ref) {
          assignment = _ref[id];
          if (assignment.submission_types !== "not_graded") {
            html = "<div class='assignment-name'>" + assignment.name + "</div>";
            if (assignment.points_possible != null) {
              html += "<div class='assignment-points-possible'>" + (I18n.t('points_out_of', "out of %{points_possible}", {
                points_possible: assignment.points_possible
              })) + "</div>";
            }
            outOfFormatter = assignment && assignment.grading_type === 'points' && (assignment.points_possible != null) && SubmissionCell.out_of;
            minWidth = outOfFormatter ? 70 : 50;
            this.columns.push({
              id: "assignment_" + id,
              field: "assignment_" + id,
              name: html,
              object: assignment,
              formatter: this.cellFormatter,
              editor: outOfFormatter || SubmissionCell[assignment.grading_type] || SubmissionCell,
              minWidth: minWidth,
              maxWidth: 200,
              width: testWidth(assignment.name, minWidth)
            });
          }
        }
        _ref2 = this.assignment_groups;
        for (id in _ref2) {
          group = _ref2[id];
          html = "" + group.name;
          if (group.group_weight != null) {
            html += "<div class='assignment-points-possible'>" + (I18n.t('percent_of_grade', "%{percentage} of grade", {
              percentage: I18n.toPercentage(group.group_weight, {
                precision: 0
              })
            })) + "</div>";
          }
          this.columns.push({
            id: "assignment_group_" + id,
            field: "assignment_group_" + id,
            formatter: this.groupTotalFormatter,
            name: html,
            object: group,
            minWidth: 35,
            maxWidth: 200,
            width: testWidth(group.name, 35),
            cssClass: "meta-cell assignment-group-cell"
          });
        }
        this.columns.push({
          id: "total_grade",
          field: "total_grade",
          formatter: this.groupTotalFormatter,
          name: "Total",
          minWidth: 50,
          maxWidth: 100,
          width: testWidth("Total", 50),
          cssClass: "total-cell"
        });
        $widthTester.remove();
        options = $.extend({
          enableCellNavigation: false,
          enableColumnReorder: false,
          enableAsyncPostRender: true,
          asyncPostRenderDelay: 1,
          autoEdit: true,
          rowHeight: 35
        }, this.options);
        grids = [
          {
            selector: '#gradebook_students_grid',
            columns: this.columns.slice(0, 2)
          }, {
            selector: '#gradebook_grid',
            columns: this.columns.slice(2, this.columns.length),
            options: {
              enableCellNavigation: true,
              editable: true,
              syncColumnCellResize: true
            }
          }
        ];
        this.multiGrid = new MultiGrid(this.rows, options, grids, 1);
        this.multiGrid.grids[1].onCellChange = __bind(function(row, col, student) {
          return this.calculateStudentGrade(student);
        }, this);
        this.multiGrid.parent_grid.onKeyDown = __bind(function() {
          return false;
        }, this);
        return typeof this.onGridInit === "function" ? this.onGridInit() : void 0;
      };
      return Gradebook;
    })();
  });
}).call(this);
