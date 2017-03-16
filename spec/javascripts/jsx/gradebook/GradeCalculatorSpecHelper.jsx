define(() => {
  const GradeCalculatorSpecHelper = {
    createCourseGradesWithGradingPeriods () {
      return {
        assignmentGroups: {
          301: {
            assignmentGroupId: 301,
            assignmentGroupWeight: 40,
            current: { score: 5, possible: 10, submissions: [] },
            final: { score: 5, possible: 20, submissions: [] }
          },

          302: {
            assignmentGroupId: 302,
            assignmentGroupWeight: 60,
            current: { score: 12, possible: 15, submissions: [] },
            final: { score: 12, possible: 25, submissions: [] }
          }
        },

        gradingPeriods: {
          701: {
            gradingPeriodId: 701,
            gradingPeriodWeight: 25,
            assignmentGroups: {
              301: {
                assignmentGroupId: 301,
                assignmentGroupWeight: 40,
                current: { score: 5, possible: 10, submissions: [] },
                final: { score: 5, possible: 20, submissions: [] }
              }
            },
            current: { score: 5, possible: 10, submissions: [] },
            final: { score: 5, possible: 20, submissions: [] }
          },

          702: {
            gradingPeriodId: 702,
            gradingPeriodWeight: 75,
            assignmentGroups: {
              302: {
                assignmentGroupId: 302,
                assignmentGroupWeight: 60,
                current: { score: 12, possible: 15, submissions: [] },
                final: { score: 12, possible: 25, submissions: [] }
              },
            },
            current: { score: 12, possible: 15, submissions: [] },
            final: { score: 12, possible: 25, submissions: [] }
          },
        },

        current: { score: 17, possible: 25, submissions: [] },
        final: { score: 17, possible: 45, submissions: [] }
      };
    }
  };

  return GradeCalculatorSpecHelper;
});
