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
import DueDateOverrideView from 'compiled/views/assignments/DueDateOverride';
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
  const errorBoxSpy = this.spy($.fn, 'errorBox');
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

  this.stub(StudentGroupStore, 'fetchComplete').returns(true);
  this.stub(StudentGroupStore, 'groupsFilteredForSelectedSet').returns([]);
  const errorBoxSpy = this.spy($.fn, 'errorBox');
  const view = new DueDateOverrideView();
  const errs = view.validateGroupOverrides(data, {});
  view.showError(errs.invalidGroupOverride.element, errs.invalidGroupOverride.message)
  strictEqual(errorBoxSpy.calledOnce, true);
});

test('Does not date restrict individual student overrides', function () {
  const data = { assignment_overrides: [{ student_ids: [20], rowKey: '16309' }] };

    this.stub(StudentGroupStore, 'fetchComplete').returns(true);
    this.stub(StudentGroupStore, 'groupsFilteredForSelectedSet').returns([]);
    const errorBoxSpy = this.spy($.fn, 'errorBox');
    const view = new DueDateOverrideView();
    const errs = view.validateGroupOverrides(data, {});
    strictEqual(errs.invalidGroupOverride, undefined);
});
