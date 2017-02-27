define([
  'underscore',
  'i18n!gradebook',
], (_, I18n) => {
  function getSubmittedAt (student) {
    return (student.submittedAt || student.submitted_at);
  }

  function getSubmissionTypes (assignment) {
    return (assignment.submissionTypes || assignment.submission_types);
  }

  function getCourseId (assignment) {
    return (assignment.courseId || assignment.course_id);
  }

  const MessageStudentsWhoHelper = {
    settings (assignment, students) {
      return {
        options: this.options(assignment),
        title: assignment.name,
        points_possible: assignment.points_possible,
        students,
        context_code: `course_${getCourseId(assignment)}`,
        callback: this.callbackFn.bind(this),
        subjectCallback: this.generateSubjectCallbackFn(assignment)
      }
    },

    options (assignment) {
      const options = this.allOptions();
      const noSubmissions = !this.hasSubmission(assignment);
      if (noSubmissions) options.splice(0, 1);
      return options;
    },

    allOptions () {
      return [
        {
          text: I18n.t("Haven't submitted yet"),
          subjectFn: assignment => I18n.t(
            'No submission for %{assignment}',
            { assignment: assignment.name }
          ),
          criteriaFn: student => !getSubmittedAt(student)
        },
        {
          text: I18n.t("Haven't been graded"),
          subjectFn: assignment => I18n.t(
            'No grade for %{assignment}',
            { assignment: assignment.name }
          ),
          criteriaFn: student => !this.exists(student.score)
        },
        {
          text: I18n.t('Scored less than'),
          cutoff: true,
          subjectFn: (assignment, cutoff) => I18n.t(
            'Scored less than %{cutoff} on %{assignment}',
            { assignment: assignment.name, cutoff: I18n.n(cutoff) }
          ),
          criteriaFn: (student, cutoff) => this.scoreWithCutoff(student, cutoff) && student.score < cutoff
        },
        {
          text: I18n.t('Scored more than'),
          cutoff: true,
          subjectFn: (assignment, cutoff) => I18n.t(
            'Scored more than %{cutoff} on %{assignment}',
            { assignment: assignment.name, cutoff: I18n.n(cutoff) }
          ),
          criteriaFn: (student, cutoff) => this.scoreWithCutoff(student, cutoff) && student.score > cutoff
        }
      ];
    },

    hasSubmission (assignment) {
      const submissionTypes = getSubmissionTypes(assignment);
      if (submissionTypes.length === 0) return false;

      return _.any(submissionTypes, submissionType => submissionType !== 'none' && submissionType !== 'on_paper');
    },

    exists (value) {
      return !_.isUndefined(value) && !_.isNull(value);
    },

    scoreWithCutoff (student, cutoff) {
      return this.exists(student.score)
        && student.score !== ''
        && this.exists(cutoff);
    },

    callbackFn (selected, cutoff, students) {
      const criteriaFn = this.findOptionByText(selected).criteriaFn;
      const studentsMatchingCriteria = _.filter(students, student => criteriaFn(student.user_data, cutoff));
      return _.map(studentsMatchingCriteria, student => student.user_data.id);
    },

    findOptionByText (text) {
      return _.find(this.allOptions(), option => option.text === text);
    },

    generateSubjectCallbackFn (assignment) {
      return (selected, cutoff) => {
        const cutoffString = cutoff || '';
        const subjectFn = this.findOptionByText(selected).subjectFn;
        return subjectFn(assignment, cutoffString);
      }
    }
  };
  return MessageStudentsWhoHelper;
});
