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
import DateValidator from 'compiled/util/DateValidator';
import DueDateOverrideView from 'compiled/views/assignments/DueDateOverride';
import fakeENV from 'helpers/fakeENV'
import StudentGroupStore from 'jsx/due_dates/StudentGroupStore';
import 'jquery.instructure_forms';  // errorBox

QUnit.module('DueDateOverride#validateTokenInput', {
  setup () {
    this.fixtures = document.getElementById('fixtures');
    this.fixtures.innerHTML = `
      <div data-row-key="01" class="Container__DueDateRow-item">
        <div data-row-identifier="tokenInputFor01">
          <input />
        </div>
      </div>
    `;
  },
  teardown () {
    this.fixtures.innerHTML = '';
  }
});

test('rowKey can be prefixed with a zero', function () {
  const errorBoxSpy = sandbox.spy($.fn, 'errorBox');
  const view = new DueDateOverrideView();
  const errs = view.validateTokenInput({}, {});
  view.showError(errs.blankOverrides.element, errs.blankOverrides.message)
  strictEqual(errorBoxSpy.calledOnce, true);
});

QUnit.module('DueDateOverride#validateGroupOverrides', {
  setup () {
    this.fixtures = document.getElementById('fixtures');
    this.fixtures.innerHTML = `
      <div data-row-key="01" class="Container__DueDateRow-item">
        <div data-row-identifier="tokenInputFor01">
          <input />
        </div>
      </div>
    `;
  },
  teardown () {
    this.fixtures.innerHTML = '';
  }
});

test('rowKey can be prefixed with a zero', function () {
  const data = { assignment_overrides: [{ group_id: '42', rowKey: '01' }] };

  sandbox.stub(StudentGroupStore, 'fetchComplete').returns(true);
  sandbox.stub(StudentGroupStore, 'groupsFilteredForSelectedSet').returns([]);
  const errorBoxSpy = sandbox.spy($.fn, 'errorBox');
  const view = new DueDateOverrideView();
  const errs = view.validateGroupOverrides(data, {});
  view.showError(errs.invalidGroupOverride.element, errs.invalidGroupOverride.message)
  strictEqual(errorBoxSpy.calledOnce, true);
});

test('Does not date restrict individual student overrides', function () {
  const data = { assignment_overrides: [{ student_ids: [20], rowKey: '16309' }] };

    sandbox.stub(StudentGroupStore, 'fetchComplete').returns(true);
    sandbox.stub(StudentGroupStore, 'groupsFilteredForSelectedSet').returns([]);
    const errorBoxSpy = sandbox.spy($.fn, 'errorBox');
    const view = new DueDateOverrideView();
    const errs = view.validateGroupOverrides(data, {});
    strictEqual(errs.invalidGroupOverride, undefined);
});

QUnit.module('DueDateOverride#validateDatetimes', () => {
  test('skips overrides whose row key has already been validated', () => {
    const overrides = [
      { rowKey: '1', student_ids: [1] },
      { rowKey: '1', student_ids: [1] }
    ]
    const data = { assignment_overrides: overrides }

    const validateSpy = sinon.spy(DateValidator.prototype, 'validateDatetimes')
    const view = new DueDateOverrideView()
    sinon.stub(view, 'postToSIS').returns(false)

    view.validateDatetimes(data, {})

    strictEqual(validateSpy.callCount, 1)
    validateSpy.restore()
  })

  QUnit.module('when a valid date range is specified', (hooks) => {
    hooks.beforeEach(() => {
      const start_at = {
        date: new Date('Nov 10, 2018').toISOString(),
        date_context: 'course'
      }
      const end_at = {
        date: new Date('Nov 20, 2018').toISOString(),
        date_context: 'course'
      }

      fakeENV.setup({
        VALID_DATE_RANGE: {start_at, end_at}
      })
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
    })

    test('allows dates for individual students to fall outside of the specified date range', () => {
      const dueDate = new Date('Nov 30, 2018').toISOString()
      const overrides = [
        { rowKey: '1', student_ids: [1], due_at: dueDate }
      ]
      const data = { assignment_overrides: overrides }

      const view = new DueDateOverrideView()
      sinon.stub(view, 'postToSIS').returns(false)

      const errors = view.validateDatetimes(data, {})
      strictEqual(Object.keys(errors).length, 0)
    })

    test('requires non-individual-student overrides to be within specified date range', () => {
      const dueDate = new Date('Nov 30, 2018').toISOString()
      const overrides = [
        { rowKey: '1', course_section_id: '1', due_at: dueDate }
      ]
      const data = { assignment_overrides: overrides }

      const view = new DueDateOverrideView()
      sinon.stub(view, 'postToSIS').returns(false)

      const errors = view.validateDatetimes(data, {})
      strictEqual(errors.due_at.message, 'Due date cannot be after course end')
    })
  })
})
