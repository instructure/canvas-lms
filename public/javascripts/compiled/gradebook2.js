(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  I18n.scoped('gradebook2', function(I18n) {
    var Gradebook;
    return this.Gradebook = Gradebook = (function() {
      var minimumAssignmentColumWidth;
      minimumAssignmentColumWidth = 10;
      function Gradebook(options) {
        this.options = options;
        this.initHeader = __bind(this.initHeader, this);
        this.hoverMinimizedCell = __bind(this.hoverMinimizedCell, this);
        this.unminimizeColumn = __bind(this.unminimizeColumn, this);
        this.minimizeColumn = __bind(this.minimizeColumn, this);
        this.fixColumnReordering = __bind(this.fixColumnReordering, this);
        this.showCommentDialog = __bind(this.showCommentDialog, this);
        this.unhighlightColumns = __bind(this.unhighlightColumns, this);
        this.highlightColumn = __bind(this.highlightColumn, this);
        this.calculateStudentGrade = __bind(this.calculateStudentGrade, this);
        this.groupTotalFormatter = __bind(this.groupTotalFormatter, this);
        this.staticCellFormatter = __bind(this.staticCellFormatter, this);
        this.cellFormatter = __bind(this.cellFormatter, this);
        this.gotSubmissionsChunk = __bind(this.gotSubmissionsChunk, this);
        this.rowFilter = __bind(this.rowFilter, this);
        this.gotStudents = __bind(this.gotStudents, this);
        this.gotAssignmentGroups = __bind(this.gotAssignmentGroups, this);
        this.chunk_start = 0;
        this.students = {};
        this.rows = [];
        this.sortFn = function(student) {
          return student.display_name;
        };
        this.assignmentsToHide = ($.store.userGet("hidden_columns_" + this.options.context_code) || '').split(',');
        this.sectionToShow = Number($.store.userGet("grading_show_only_section" + this.options.context_id)) || void 0;
        this.show_attendance = $.store.userGet("show_attendance_" + this.options.context_code) === 'true';
        this.include_ungraded_assignments = $.store.userGet("include_ungraded_assignments_" + this.options.context_code) === 'true';
        $.when($.ajaxJSON(this.options.assignment_groups_url, "GET", {}, this.gotAssignmentGroups), $.ajaxJSON(this.options.sections_and_students_url, "GET", this.sectionToShow && {
          sections: [this.sectionToShow]
        })).then(__bind(function(assignmentGroupsArgs, studentsArgs) {
          this.gotStudents.apply(this, studentsArgs);
          return this.initHeader();
        }, this));
      }
      Gradebook.prototype.gotAssignmentGroups = function(assignment_groups) {
        var assignment, group, _i, _len, _results;
        this.assignment_groups = {};
        this.assignments = {};
        _results = [];
        for (_i = 0, _len = assignment_groups.length; _i < _len; _i++) {
          group = assignment_groups[_i];
          $.htmlEscapeValues(group);
          this.assignment_groups[group.id] = group;
          _results.push((function() {
            var _j, _len2, _ref, _results2;
            _ref = group.assignments;
            _results2 = [];
            for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
              assignment = _ref[_j];
              $.htmlEscapeValues(assignment);
              if (assignment.due_at) {
                assignment.due_at = $.parseFromISO(assignment.due_at);
              }
              _results2.push(this.assignments[assignment.id] = assignment);
            }
            return _results2;
          }).call(this));
        }
        return _results;
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
        return this.getSubmissionsChunks();
      };
      Gradebook.prototype.rowFilter = function(student) {
        return !this.sectionToShow || (student.section.id === this.sectionToShow);
      };
      Gradebook.prototype.buildRows = function() {
        var column, i, id, sortables, student, _len, _ref, _ref2, _ref3, _ref4;
        this.rows.length = 0;
        sortables = {};
        _ref = this.gradeGrid.getColumns();
        for (id in _ref) {
          column = _ref[id];
          if ('' + ((_ref2 = column.object) != null ? _ref2.submission_types : void 0) === "attendance") {
            column.unselectable = !this.show_attendance;
            column.cssClass = this.show_attendance ? '' : 'completely-hidden';
            this.$grid.find("[id*='" + column.id + "']").showIf(this.show_attendance);
          }
        }
        _ref3 = this.students;
        for (id in _ref3) {
          student = _ref3[id];
          student.row = -1;
          if (this.rowFilter(student)) {
            this.rows.push(student);
            this.calculateStudentGrade(student);
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
        _ref4 = this.rows;
        for (i = 0, _len = _ref4.length; i < _len; i++) {
          student = _ref4[i];
          student.row = i;
        }
        this.multiGrid.removeAllRows();
        this.multiGrid.updateRowCount();
        return this.multiGrid.render();
      };
      Gradebook.prototype.getSubmissionsChunks = function() {
        var assignment, id, params, student, students, _results;
        _results = [];
        while (true) {
          students = this.rows.slice(this.chunk_start, this.chunk_start + this.options.chunk_size);
          if (!students.length) {
            break;
          }
          params = {
            student_ids: (function() {
              var _i, _len, _results2;
              _results2 = [];
              for (_i = 0, _len = students.length; _i < _len; _i++) {
                student = students[_i];
                _results2.push(student.id);
              }
              return _results2;
            })(),
            assignment_ids: (function() {
              var _ref, _results2;
              _ref = this.assignments;
              _results2 = [];
              for (id in _ref) {
                assignment = _ref[id];
                _results2.push(id);
              }
              return _results2;
            }).call(this),
            response_fields: ['user_id', 'url', 'score', 'grade', 'submission_type', 'submitted_at', 'assignment_id', 'grade_matches_current_submission']
          };
          $.ajaxJSON(this.options.submissions_url, "GET", params, this.gotSubmissionsChunk);
          _results.push(this.chunk_start += this.options.chunk_size);
        }
        return _results;
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
        return this.multiGrid.render();
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
        gradeToShow = val;
        percentage = columnDef.field === 'total_grade' ? gradeToShow.score : (gradeToShow.score / gradeToShow.possible) * 100;
        percentage = Math.round(percentage);
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
            student["assignment_group_" + group.group.id] = group[this.include_ungraded_assignments ? 'final' : 'current'];
          }
          return student["total_grade"] = result[this.include_ungraded_assignments ? 'final' : 'current'];
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
      Gradebook.prototype.fixColumnReordering = function() {
        var $headers, fixupStopCallback, makeOnlyAssignmentsSortable, onlyAssignmentColsSelector, originalItemsSelector, originalStopFn;
        $headers = $('#gradebook_grid').find('.slick-header-columns');
        originalItemsSelector = $headers.sortable('option', 'items');
        onlyAssignmentColsSelector = '> *:not([id*="assignment_group"]):not([id*="total_grade"])';
        (makeOnlyAssignmentsSortable = function() {
          var $notAssignments;
          $headers.sortable('option', 'items', onlyAssignmentColsSelector);
          $notAssignments = $(originalItemsSelector, $headers).not($(onlyAssignmentColsSelector, $headers));
          return $notAssignments.data('sortable-item', null);
        })();
        originalStopFn = $headers.sortable('option', 'stop');
        return (fixupStopCallback = function() {
          return $headers.sortable('option', 'stop', function(event, ui) {
            var returnVal;
            $headers.sortable('option', 'items', originalItemsSelector);
            returnVal = originalStopFn.apply(this, arguments);
            makeOnlyAssignmentsSortable();
            fixupStopCallback();
            return returnVal;
          });
        })();
      };
      Gradebook.prototype.minimizeColumn = function($columnHeader) {
        var colIndex, columnDef;
        colIndex = $columnHeader.index();
        columnDef = this.gradeGrid.getColumns()[colIndex];
        columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '') + ' minimized';
        columnDef.unselectable = true;
        columnDef.unminimizedName = columnDef.name;
        columnDef.name = '';
        this.$grid.find(".c" + colIndex).add($columnHeader).addClass('minimized');
        $columnHeader.data('minimized', true);
        this.assignmentsToHide.push(columnDef.id);
        return $.store.userSet("hidden_columns_" + this.options.context_code, $.uniq(this.assignmentsToHide).join(','));
      };
      Gradebook.prototype.unminimizeColumn = function($columnHeader) {
        var assignmentsToHide, colIndex, columnDef;
        colIndex = $columnHeader.index();
        columnDef = this.gradeGrid.getColumns()[colIndex];
        columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '');
        columnDef.unselectable = false;
        columnDef.name = columnDef.unminimizedName;
        this.$grid.find(".c" + colIndex).add($columnHeader).removeClass('minimized');
        $columnHeader.removeData('minimized');
        assignmentsToHide = $.grep(this.assignmentsToHide, function(el) {
          return el !== columnDef.id;
        });
        return $.store.userSet("hidden_columns_" + this.options.context_code, $.uniq(this.assignmentsToHide).join(','));
      };
      Gradebook.prototype.hoverMinimizedCell = function(event) {
        var $hoveredCell, assignment, columnDef, htmlLines, offset, submission, _ref;
        $hoveredCell = $(event.currentTarget).removeClass('hover');
        columnDef = this.gradeGrid.getColumns()[$hoveredCell.index()];
        assignment = columnDef.object;
        offset = $hoveredCell.offset();
        htmlLines = [assignment.name];
        if ($hoveredCell.hasClass('slick-cell')) {
          submission = this.rows[this.gradeGrid.getCellFromEvent(event).row][columnDef.id];
          if (assignment.points_possible != null) {
            htmlLines.push("" + ((_ref = submission.score) != null ? _ref : '--') + " / " + assignment.points_possible);
          } else if (submission.score != null) {
            htmlLines.push(submission.score);
          }
          Array.prototype.push.apply(htmlLines, $.map(SubmissionCell.classesBasedOnSubmission(submission, assignment), __bind(function(c) {
            return GRADEBOOK_TRANSLATIONS["#submission_tooltip_" + c];
          }, this)));
        } else if (assignment.points_possible != null) {
          htmlLines.push(I18n.t('points_out_of', "out of %{points_possible}", {
            points_possible: assignment.points_possible
          }));
        }
        return $hoveredCell.data('tooltip', $("<span />", {
          "class": 'gradebook-tooltip',
          css: {
            left: offset.left - 15,
            top: offset.top,
            zIndex: 10000,
            display: 'block'
          },
          html: htmlLines.join('<br />')
        }).appendTo('body').css('top', function(i, top) {
          return parseInt(top) - $(this).outerHeight();
        }));
      };
      Gradebook.prototype.unhoverMinimizedCell = function(event) {
        var $tooltip;
        if ($tooltip = $(this).data('tooltip')) {
          if (event.toElement === $tooltip[0]) {
            return $tooltip.mouseleave(function() {
              return $tooltip.remove();
            });
          } else {
            return $tooltip.remove();
          }
        }
      };
      Gradebook.prototype.onGridInit = function() {
        var grid, tooltipTexts;
        this.fixColumnReordering();
        tooltipTexts = {};
        this.$grid = grid = $('#gradebook_grid').fillWindowWithMe({
          alsoResize: '#gradebook_students_grid',
          onResize: __bind(function() {
            return this.multiGrid.resizeCanvas();
          }, this)
        }).delegate('.slick-cell', {
          'mouseenter.gradebook focusin.gradebook': this.highlightColumn,
          'mouseleave.gradebook focusout.gradebook': this.unhighlightColumns,
          'mouseenter focusin': function(event) {
            grid.find('.hover, .focus').removeClass('hover focus');
            return $(this).addClass((event.type === 'mouseenter' ? 'hover' : 'focus'));
          },
          'mouseleave focusout': function() {
            return $(this).removeClass('hover focus');
          }
        }).delegate('.gradebook-cell-comment', 'click.gradebook', this.showCommentDialog).delegate('.minimized', {
          'mouseenter': this.hoverMinimizedCell,
          'mouseleave': this.unhoverMinimizedCell
        });
        $('#gradebook_grid .slick-resizable-handle').live('drag', __bind(function(e, dd) {
          return this.$grid.find('.slick-header-column').each(__bind(function(i, elem) {
            var $columnHeader, isMinimized;
            $columnHeader = $(elem);
            isMinimized = $columnHeader.data('minimized');
            if ($columnHeader.outerWidth() <= minimumAssignmentColumWidth) {
              if (!isMinimized) {
                return this.minimizeColumn($columnHeader);
              }
            } else if (isMinimized) {
              return this.unminimizeColumn($columnHeader);
            }
          }, this));
        }, this));
        return $(document).trigger('gridready');
      };
      Gradebook.prototype.initHeader = function() {
        var $courseSectionTemplate, $sectionToShowMenu, $settingsMenu, allSectionsText, i, section, _ref;
        if (this.sections_enabled) {
          $courseSectionTemplate = $('#course_section_template').removeAttr('id').detach();
          $sectionToShowMenu = $('#section_to_show').next();
          allSectionsText = $('#section_being_shown').text();
          if (this.sectionToShow) {
            $('#section_being_shown').text(this.sections[this.sectionToShow].name);
          }
          _ref = this.sections;
          for (i in _ref) {
            section = _ref[i];
            $courseSectionTemplate.clone().appendTo($sectionToShowMenu).find('label').attr('for', "section_option_" + section.id).text(section.name).end().find('input').attr({
              id: "section_option_" + section.id,
              value: section.id
            }).prop('checked', section.id === this.sectionToShow);
          }
          $('#section_to_show').show().kyleMenu({
            buttonOpts: {
              icons: {
                primary: "ui-icon-sections",
                secondary: "ui-icon-droparrow"
              }
            }
          });
          $sectionToShowMenu.bind('menuselect', __bind(function(event, ui) {
            this.sectionToShow = Number($sectionToShowMenu.find('input[name="section_to_show_radio"]:checked').val()) || void 0;
            $.store[this.sectionToShow ? 'userSet' : 'userRemove']("grading_show_only_section" + this.options.context_id, this.sectionToShow);
            $('#section_being_shown').text(this.sectionToShow ? this.sections[this.sectionToShow].name : allSectionsText);
            return this.buildRows();
          }, this));
        }
        $settingsMenu = $('#gradebook_settings').next();
        $.each(['show_attendance', 'include_ungraded_assignments'], __bind(function(i, setting) {
          return $settingsMenu.find("#" + setting).prop('checked', this[setting]).change(__bind(function(event) {
            this[setting] = $(event.target).is(':checked');
            $.store.userSet("" + setting + "_" + this.options.context_code, '' + this[setting]);
            return this.buildRows();
          }, this));
        }, this));
        $('#gradebook_settings').show().kyleMenu({
          buttonOpts: {
            icons: {
              primary: "ui-icon-cog",
              secondary: "ui-icon-droparrow"
            }
          }
        });
        return $settingsMenu.find('.gradebook_upload_link').click(function(event) {
          var dialogData;
          event.preventDefault();
          dialogData = {
            bgiframe: true,
            autoOpen: false,
            modal: true,
            width: 410,
            resizable: false,
            buttons: {}
          };
          dialogData['buttons'][I18n.t('buttons.upload_data', 'Upload Data')] = function() {
            return $(this).submit();
          };
          return $("#upload_modal").dialog(dialogData).dialog('open');
        });
      };
      Gradebook.prototype.initGrid = function() {
        var $widthTester, assignment, columnDef, fieldName, grids, group, html, id, minWidth, options, outOfFormatter, sortRowsBy, testWidth, _ref, _ref2;
        $widthTester = $('<span style="padding:10px" />').appendTo('#content');
        testWidth = function(text, minWidth) {
          return Math.max($widthTester.text(text).outerWidth(), minWidth);
        };
        this.columns = [
          {
            id: 'student',
            name: I18n.t('student_name', 'Student Name'),
            field: 'display_name',
            width: 150,
            cssClass: "meta-cell",
            resizable: false,
            sortable: true
          }, {
            id: 'secondary_identifier',
            name: I18n.t('secondary_id', 'Secondary ID'),
            field: 'secondary_identifier',
            width: 100,
            cssClass: "meta-cell secondary_identifier_cell",
            resizable: false,
            sortable: true
          }
        ];
        _ref = this.assignments;
        for (id in _ref) {
          assignment = _ref[id];
          html = "<div class='assignment-name'>" + assignment.name + "</div>";
          if (assignment.points_possible != null) {
            html += "<div class='assignment-points-possible'>" + (I18n.t('points_out_of', "out of %{points_possible}", {
              points_possible: assignment.points_possible
            })) + "</div>";
          }
          outOfFormatter = assignment && assignment.grading_type === 'points' && (assignment.points_possible != null) && SubmissionCell.out_of;
          minWidth = outOfFormatter ? 70 : 50;
          fieldName = "assignment_" + id;
          columnDef = {
            id: fieldName,
            field: fieldName,
            name: html,
            object: assignment,
            formatter: this.cellFormatter,
            editor: outOfFormatter || SubmissionCell[assignment.grading_type] || SubmissionCell,
            minWidth: minimumAssignmentColumWidth,
            maxWidth: 200,
            width: testWidth(assignment.name, minWidth),
            sortable: true,
            toolTip: true
          };
          if ('' + assignment.submission_types === "not_graded") {
            columnDef.cssClass = 'ungraded';
            columnDef.unselectable = true;
          } else if ($.inArray(fieldName, this.assignmentsToHide) !== -1) {
            columnDef.width = 10;
            __bind(function(fieldName) {
              return $(document).bind('gridready', __bind(function() {
                return this.minimizeColumn(this.$grid.find("[id*='" + fieldName + "']"));
              }, this)).unbind('gridready.render').bind('gridready.render', __bind(function() {
                return this.gradeGrid.invalidate();
              }, this));
            }, this)(fieldName);
          }
          this.columns.push(columnDef);
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
            cssClass: "meta-cell assignment-group-cell",
            sortable: true
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
          cssClass: "total-cell",
          sortable: true
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
              syncColumnCellResize: true,
              enableColumnReorder: true
            }
          }
        ];
        this.multiGrid = new MultiGrid(this.rows, options, grids, 1);
        this.gradeGrid = this.multiGrid.grids[1];
        this.gradeGrid.onCellChange = __bind(function(row, col, student) {
          return this.calculateStudentGrade(student);
        }, this);
        sortRowsBy = __bind(function(sortFn) {
          var i, student, _len, _ref3;
          this.rows.sort(sortFn);
          _ref3 = this.rows;
          for (i = 0, _len = _ref3.length; i < _len; i++) {
            student = _ref3[i];
            student.row = i;
          }
          return this.multiGrid.invalidate();
        }, this);
        this.gradeGrid.onSort = __bind(function(sortCol, sortAsc) {
          return sortRowsBy(function(a, b) {
            var aScore, bScore, _ref3, _ref4;
            aScore = (_ref3 = a[sortCol.field]) != null ? _ref3.score : void 0;
            bScore = (_ref4 = b[sortCol.field]) != null ? _ref4.score : void 0;
            if (!aScore && aScore !== 0) {
              aScore = -99999999999;
            }
            if (!bScore && bScore !== 0) {
              bScore = -99999999999;
            }
            if (sortAsc) {
              return bScore - aScore;
            } else {
              return aScore - bScore;
            }
          });
        }, this);
        this.multiGrid.grids[0].onSort = __bind(function(sortCol, sortAsc) {
          var propertyToSortBy;
          propertyToSortBy = {
            display_name: 'sortable_name',
            secondary_identifier: 'secondary_identifier'
          }[sortCol.field];
          return sortRowsBy(function(a, b) {
            var res;
            res = a[propertyToSortBy] < b[propertyToSortBy] ? -1 : a[propertyToSortBy] > b[propertyToSortBy] ? 1 : 0;
            if (sortAsc) {
              return res;
            } else {
              return 0 - res;
            }
          });
        }, this);
        this.multiGrid.parent_grid.onKeyDown = __bind(function() {
          return false;
        }, this);
        return this.onGridInit();
      };
      return Gradebook;
    })();
  });
}).call(this);
