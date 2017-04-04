import Gradebook from 'compiled/gradebook/Gradebook';
import _ from 'underscore';
import fakeENV from 'helpers/fakeENV';

QUnit.module('addRow', {
  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: { context_id: 1 },
    });
  },
  teardown: () => fakeENV.teardown(),
});

test("doesn't add filtered out users", () => {
  const gb = {
    sections_enabled: true,
    sections: {1: {name: 'Section 1'}, 2: {name: 'Section 2'}},
    options: {},
    rows: [],
    sectionToShow: '2', // this is the filter
    ...Gradebook.prototype
  };

  const student1 = {
    enrollments: [{grades: {}}],
    sections: ['1'],
    name: 'student',
  };
  const student2 = {...student1, sections: ['2']};
  const student3 = {...student1, sections: ['2']};
  [student1, student2, student3].forEach(s => gb.addRow(s));

  ok(student1.row == null, 'filtered out students get no row number');
  ok(student2.row === 0, 'other students do get a row number');
  ok(student3.row === 1, 'row number increments');
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

test('calculates percentage from given  score and possible values', function () {
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

QUnit.module('Gradebook#getFrozenColumnCount');

test('returns number of columns in frozen section', function () {
  const gradebook = new Gradebook({ settings: {}, sections: {} });
  gradebook.parentColumns = [{ id: 'student' }, { id: 'secondary_identifier' }];
  gradebook.customColumns = [{ id: 'custom_col_1' }];
  equal(gradebook.getFrozenColumnCount(), 3);
});
