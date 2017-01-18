define([
  'underscore',
  'i18n!gradebook',
], function (_, I18n) {
  var MessageStudentsWhoHelper = {
    settings: function(assignment, students) {
      return {
        options: this.options(assignment),
        title: assignment.name,
        points_possible: assignment.points_possible,
        students: students,
        context_code: "course_" + assignment.course_id,
        callback: this.callbackFn.bind(this),
        subjectCallback: this.generateSubjectCallbackFn(assignment)
      }
    },

    options: function(assignment) {
      var options = this.allOptions();
      var noSubmissions = !this.hasSubmission(assignment);
      if(noSubmissions) options.splice(0,1);
      return options;
    },

    allOptions: function() {
      return [
        {
          text: I18n.t("students_who.havent_submitted_yet", "Haven't submitted yet"),
          subjectFn: (assignment) => I18n.t('students_who.no_submission_for', 'No submission for %{assignment}', { assignment: assignment.name }),
          criteriaFn: (student) => !student.submitted_at
        },
        {
          text: I18n.t("students_who.havent_been_graded", "Haven't been graded"),
          subjectFn: (assignment) => I18n.t('students_who.no_grade_for', 'No grade for %{assignment}', { assignment: assignment.name }),
          criteriaFn: (student) => !this.exists(student.score)
        },
        {
          text: I18n.t("students_who.scored_less_than", "Scored less than"),
          cutoff: true,
          subjectFn: (assignment, cutoff) => I18n.t(
            'Scored less than %{cutoff} on %{assignment}',
            { assignment: assignment.name, cutoff: I18n.n(cutoff) }
          ),
          criteriaFn: (student, cutoff) => this.scoreWithCutoff(student, cutoff) && student.score < cutoff
        },
        {
          text: I18n.t("students_who.scored_more_than", "Scored more than"),
          cutoff: true,
          subjectFn: (assignment, cutoff) => I18n.t(
            'Scored more than %{cutoff} on %{assignment}',
            { assignment: assignment.name, cutoff: I18n.n(cutoff) }
          ),
          criteriaFn: (student, cutoff) => this.scoreWithCutoff(student, cutoff) && student.score > cutoff
        }
      ];
    },

    hasSubmission: function(assignment) {
      var submissionTypes = assignment.submission_types;
      if(submissionTypes.length === 0) return false;

      return _.any(submissionTypes, (submissionType) => {
        return submissionType !== 'none' && submissionType !== 'on_paper';
      });
    },

    exists: function(value) {
      return !_.isUndefined(value) && !_.isNull(value);
    },

    scoreWithCutoff: function(student, cutoff) {
      return this.exists(student.score)
        && student.score !== ''
        && this.exists(cutoff);
    },

    callbackFn: function(selected, cutoff, students) {
      var criteriaFn = this.findOptionByText(selected).criteriaFn;
      var students = _.filter(students, student => criteriaFn(student.user_data, cutoff));
      return _.map(students, student => student.user_data.id);
    },

    findOptionByText: function(text) {
      return _.find(this.allOptions(), option => option.text === text);
    },

    generateSubjectCallbackFn: function(assignment) {
      return (selected, cutoff) => {
        var cutoffString = cutoff || '';
        var subjectFn = this.findOptionByText(selected).subjectFn;
        return subjectFn(assignment, cutoffString);
      }
    }
  };
  return MessageStudentsWhoHelper;
});
