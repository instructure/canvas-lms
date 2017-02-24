define([
  'underscore',
  'react',
  'react-dom',
  'helpers/fakeENV',
  'compiled/gradezilla/Gradebook'
], (_, React, ReactDOM, fakeENV, Gradebook) => {
  QUnit.module("addRow", {
    setup: function() {
      fakeENV.setup({
        GRADEBOOK_OPTIONS: { context_id: 1 },
      });
    },
    teardown: () => fakeENV.teardown(),
  });

  test("doesn't add filtered out users", () => {
    const gb = {
      sections_enabled: true,
      sections: {"1": {name: "Section 1"}, "2": {name: "Section 2"}},
      options: {},
      rows: [],
      sectionToShow: "2", // this is the filter
      ...Gradebook.prototype
    };

    const student1 = {
      enrollments: [{grades: {}}],
      sections: ["1"],
      name: "student",
    };
    const student2 = {...student1, sections: ["2"]};
    const student3 = {...student1, sections: ["2"]};
    [student1, student2, student3].forEach(s => gb.addRow(s));

    ok(student1.row == null, "filtered out students get no row number");
    ok(student2.row === 0, "other students do get a row number");
    ok(student3.row === 1, "row number increments");
    ok(_.isEqual(gb.rows, [student2, student3]));
  });

  QUnit.module('Gradebook#groupTotalFormatter', {
    setup () {
      fakeENV.setup();
    },
    teardown () {
      fakeENV.teardown();
    },
  });

  test('calculates percentage from given score and possible values', function () {
    const gradebook = new Gradebook({ settings: {}, sections: {} });
    const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 10 }, {});
    ok(groupTotalOutput.includes('9 / 10'));
    ok(groupTotalOutput.includes('90%'));
  });

  test('displays percentage as "-" when group total score is positive infinity', function () {
    const gradebook = new Gradebook({ settings: {}, sections: {} });
    this.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(Number.POSITIVE_INFINITY);
    const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
    ok(groupTotalOutput.includes('9 / 0'));
    ok(groupTotalOutput.includes('-'));
  });

  test('displays percentage as "-" when group total score is negative infinity', function () {
    const gradebook = new Gradebook({ settings: {}, sections: {} });
    this.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(Number.NEGATIVE_INFINITY);
    const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
    ok(groupTotalOutput.includes('9 / 0'));
    ok(groupTotalOutput.includes('-'));
  });

  test('displays percentage as "-" when group total score is not a number', function () {
    const gradebook = new Gradebook({ settings: {}, sections: {} });
    this.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(NaN);
    const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
    ok(groupTotalOutput.includes('9 / 0'));
    ok(groupTotalOutput.includes('-'));
  });

  QUnit.module('Gradebook#getAssignmentColumnId');

  test('returns a unique key for the assignment column', function () {
    equal(Gradebook.prototype.getAssignmentColumnId('201'), 'assignment_201');
  });

  QUnit.module('Gradebook#getAssignmentGroupColumnId');

  test('returns a unique key for the assignment group column', function () {
    equal(Gradebook.prototype.getAssignmentGroupColumnId('301'), 'assignment_group_301');
  });

  QUnit.module('Gradebook#getAssignmentColumnHeaderProps', {
    createGradebook (options = {}) {
      const gradebook = new Gradebook({
        settings: {},
        sections: {},
        ...options
      });
      gradebook.setAssignments({
        201: { name: 'Math Assignment' },
        202: { name: 'English Assignment' }
      });
      return gradebook;
    }
  });

  test('includes properties from the assignment', function () {
    const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
    ok(props.assignment, 'assignment is present');
    equal(props.assignment.name, 'Math Assignment');
  });

  QUnit.module('Gradebook#getAssignmentGroupColumnHeaderProps', {
    createGradebook (options = {}) {
      const gradebook = new Gradebook({
        group_weighting_scheme: 'percent',
        settings: {},
        sections: {},
        ...options
      });
      gradebook.setAssignmentGroups({
        301: { name: 'Assignments', group_weight: 40 },
        302: { name: 'Homework', group_weight: 60 }
      });
      return gradebook;
    }
  });

  test('includes properties from the assignment group', function () {
    const props = this.createGradebook().getAssignmentGroupColumnHeaderProps('301');
    ok(props.assignmentGroup, 'assignmentGroup is present');
    equal(props.assignmentGroup.name, 'Assignments');
    equal(props.assignmentGroup.groupWeight, 40);
  });

  test('sets weightedGroups to true when assignment group weighting scheme is "percent"', function () {
    const props = this.createGradebook().getAssignmentGroupColumnHeaderProps('301');
    equal(props.weightedGroups, true);
  });

  test('sets weightedGroups to false when assignment group weighting scheme is not "percent"', function () {
    const options = { group_weighting_scheme: 'equal' };
    const props = this.createGradebook(options).getAssignmentGroupColumnHeaderProps('301');
    equal(props.weightedGroups, false);
  });
});
