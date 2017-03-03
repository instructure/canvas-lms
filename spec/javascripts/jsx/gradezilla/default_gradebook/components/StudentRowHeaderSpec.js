import $ from 'jquery'
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants'
import StudentRowHeader from 'jsx/gradezilla/default_gradebook/components/StudentRowHeader'
import 'compiled/handlebars_helpers'

function generateStudent (overrides) {
  return {
    avatar_url: 'http://avatar.url',
    id: 'student_id',
    sis_user_id: 'student_sis_user_id',
    login_id: 'student_login_id',
    sortable_name: 'student_sortable_name',
    name: 'student_regular_name',
    isConcluded: false,
    isInactive: false,
    enrollments: [{grades: {html_url: 'http://html.url'}}],
    ...overrides
  };
}

function generateOpts (
  useSortableName = true,
  selectedSecondaryInfo = StudentRowHeaderConstants.secondaryInfoKeys[0]
) {
  return {
    useSortableName,
    selectedSecondaryInfo,
    sectionNames: 'sectionNames',
    courseId: 1
  };
}

function wrappedRender (header) {
  return $(`<div>${header.render()}</div>`);
}

QUnit.module('StudentRowHeader - constructor', {
  setup () {
    this.student = generateStudent();
    this.opts = generateOpts();
  }
});

test('sets member variables', function () {
  const header = new StudentRowHeader(this.student, this.opts);

  equal(header.student, this.student);
  equal(header.opts, this.opts);
});

QUnit.module('StudentRowHeader - render', {
  setup () {
    this.student = generateStudent();
    this.opts = generateOpts();
  }
});

test('renders with student.name when useSortableName is false', function () {
  this.opts = generateOpts(false);

  const expectedDisplayName = this.student.name;
  const unexpectedDisplayName = this.student.sortable_name;
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.student-name').text().includes(expectedDisplayName));
  notOk($renderOutput.find('.student-name').text().includes(unexpectedDisplayName));
});

test('renders with student.sortable_name when useSortableName is true', function () {
  const expectedDisplayName = this.student.sortable_name;
  const unexpectedDisplayName = this.student.name;
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.student-name').text().includes(expectedDisplayName));
  notOk($renderOutput.find('.student-name').text().includes(unexpectedDisplayName));
});

test('renders with "concluded" status when student.isConcluded is true', function () {
  this.student = generateStudent({isConcluded: true});

  const expectedText = 'concluded';
  const unexpectedText = 'inactive';
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.student-name').text().includes(expectedText));
  notOk($renderOutput.find('.student-name').text().includes(unexpectedText));
});

test('renders with "inactive" status when student.isInactive is true', function () {
  this.student = generateStudent({isInactive: true});

  const expectedText = 'inactive';
  const unexpectedText = 'concluded';
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.student-name').text().includes(expectedText));
  notOk($renderOutput.find('.student-name').text().includes(unexpectedText));
});

test('renders without "inactive" or "concluded" when props on student are false', function () {
  const unexpectedTextInactive = 'inactive';
  const unexpectedTextConcluded = 'concluded';
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  notOk($renderOutput.find('.student-name').text().includes(unexpectedTextInactive));
  notOk($renderOutput.find('.student-name').text().includes(unexpectedTextConcluded));
});

test('renders with student.sis_user_id when opts.selectedSecondaryInfo is "sis_id"', function () {
  this.opts = generateOpts(true, 'sis_id');

  const expectedText = this.student.sis_user_id;
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.secondary-info').text().includes(expectedText));
});

test('renders with student.login_id when opts.selectedSecondaryInfo is "login_id"', function () {
  this.opts = generateOpts(true, 'login_id');

  const expectedText = this.student.login_id;
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.secondary-info').text().includes(expectedText));
});

test('renders with opts.sectionNames when opts.selectedSecondaryInfo is "section"', function () {
  this.opts = generateOpts(true, 'section');

  const expectedText = this.opts.sectionNames;
  const header = new StudentRowHeader(this.student, this.opts);
  const $renderOutput = wrappedRender(header);

  ok($renderOutput.find('.student-section').text().includes(expectedText));
});
