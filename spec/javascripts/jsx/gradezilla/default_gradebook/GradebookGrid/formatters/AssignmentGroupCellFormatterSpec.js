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
import AssignmentGroupCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/AssignmentGroupCellFormatter'

QUnit.module('AssignmentGroupCellFormatter', function (hooks) {
  let $fixture;
  let gradebook;
  let formatter;
  let grade;

  hooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);
    setFixtureHtml($fixture);

    gradebook = createGradebook();
    sinon.stub(gradebook, 'saveSettings')
    formatter = new AssignmentGroupCellFormatter(gradebook);

    grade = { score: 8, possible: 10 };
  });

  hooks.afterEach(function () {
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

  QUnit.module('#render with a grade');

  test('renders the percentage of the grade', function () {
    equal(renderCell().querySelector('.percentage').innerHTML.trim(), '80%');
  });

  test('rounds the percentage to two decimal places', function () {
    grade.score = 8.2345;
    equal(renderCell().querySelector('.percentage').innerHTML.trim(), '82.35%');
  });

  test('avoids floating point calculation issues', function () {
    grade.score = 946.65;
    grade.possible = 1000
    equal(renderCell().querySelector('.percentage').innerHTML.trim(), '94.67%');
  });

  test('renders a dash "-" when the grade has zero points possible', function () {
    grade.possible = 0;
    equal(renderCell().querySelector('.percentage').innerHTML.trim(), '-');
  });

  test('renders a dash "-" when the grade has undefined points possible', function () {
    grade.possible = null;
    equal(renderCell().querySelector('.percentage').innerHTML.trim(), '-');
  });

  test('renders the score and points possible in the tooltip', function () {
    grade.score = 8.345;
    grade.possible = 10.345;
    equal(renderCell().querySelector('.gradebook-tooltip').innerHTML.trim(), '8.35 / 10.35');
  });
});
