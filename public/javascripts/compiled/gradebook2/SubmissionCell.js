(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  this.SubmissionCell = (function() {
    function SubmissionCell(opts) {
      this.opts = opts;
      this.init();
    }
    SubmissionCell.prototype.init = function() {
      var submission;
      submission = this.opts.item[this.opts.column.field];
      this.$wrapper = $(this.cellWrapper('<input class="grade"/>')).appendTo(this.opts.container);
      return this.$input = this.$wrapper.find('input').focus().select();
    };
    SubmissionCell.prototype.destroy = function() {
      return this.$input.remove();
    };
    SubmissionCell.prototype.focus = function() {
      return this.$input.focus();
    };
    SubmissionCell.prototype.loadValue = function() {
      this.val = this.opts.item[this.opts.column.field].grade || "";
      this.$input.val(this.val);
      this.$input[0].defaultValue = this.val;
      return this.$input.select();
    };
    SubmissionCell.prototype.serializeValue = function() {
      return this.$input.val();
    };
    SubmissionCell.prototype.applyValue = function(item, state) {
      var _ref;
      item[this.opts.column.field].grade = state;
      if ((_ref = this.wrapper) != null) {
        _ref.remove();
      }
      return this.postValue(item, state);
    };
    SubmissionCell.prototype.postValue = function(item, state) {
      var submission, url;
      submission = item[this.opts.column.field];
      url = this.opts.grid.getOptions().change_grade_url;
      url = url.replace(":assignment", submission.assignment_id).replace(":submission", submission.user_id);
      return $.ajaxJSON(url, "PUT", {
        "submission[posted_grade]": state
      }, __bind(function(submission) {
        return $.publish('submissions_updated', [[submission]]);
      }, this));
    };
    SubmissionCell.prototype.isValueChanged = function() {
      return this.val !== this.$input.val();
    };
    SubmissionCell.prototype.validate = function() {
      return {
        valid: true,
        msg: null
      };
    };
    SubmissionCell.formatter = function(row, col, submission, assignment) {
      return this.prototype.cellWrapper(submission.grade, {
        submission: submission,
        assignment: assignment,
        editable: false
      });
    };
    SubmissionCell.prototype.cellWrapper = function(innerContents, options) {
      var opts, specialClasses, tooltipText;
      if (options == null) {
        options = {};
      }
      opts = $.extend({}, {
        innerContents: '',
        classes: '',
        editable: true
      }, options);
      opts.submission || (opts.submission = this.opts.item[this.opts.column.field]);
      opts.assignment || (opts.assignment = this.opts.column.object);
      specialClasses = SubmissionCell.classesBasedOnSubmission(opts.submission, opts.assignment);
      tooltipText = $.map(specialClasses, function(c) {
        return GRADEBOOK_TRANSLATIONS["submission_tooltip_" + c];
      }).join(', ');
      return "" + (tooltipText ? '<div class="gradebook-tooltip">' + tooltipText + '</div>' : '') + "\n<div class=\"gradebook-cell " + (opts.editable ? 'gradebook-cell-editable focus' : '') + " " + opts.classes + " " + (specialClasses.join(' ')) + "\">\n  <a href=\"#\" data-user-id=" + opts.submission.user_id + " data-assignment-id=" + opts.assignment.id + " class=\"gradebook-cell-comment\"><span class=\"gradebook-cell-comment-label\">submission comments</span></a>\n  " + innerContents + "\n</div>";
    };
    SubmissionCell.classesBasedOnSubmission = function(submission, assignment) {
      var classes;
      if (submission == null) {
        submission = {};
      }
      if (assignment == null) {
        assignment = {};
      }
      classes = [];
      if (submission.grade_matches_current_submission === false) {
        classes.push('resubmitted');
      }
      if (assignment.due_at && submission.submitted_at && (submission.submitted_at.timestamp > assignment.due_at.timestamp)) {
        classes.push('late');
      }
      if (submission.drop) {
        classes.push('dropped');
      }
      if ('' + assignment.submission_types === "not_graded") {
        classes.push('ungraded');
      }
      if (assignment.muted) {
        classes.push('muted');
      }
      return classes;
    };
    return SubmissionCell;
  })();
  SubmissionCell.out_of = (function() {
    __extends(out_of, SubmissionCell);
    function out_of() {
      out_of.__super__.constructor.apply(this, arguments);
    }
    out_of.prototype.init = function() {
      var submission;
      submission = this.opts.item[this.opts.column.field];
      this.$wrapper = $(this.cellWrapper("<div class=\"overflow-wrapper\">\n  <div class=\"grade-and-outof-wrapper\">\n    <input type=\"number\" class=\"grade\"/><span class=\"outof\"><span class=\"divider\">/</span>" + this.opts.column.object.points_possible + "</span>\n  </div>\n</div>", {
        classes: 'gradebook-cell-out-of-formatter'
      })).appendTo(this.opts.container);
      return this.$input = this.$wrapper.find('input').focus().select();
    };
    return out_of;
  })();
  SubmissionCell.pass_fail = (function() {
    var classFromSubmission, states;
    __extends(pass_fail, SubmissionCell);
    function pass_fail() {
      pass_fail.__super__.constructor.apply(this, arguments);
    }
    states = ['pass', 'fail', ''];
    classFromSubmission = function(submission) {
      return {
        pass: 'pass',
        complete: 'pass',
        fail: 'fail',
        incomplete: 'fail'
      }[submission.grade] || '';
    };
    pass_fail.prototype.htmlFromSubmission = function(options) {
      var cssClass;
      if (options == null) {
        options = {};
      }
      cssClass = classFromSubmission(options.submission);
      return SubmissionCell.prototype.cellWrapper("<a data-value=\"" + cssClass + "\" class=\"gradebook-checkbox gradebook-checkbox-" + cssClass + " " + (options.editable ? 'editable' : void 0) + "\" href=\"#\">" + cssClass + "</a>", options);
    };
    pass_fail.formatter = function(row, col, submission, assignment) {
      return pass_fail.prototype.htmlFromSubmission({
        submission: submission,
        assignment: assignment,
        editable: false
      });
    };
    pass_fail.prototype.init = function() {
      this.$wrapper = $(this.cellWrapper());
      this.$wrapper = $(this.htmlFromSubmission({
        submission: this.opts.item[this.opts.column.field],
        assignment: this.opts.column.object,
        editable: true
      })).appendTo(this.opts.container);
      return this.$input = this.$wrapper.find('.gradebook-checkbox').bind('click keypress', __bind(function(event) {
        var currentValue, newValue;
        event.preventDefault();
        currentValue = this.$input.data('value');
        if (currentValue === 'pass') {
          newValue = 'fail';
        } else if (currentValue === 'fail') {
          newValue = '';
        } else {
          newValue = 'pass';
        }
        return this.transitionValue(newValue);
      }, this)).focus();
    };
    pass_fail.prototype.destroy = function() {
      return this.$wrapper.remove();
    };
    pass_fail.prototype.transitionValue = function(newValue) {
      return this.$input.removeClass('gradebook-checkbox-pass gradebook-checkbox-fail').addClass('gradebook-checkbox-' + classFromSubmission({
        grade: newValue
      })).data('value', newValue);
    };
    pass_fail.prototype.loadValue = function() {
      return this.val = this.opts.item[this.opts.column.field].grade || "";
    };
    pass_fail.prototype.serializeValue = function() {
      return this.$input.data('value');
    };
    pass_fail.prototype.isValueChanged = function() {
      return this.val !== this.$input.data('value');
    };
    return pass_fail;
  })();
  SubmissionCell.points = (function() {
    __extends(points, SubmissionCell);
    function points() {
      points.__super__.constructor.apply(this, arguments);
    }
    return points;
  })();
}).call(this);
