/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import { createGradebook } from 'spec/jsx/gradezilla/default_gradebook/GradebookSpecHelper';

QUnit.module('Total Grade Cell Formatter', function (hooks) {
  let $fixture;
  let gradebook;
  let grade;

  hooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);

    const assignments = {
      2301: { id: '2301', points_possible: 5 },
      2302: { id: '2302', points_possible: 5 }
    };

    gradebook = createGradebook({
      show_total_grade_as_points: true,
      grading_standard: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]]
    });
    gradebook.setAssignments(assignments);
    gradebook.setAssignmentGroups({
      2401: { id: '2401', name: 'Math', assignments: [assignments[2301]] },
      2402: { id: '2402', name: 'English', assignments: [assignments[2302]] }
    });

    grade = { score: 8, possible: 10 };
  });

  hooks.afterEach(function () {
    $fixture.remove();
  });

  function renderCell () {
    gradebook.setAssignmentWarnings();
    $fixture.innerHTML = gradebook.groupTotalFormatter(
      0, // row
      0, // cell
      grade, // value
      { type: 'total_grade' }, // column definition
      null // dataContext
    );
    return $fixture;
  }

  QUnit.module('with no grade');

  test('renders no content', function () {
    grade = null;
    strictEqual(renderCell().innerHTML, '');
  });

  QUnit.module('with a points grade');

  test('renders the score of the grade', function () {
    equal(renderCell().querySelector('.percentage').innerText.trim(), '8');
  });

  test('rounds the score to two decimal places', function () {
    grade.score = 8.345;
    equal(renderCell().querySelector('.percentage').innerText.trim(), '8.35');
  });

  test('renders the percentage of the grade in the tooltip', function () {
    grade.score = 8.2345;
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), '82.35%');
  });

  test('renders a dash "-" in the tooltip when the grade has zero points possible', function () {
    grade.possible = 0;
    equal(renderCell().querySelector('.gradebook-tooltip').innerText, '-');
  });

  test('renders a dash "-" in the tooltip when the grade has undefined points possible', function () {
    grade.possible = null;
    equal(renderCell().querySelector('.gradebook-tooltip').innerText, '-');
  });

  QUnit.module('with a percent grade', {
    setup () {
      gradebook.options.show_total_grade_as_points = false;
    }
  });

  test('renders the percentage of the grade', function () {
    equal(renderCell().querySelector('.percentage').innerText.trim(), '80%');
  });

  test('rounds the percentage to two decimal places', function () {
    grade.score = 8.2345;
    equal(renderCell().querySelector('.percentage').innerText.trim(), '82.35%');
  });

  test('renders a dash "-" when the grade has zero points possible', function () {
    grade.possible = 0;
    equal(renderCell().querySelector('.percentage').innerText, '-');
  });

  test('renders a dash "-" when the grade has undefined points possible', function () {
    grade.possible = null;
    equal(renderCell().querySelector('.percentage').innerText, '-');
  });

  test('renders the score and points possible in the tooltip', function () {
    grade.score = 8.345;
    grade.possible = 10.345;
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), '8.35 / 10.35');
  });

  QUnit.module('with any grade');

  test('renders a warning when there are muted assignments', function () {
    gradebook.assignments[2301].muted = true;
    const expectedText = /^This grade differs .* some assignments are muted$/;
    ok(renderCell().querySelector('.gradebook-tooltip').innerText.trim().match(expectedText));
  });

  test('renders a warning icon when there are muted assignments', function () {
    gradebook.assignments[2301].muted = true;
    strictEqual(renderCell().querySelectorAll('i.icon-muted').length, 1);
  });

  test('renders a warning when there is an invalid assignment group', function () {
    gradebook.options.group_weighting_scheme = 'percent';
    gradebook.assignmentGroups[2401].assignments = [];
    const expectedText = 'Score does not include Math because it has no points possible';
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), expectedText);
  });

  test('renders a warning icon when there is an invalid assignment group', function () {
    gradebook.options.group_weighting_scheme = 'percent';
    gradebook.assignmentGroups[2401].assignments = [];
    strictEqual(renderCell().querySelectorAll('i.icon-warning').length, 1);
  });

  test('renders a warning when there are multiple invalid assignment groups', function () {
    gradebook.options.group_weighting_scheme = 'percent';
    gradebook.assignmentGroups[2401].assignments = [];
    gradebook.assignmentGroups[2402].assignments = [];
    const expectedText = 'Score does not include Math and English because they have no points possible';
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), expectedText);
  });

  test('renders a warning when total points possible is zero', function () {
    gradebook.assignments[2301].points_possible = 0;
    gradebook.assignments[2302].points_possible = null;
    const expectedText = 'Can\'t compute score until an assignment has points possible';
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), expectedText);
  });

  test('renders a warning icon when total points possible is zero', function () {
    gradebook.assignments[2301].points_possible = 0;
    gradebook.assignments[2302].points_possible = null;
    strictEqual(renderCell().querySelectorAll('i.icon-warning').length, 1);
  });

  test('renders a letter grade when using a grading standard', function () {
    equal(renderCell().querySelector('.letter-grade-points').innerText, 'B');
  });

  test('does not render a letter grade when not using a grading standard', function () {
    gradebook.options.grading_standard = null;
    strictEqual(renderCell().querySelector('.letter-grade-points'), null);
  });

  test('does not render a letter grade when the grade has zero points possible', function () {
    grade.possible = 0;
    strictEqual(renderCell().querySelector('.letter-grade-points'), null);
  });

  test('does not render a letter grade when the grade has undefined points possible', function () {
    grade.possible = undefined;
    strictEqual(renderCell().querySelector('.letter-grade-points'), null);
  });
});
