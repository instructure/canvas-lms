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

import { createGradebook, setFixtureHtml } from '../../GradebookSpecHelper';
import TotalGradeCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/TotalGradeCellFormatter'

QUnit.module('TotalGradeCellFormatter', function (hooks) {
  let $fixture;
  let gradebook;
  let formatter;
  let grade;

  hooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);
    setFixtureHtml($fixture);

    gradebook = createGradebook({
      grading_standard: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]],
      show_total_grade_as_points: true
    });
    sinon.stub(gradebook, 'getTotalPointsPossible').returns(10);
    sinon.stub(gradebook, 'listInvalidAssignmentGroups').returns([]);
    sinon.stub(gradebook, 'listMutedAssignments').returns([]);
    sinon.stub(gradebook, 'saveSettings')
    formatter = new TotalGradeCellFormatter(gradebook);

    grade = { score: 8, possible: 10 };
  });

  hooks.afterEach(function () {
    gradebook.getTotalPointsPossible.restore();
    gradebook.listInvalidAssignmentGroups.restore();
    gradebook.listMutedAssignments.restore();
    $fixture.remove();
  });

  function renderCell () {
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      grade, // value
      null, // column definition
      null // dataContext
    );
    return $fixture;
  }

  QUnit.module('#render with no grade');

  test('renders no content', function () {
    grade = null;
    strictEqual(renderCell().innerHTML, '');
  });

  QUnit.module('#render with a points grade');

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

  test('avoids floating point calculation issues when computing the percentage', function () {
    grade.score = 946.65
    grade.possible = 1000
    const floatingPointResult = (grade.score / grade.possible) * 100
    equal(floatingPointResult, 94.66499999999999)
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), '94.67%')
  })

  test('renders a dash "-" in the tooltip when the grade has zero points possible', function () {
    grade.possible = 0;
    equal(renderCell().querySelector('.gradebook-tooltip').innerText, '-');
  });

  test('renders a dash "-" in the tooltip when the grade has undefined points possible', function () {
    grade.possible = null;
    equal(renderCell().querySelector('.gradebook-tooltip').innerText, '-');
  });

  QUnit.module('#render with a percent grade', {
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

  QUnit.module('#render with any grade');

  test('renders a warning when there are muted assignments', function () {
    gradebook.listMutedAssignments.returns([{ id: '2301' }]);
    const expectedText = /^This grade differs .* some assignments are muted$/;
    ok(renderCell().querySelector('.gradebook-tooltip').innerText.trim().match(expectedText));
  });

  test('renders a warning icon when there are muted assignments', function () {
    gradebook.listMutedAssignments.returns([{ id: '2301' }]);
    strictEqual(renderCell().querySelectorAll('i.icon-muted').length, 1);
  });

  test('renders a warning when there is an invalid assignment group', function () {
    gradebook.listInvalidAssignmentGroups.returns([{ id: '2401', name: 'Math' }]);
    const expectedText = 'Score does not include Math because it has no points possible';
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), expectedText);
  });

  test('renders a warning icon when there is an invalid assignment group', function () {
    gradebook.listInvalidAssignmentGroups.returns([{ id: '2401', name: 'Math' }]);
    strictEqual(renderCell().querySelectorAll('i.icon-warning').length, 1);
  });

  test('renders a warning when there are multiple invalid assignment groups', function () {
    gradebook.listInvalidAssignmentGroups.returns([{ id: '2401', name: 'Math' }, { id: '2402', name: 'English' }]);
    const expectedText = 'Score does not include Math and English because they have no points possible';
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), expectedText);
  });

  test('renders a warning when total points possible is zero', function () {
    gradebook.getTotalPointsPossible.returns(0);
    const expectedText = 'Can\'t compute score until an assignment has points possible';
    equal(renderCell().querySelector('.gradebook-tooltip').innerText.trim(), expectedText);
  });

  test('renders a warning icon when total points possible is zero', function () {
    gradebook.getTotalPointsPossible.returns(0);
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
