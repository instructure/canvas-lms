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

import $ from 'jquery';
import gradebook_uploads from 'gradebook_uploads';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import * as waitForProcessing from 'jsx/gradezilla/uploads/wait_for_processing';

const fixtures = document.getElementById('fixtures');

QUnit.module('gradebook_uploads#createGeneralFormatter');

test('formatter returns expected lookup value', function () {
  const formatter = gradebook_uploads.createGeneralFormatter('foo');
  const formatted = formatter(null, null, {foo: 'bar'});
  equal(formatted, 'bar');
});

test('formatter returns empty string when lookup value missing', function () {
  const formatter = gradebook_uploads.createGeneralFormatter('foo');
  const formatted = formatter(null, null, null);
  equal(formatted, '');
});

QUnit.module('gradebook_uploads#handleThingsNeedingToBeResolved', (hooks) => {
  let defaultUploadedGradebook;

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <form id='gradebook_importer_resolution_section'>
        <select name='assignment_-1'>
          <option>73</option>
        </select>
      </form>
      <div id='gradebook_grid'>
        <div id='gradebook_grid_header'></div>
      </div>
      <div id='no_changes_detected' style='display:none;'></div>
    `;

    defaultUploadedGradebook = {
      assignments: [{grading_type: null, id: '-1', points_possible: 10, previous_id: null, title: 'imported'}],
      custom_columns: [],
      missing_objects: {
        assignments: [{grading_type: 'points', id: '73', points_possible: 10, previous_id: null, title: 'existing'}],
        students: []
      },
      original_submissions: [{assignment_id: '73', gradeable: true, score: '', user_id: '1'}],
      students: [{
        id: '1',
        last_name_first: 'Efron, Zac',
        name: 'Zac Efron',
        previous_id: '1',
        submissions: [{assignment_id: '-1', grade: '0.0', gradeable: true, original_grade: null}],
        custom_column_data: [],
      }],
      warning_messages: {
        prevented_grading_ungradeable_submission: false,
        prevented_new_assignment_creation_in_closed_period: false
      }
    };
  });

  hooks.afterEach(() => {
    fixtures.innerHTML = '';
  });

  test('recognizes that there are no changed assignments when the grades are the same', () => {
    const uploadedGradebook = {
      ...defaultUploadedGradebook,
      original_submissions: [{assignment_id: '73', gradeable: true, score: '0.0', user_id: '1'}]
    };
    const waitForProcessingStub = sinon.stub(waitForProcessing, 'waitForProcessing').returns(
      $.Deferred().resolve(uploadedGradebook)
    );

    gradebook_uploads.handleThingsNeedingToBeResolved();
    $('#gradebook_importer_resolution_section').submit();
    strictEqual($('#no_changes_detected:visible').length, 1);

    waitForProcessingStub.restore();
  });

  test('recognizes that there are changed assignments when original grade was ungraded', () => {
    const uploadedGradebook = {
      ...defaultUploadedGradebook,
      original_submissions: [{assignment_id: '73', gradeable: true, score: '', user_id: '1'}]
    };
    const waitForProcessingStub = sinon.stub(waitForProcessing, 'waitForProcessing').returns(
      $.Deferred().resolve(uploadedGradebook)
    );

    gradebook_uploads.handleThingsNeedingToBeResolved();
    $('#gradebook_importer_resolution_section').submit();
    strictEqual($('#no_changes_detected:visible').length, 0);

    waitForProcessingStub.restore();
  });
});

QUnit.module('grade_summary#createNumberFormatter');

test('number formatter returns empty string when value missing', function () {
  const formatter = gradebook_uploads.createNumberFormatter('foo');
  const formatted = formatter(null, null, null);
  equal(formatted, '');
});

test('number formatter delegates to GradeFormatHelper#formatGrade', function () {
  const formatGradeSpy = sandbox.spy(GradeFormatHelper, 'formatGrade');
  const formatter = gradebook_uploads.createNumberFormatter('foo');
  formatter(null, null, {});
  ok(formatGradeSpy.calledOnce);
});
