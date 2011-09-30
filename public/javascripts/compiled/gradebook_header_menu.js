(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  I18n.scoped('gradebook2', function(I18n) {
    var GradebookHeaderMenu;
    return this.GradebookHeaderMenu = GradebookHeaderMenu = (function() {
      function GradebookHeaderMenu(assignment, $trigger, gradebook) {
        this.assignment = assignment;
        this.$trigger = $trigger;
        this.gradebook = gradebook;
        this.minimizeColumn = __bind(this.minimizeColumn, this);
        this.reuploadSubmissions = __bind(this.reuploadSubmissions, this);
        this.downloadSubmissions = __bind(this.downloadSubmissions, this);
        this.curveGrades = __bind(this.curveGrades, this);
        this.setDefaultGrade = __bind(this.setDefaultGrade, this);
        this.messageStudentsWho = __bind(this.messageStudentsWho, this);
        this.showAssignmentDetails = __bind(this.showAssignmentDetails, this);
        this.$menu = $("<ul class=\"gradebook-header-menu\">\n  <li><a data-action=\"showAssignmentDetails\" href=\"" + this.gradebook.options.context_url + "/assignments/" + this.assignment.id + "\">" + (I18n.t('assignment_details', 'Assignment Details')) + "</a></li>\n  <li><a href=\"" + this.gradebook.options.context_url + "/gradebook/speed_grader?assignment_id=" + this.assignment.id + "\">" + (I18n.t('speed_grader', 'SpeedGrader')) + "</a></li>\n  <li><a data-action=\"messageStudentsWho\" href=\"#\">" + (I18n.t('message_students_who', 'Message Students Who...')) + "</a></li>\n  <li><a data-action=\"setDefaultGrade\" href=\"#\">" + (I18n.t('set_default_grade', 'Set Default Grade')) + "</a></li>\n  <li><a data-action=\"curveGrades\" href=\"#\">" + (I18n.t('curve_grades', 'Curve Grades')) + "</a></li>\n  <li><a data-action=\"downloadSubmissions\" href=\"#\">" + (I18n.t('download_submissions', 'Download Submissions')) + "</a></li>\n  <li><a data-action=\"reuploadSubmissions\" href=\"#\">" + (I18n.t('reupload_submissions', 'Re-Upload Submissions')) + "</a></li>\n  <li><a data-action=\"minimizeColumn\" href=\"#\">" + (I18n.t('hide_column', 'Hide Column')) + "</a></li>\n</ul>").insertAfter(this.$trigger);
        this.$trigger.kyleMenu({
          noButton: true
        });
        this.$menu.appendTo('#gradebook_grid').delegate('a', 'click', __bind(function(event) {
          var action;
          action = this[$(event.target).data('action')];
          if (action) {
            action();
            return false;
          }
        }, this)).bind('popupopen popupclose', __bind(function(event) {
          return this.$trigger.toggleClass('ui-menu-trigger-menu-is-open', event.type === 'popupopen');
        }, this)).bind('popupopen', __bind(function() {
          var action, condition, _ref, _results;
          _ref = {
            showAssignmentDetails: this.gradebook.allSubmissionsLoaded,
            messageStudentsWho: this.gradebook.allSubmissionsLoaded,
            setDefaultGrade: this.gradebook.allSubmissionsLoaded,
            curveGrades: this.gradebook.allSubmissionsLoaded && this.assignment.grading_type !== 'pass_fail' && this.assignment.points_possible,
            downloadSubmissions: ("" + this.assignment.submission_types).match(/(online_upload|online_text_entry|online_url)/),
            reuploadSubmissions: this.assignment.submissions_downloads > 0
          };
          _results = [];
          for (action in _ref) {
            condition = _ref[action];
            _results.push(this.$menu.find("[data-action=" + action + "]").showIf(condition));
          }
          return _results;
        }, this)).popup('open');
      }
      GradebookHeaderMenu.prototype.showAssignmentDetails = function() {
        return $('<div>TODO: show assignment stats, is doing what we were doing best? look at: http://www.highcharts.com/demo/scatter/grid</div>').dialog();
      };
      GradebookHeaderMenu.prototype.messageStudentsWho = function() {
        var i, student, students;
        students = (function() {
          var _ref, _results;
          _ref = this.gradebook.students;
          _results = [];
          for (i in _ref) {
            student = _ref[i];
            _results.push($.extend({
              id: student.id,
              name: student.name
            }, student["assignment_" + this.assignment.id]));
          }
          return _results;
        }).call(this);
        return window.messageStudents({
          options: [
            {
              text: I18n.t("students_who.havent_submitted_yet", "Haven't submitted yet")
            }, {
              text: I18n.t("students_who.scored_less_than", "Scored less than"),
              cutoff: true
            }, {
              text: I18n.t("students_who.scored_more_than", "Scored more than"),
              cutoff: true
            }
          ],
          title: this.assignment.name,
          points_possible: this.assignment.points_possible,
          students: students,
          callback: function(selected, cutoff, students) {
            students = $.grep(students, function($student, idx) {
              student = $student.user_data;
              if (selected === I18n.t("not_submitted_yet", "Haven't submitted yet")) {
                return !student.submitted_at;
              } else if (selected === I18n.t("scored_less_than", "Scored less than")) {
                return (student.score != null) && student.score !== "" && (cutoff != null) && student.score < cutoff;
              } else if (selected === I18n.t("scored_more_than", "Scored more than")) {
                return (student.score != null) && student.score !== "" && (cutoff != null) && student.score > cutoff;
              }
            });
            return $.map(students, function(student) {
              return student.user_data.id;
            });
          }
        });
      };
      GradebookHeaderMenu.prototype.setDefaultGrade = function() {
        return new setDefaultGradeDialog(this.assignment, this.gradebook);
      };
      GradebookHeaderMenu.prototype.curveGrades = function() {
        return new curveGradesDialog(this.assignment, this.gradebook);
      };
      GradebookHeaderMenu.prototype.downloadSubmissions = function() {
        var url, _base, _ref;
        url = $.replaceTags(this.gradebook.options.download_assignment_submissions_url, "assignment_id", this.assignment.id);
        INST.downloadSubmissions(url);
        return this.assignment.submissions_downloads = ((_ref = (_base = this.assignment).submissions_downloads) != null ? _ref : _base.submissions_downloads = 0) + 1;
      };
      GradebookHeaderMenu.prototype.reuploadSubmissions = function() {
        var url;
        if (!this.$re_upload_submissions_form) {
          GradebookHeaderMenu.prototype.$re_upload_submissions_form = $("#re_upload_submissions_form");
          this.$re_upload_submissions_form.dialog({
            width: 400,
            modal: true,
            resizable: false,
            autoOpen: false
          }).submit(function() {
            var data;
            data = $(this).getFormData();
            if (!data.submissions_zip) {
              return false;
            } else if (!data.submissions_zip.match(/\.zip$/)) {
              $(this).formErrors({
                submissions_zip: I18n.t('errors.upload_as_zip', "Please upload files as a .zip")
              });
              return false;
            }
          });
        }
        url = $.replaceTags(this.gradebook.options.re_upload_submissions_url, "assignment_id", this.assignment.id);
        return this.$re_upload_submissions_form.attr('action', url).dialog('open');
      };
      GradebookHeaderMenu.prototype.minimizeColumn = function(event) {
        return this.gradebook.minimizeColumn($(event.target).closest('.slick-header-column'));
      };
      return GradebookHeaderMenu;
    })();
  });
}).call(this);
