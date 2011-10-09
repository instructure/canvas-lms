(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  I18n.scoped('AssignmentDetailsDialog', function(I18n) {
    return this.SubmissionDetailsDialog = (function() {
      function SubmissionDetailsDialog(assignment, student, options) {
        var deferred;
        this.assignment = assignment;
        this.student = student;
        this.options = options;
        this.update = __bind(this.update, this);
        this.scrollCommentsToBottom = __bind(this.scrollCommentsToBottom, this);
        this.open = __bind(this.open, this);
        this.url = this.options.change_grade_url.replace(":assignment", this.assignment.id).replace(":submission", this.student.id);
        this.submission = $.extend({}, this.student["assignment_" + this.assignment.id], {
          assignment: this.assignment,
          speedGraderUrl: "" + this.options.context_url + "/gradebook/speed_grader?assignment_id=" + this.assignment.id + "#%7B%22student_id%22%3A" + this.student.id + "%7D",
          loading: true
        });
        this.dialog = $('<div class="use-css-transitions-for-show-hide" style="padding:0;"/>');
        this.dialog.html(Template('SubmissionDetailsDialog', this.submission)).dialog({
          title: this.student.name,
          width: 600,
          resizable: false,
          open: this.scrollCommentsToBottom
        }).delegate('select', 'change', __bind(function(event) {
          return this.dialog.find('.submission_detail').each(function(index) {
            return $(this).showIf(index === event.currentTarget.selectedIndex);
          });
        }, this)).delegate('.submission_details_add_comment_form', 'submit', __bind(function(event) {
          event.preventDefault();
          return $(event.currentTarget).disableWhileLoading($.ajaxJSON(this.url, 'PUT', $(event.currentTarget).getFormData(), __bind(function(data) {
            this.update(data);
            return setTimeout(__bind(function() {
              return this.dialog.dialog('close');
            }, this), 500);
          }, this)));
        }, this));
        deferred = $.ajaxJSON(this.url + '?include[]=submission_history&include[]=submission_comments&include[]=rubric_assessment', 'GET', {}, this.update);
        this.dialog.find('.submission_details_comments').disableWhileLoading(deferred);
      }
      SubmissionDetailsDialog.prototype.open = function() {
        return this.dialog.dialog('open');
      };
      SubmissionDetailsDialog.prototype.scrollCommentsToBottom = function() {
        return this.dialog.find('.submission_details_comments').scrollTop(999999);
      };
      SubmissionDetailsDialog.prototype.update = function(newData) {
        var attachment, comment, submission, turnitinDataForThisAttachment, urlPrefix, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3, _ref4;
        $.extend(this.submission, newData);
        this.submission.submission_history[0] = this.submission;
        this.submission.moreThanOneSubmission = this.submission.submission_history.length > 1;
        this.submission.loading = false;
        _ref = this.submission.submission_history;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          submission = _ref[_i];
          submission["submission_type_is" + submission.submission_type] = true;
          submission.submissionWasLate = this.assignment.due_at && new Date(this.assignment.due_at) > new Date(submission.submitted_at);
          _ref2 = submission.submission_comments || [];
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            comment = _ref2[_j];
            comment.url = "" + this.options.context_url + "/users/" + comment.author_id;
            urlPrefix = "" + location.protocol + "//" + location.host;
            comment.image_url = "" + urlPrefix + "/images/users/" + comment.author_id + "?fallback=" + (encodeURIComponent(urlPrefix + '/images/messages/avatar-50.png'));
          }
          _ref3 = submission.attachments || [];
          for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
            attachment = _ref3[_k];
            if (turnitinDataForThisAttachment = (_ref4 = submission.turnitin_data) != null ? _ref4["attachment_" + attachment.id] : void 0) {
              attachment.turnitinUrl = "" + this.options.context_url + "/assignments/" + this.assignment.id + "/submissions/" + this.student.id + "/turnitin/attachment_" + attachment.id;
              attachment.turnitin_data = turnitinDataForThisAttachment;
            }
          }
        }
        this.dialog.html(Template('SubmissionDetailsDialog', this.submission));
        this.dialog.find('select').trigger('change');
        return this.scrollCommentsToBottom();
      };
      SubmissionDetailsDialog.cachedDialogs = {};
      SubmissionDetailsDialog.open = function(assignment, student, options) {
        var _base, _name;
        return ((_base = SubmissionDetailsDialog.cachedDialogs)[_name = "" + assignment.id + "-" + student.id] || (_base[_name] = new SubmissionDetailsDialog(assignment, student, options))).open();
      };
      return SubmissionDetailsDialog;
    })();
  });
}).call(this);
