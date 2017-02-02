/**
 * Copyright (C) 2017 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'gradebook_uploads',
  'jsx/gradebook/shared/helpers/GradeFormatHelper'
], (gradebook_uploads, GradeFormatHelper) => { // eslint-disable-line camelcase
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

  QUnit.module('grade_summary#createNumberFormatter');

  test('number formatter returns empty string when value missing', function () {
    const formatter = gradebook_uploads.createNumberFormatter('foo');
    const formatted = formatter(null, null, null);
    equal(formatted, '');
  });

  test('number formatter delegates to GradeFormatHelper#formatGrade', function () {
    const formatGradeSpy = this.spy(GradeFormatHelper, 'formatGrade');
    const formatter = gradebook_uploads.createNumberFormatter('foo');
    formatter(null, null, {});
    ok(formatGradeSpy.calledOnce);
  });
});
