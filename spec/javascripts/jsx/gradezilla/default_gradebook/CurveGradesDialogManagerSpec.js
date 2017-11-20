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

define([
  'jquery',
  'compiled/shared/CurveGradesDialog',
  'jsx/gradezilla/default_gradebook/CurveGradesDialogManager',
  'i18n!gradebook',
  'compiled/jquery.rails_flash_notifications'
], ($, CurveGradesDialog, { createCurveGradesAction }, I18n) => {
  QUnit.module('CurveGradesDialogManager.createCurveGradesAction.isDisabled', {
    props ({points_possible, grading_type, submissionsLoaded}) {
      return [
        { // assignment
          points_possible,
          grading_type
        },
        [], // students
        {
          isAdmin: false,
          contextUrl: 'http://contextUrl/',
          submissionsLoaded
        }
      ];
    }
  });

  test('is not disabled when submissions are loaded, grading type is not pass/fail and there are ' +
    'points that are not 0', function () {
    const props = this.props({points_possible: 10, grading_type: 'points', submissionsLoaded: true});
    notOk(createCurveGradesAction(...props).isDisabled);
  });

  test('is disabled when submissions are not loaded', function () {
    const props = this.props({points_possible: 10, grading_type: 'points', submissionsLoaded: false });
    ok(createCurveGradesAction(...props).isDisabled);
  });

  test('is disabled when grading type is pass/fail', function () {
    const props = this.props({points_possible: 10, grading_type: 'pass_fail', submissionsLoaded: true });
    ok(createCurveGradesAction(...props).isDisabled);
  });

  test('returns true when points_possible is null', function () {
    const props = this.props({points_possible: null, grading_type: 'points', submissionsLoaded: true});
    ok(createCurveGradesAction(...props).isDisabled);
  });

  test('returns true when points_possible is 0', function () {
    const props = this.props({points_possible: 0, grading_type: 'points', submissionsLoaded: true});
    ok(createCurveGradesAction(...props).isDisabled);
  });

  QUnit.module('CurveGradesDialogManager.createCurveGradesAction.onSelect', {
    setup () {
      this.flashErrorSpy = this.spy($, 'flashError');
      this.stub(CurveGradesDialog.prototype, 'show');
    },
    onSelect ({ isAdmin = false, inClosedGradingPeriod = false } = {}) {
      createCurveGradesAction({ inClosedGradingPeriod }, [], isAdmin, 'http://contextUrl/', true).onSelect()
    },
    props ({ inClosedGradingPeriod = false, isAdmin = false } = {}) {
      return [
        { // assignment
          inClosedGradingPeriod
        },
        [], // students
        {
          isAdmin,
          contextUrl: 'http://contextUrl/',
          submissionsLoaded: true
        }
      ];
    }
  });

  test('calls flashError if is not admin and in a closed grading period', function () {
    const props = this.props({ isAdmin: false, inClosedGradingPeriod: true });
    createCurveGradesAction(...props).onSelect();
    ok(this.flashErrorSpy.withArgs(I18n.t('Unable to curve grades because this assignment is due in a closed ' +
      'grading period for at least one student')).calledOnce);
  });

  test('does not call curve grades dialog if is not admin and in a closed grading period', function () {
    const props = this.props({ isAdmin: false, inClosedGradingPeriod: true });
    createCurveGradesAction(...props).onSelect();
    strictEqual(CurveGradesDialog.prototype.show.callCount, 0);
  });

  test('does not call flashError if is admin and in a closed grading period', function () {
    const props = this.props({ isAdmin: true, inClosedGradingPeriod: true });
    createCurveGradesAction(...props).onSelect();
    ok(this.flashErrorSpy.notCalled);
  });

  test('calls curve grades dialog if is admin and in a closed grading period', function () {
    const props = this.props({ isAdmin: true, inClosedGradingPeriod: true });
    createCurveGradesAction(...props).onSelect();
    strictEqual(CurveGradesDialog.prototype.show.callCount, 1);
  });

  test('does not call flashError if is not admin and not in a closed grading period', function () {
    const props = this.props({ isAdmin: false, inClosedGradingPeriod: false });
    createCurveGradesAction(...props).onSelect();
    ok(this.flashErrorSpy.notCalled);
  });

  test('calls curve grades dialog if is not admin and not in a closed grading period', function () {
    const props = this.props({ isAdmin: false, inClosedGradingPeriod: false });
    createCurveGradesAction(...props).onSelect();
    strictEqual(CurveGradesDialog.prototype.show.callCount, 1);
  });

  test('does not call flashError if is admin and not in a closed grading period', function () {
    const props = this.props({ isAdmin: true, inClosedGradingPeriod: false });
    createCurveGradesAction(...props).onSelect();
    ok(this.flashErrorSpy.notCalled);
  });

  test('calls curve grades dialog if is admin and not in a closed grading period', function () {
    const props = this.props({ isAdmin: true, inClosedGradingPeriod: false });
    createCurveGradesAction(...props).onSelect();
    strictEqual(CurveGradesDialog.prototype.show.callCount, 1);
  });
});
