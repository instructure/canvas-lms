require(["jsx/speed_grader/gradingPeriod"], ({
  gradingPeriodForDate,
  dueDateForStudent,
  assignmentClosedForStudent,
}) => {
  QUnit.module("Speedgrader MGP Spec");

  const MS_IN_DAY = 24 * 60 * 60 * 1000;
  const NOW = new Date().getTime();
  const closedGradingPeriod = {
    start_date: new Date(1999, 0, 1).toISOString(),
    end_date:   new Date(1999, 5, 1).toISOString(),
    close_date: new Date(1999, 6, 1).toISOString(),
  };
  // this one is over but not closed
  const pastGradingPeriod = {
    start_date: new Date(NOW - MS_IN_DAY * 8).toISOString(),
    end_date:   new Date(NOW - MS_IN_DAY * 2).toISOString(),
    close_date: new Date(NOW + MS_IN_DAY * 1).toISOString(),
  };
  const currentGradingPeriod = {
    start_date: new Date(NOW - MS_IN_DAY * 1).toISOString(),
    end_date:   new Date(NOW + MS_IN_DAY * 7).toISOString(),
    close_date: new Date(NOW + MS_IN_DAY * 14).toISOString(),
  };

  const gradingPeriods = [
    closedGradingPeriod,
    pastGradingPeriod,
    currentGradingPeriod
  ];

  test("gradingPeriodForDate", () => {
    const pastGPDate =  new Date(NOW - MS_IN_DAY * 3).toISOString();
    ok(gradingPeriodForDate(pastGPDate, gradingPeriods) === pastGradingPeriod);

    const currentGPDate = new Date(NOW + MS_IN_DAY * 5).toISOString();
    ok(gradingPeriodForDate(currentGPDate, gradingPeriods) ===
       currentGradingPeriod);

    const invalidDate = new Date(NOW + MS_IN_DAY * 10).toISOString();
    ok(gradingPeriodForDate(invalidDate, gradingPeriods) ===
       undefined);

    ok(gradingPeriodForDate(null, gradingPeriods) === currentGradingPeriod);
  });

  const student = {id: 1};
  const studentOverride = {student_ids: [1], due_at: currentGradingPeriod.start_date};
  const sectionOverride = {course_section_id: 2, due_at: currentGradingPeriod.end_date};
  const overrides = [studentOverride,sectionOverride];

  test("dueDateForStudent", () => {
    ok(dueDateForStudent(student, [{default: true, due_at: NOW}]) === NOW,
       "no assignment overrides returns default due date");

    ok(dueDateForStudent(student, [
        {default: true, due_at: currentGradingPeriod.start_date},
        ...overrides
      ]) == studentOverride.due_at,
    "returns overrides for matching student_ids");

    ok(dueDateForStudent({...student, section_ids: [2]}, [
         {default: true, due_at: closedGradingPeriod.end_date},
         ...overrides
       ]) == sectionOverride.due_at,
       "returns section due dates");

    ok(dueDateForStudent(student,
        [{default: true, due_at: null}, studentOverride]
      ) == null,
      "returns most lenient date");
  });

  test("assignmentClosedForStudent", () => {
    const dueAt = closedGradingPeriod.start_date + 1;
    ok(!assignmentClosedForStudent(student, {
      due_at: dueAt,
      gradingPeriods: gradingPeriods,
      assignmentOverrides: overrides
    }));

    ok(assignmentClosedForStudent(student, {
      due_at: null,
      only_visible_to_overrides: true,
      gradingPeriods: gradingPeriods,
      assignmentOverrides: [{
        student_ids: [student.id],
        due_at: dueAt
      }],
    }), "respects only_visible_to_overrides");

    const closedStudent = {id: 99};
    ok(assignmentClosedForStudent(closedStudent, {
      due_at: dueAt,
      gradingPeriods: gradingPeriods,
      assignmentOverrides: overrides
    }));
  });
});
