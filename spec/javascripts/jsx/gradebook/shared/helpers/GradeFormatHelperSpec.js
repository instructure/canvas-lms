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

import I18n from 'i18n!gradebook'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'

QUnit.module('GradeFormatHelper#formatGrade', {
  setup () {
    this.stub(numberHelper, 'validate').callsFake(val => !isNaN(parseFloat(val)));
  }
});

test('uses I18n#n to format numerical integer grades', function () {
  this.stub(I18n, 'n').withArgs(1000).returns('* 1,000');
  equal(GradeFormatHelper.formatGrade(1000), '* 1,000');
  equal(I18n.n.callCount, 1);
});

test('uses I18n#n to format numerical decimal grades', function () {
  this.stub(I18n, 'n').withArgs(123.45).returns('* 123.45');
  equal(GradeFormatHelper.formatGrade(123.45), '* 123.45');
  equal(I18n.n.callCount, 1);
});

test('uses I18n#t to format completion based grades: complete', function () {
  this.stub(I18n, 't').withArgs('complete').returns('* complete');
  equal(GradeFormatHelper.formatGrade('complete'), '* complete');
  equal(I18n.t.callCount, 1);
});

test('uses I18n#t to format completion based grades: incomplete', function () {
  this.stub(I18n, 't').withArgs('incomplete').returns('* incomplete');
  equal(GradeFormatHelper.formatGrade('incomplete'), '* incomplete');
  equal(I18n.t.callCount, 1);
});

test('parses a stringified integer percentage grade when it is a valid number', function () {
  this.spy(numberHelper, 'parse');
  GradeFormatHelper.formatGrade('32%');
  equal(numberHelper.parse.callCount, 1);
  strictEqual(numberHelper.parse.getCall(0).args[0], '32');
});

test('returns the given grade when it is not a valid number', function () {
  equal(GradeFormatHelper.formatGrade('!32%'), '!32%');
});

test('returns the given grade when it is a letter grade', function () {
  equal(GradeFormatHelper.formatGrade('A'), 'A');
});

test('returns the given grade when it is a mix of letters and numbers', function () {
  equal(GradeFormatHelper.formatGrade('A3'), 'A3');
});

test('returns the given grade when it is numbers followed by letters', function () {
  equal(GradeFormatHelper.formatGrade('1E', { delocalize: false }), '1E');
});

test('does not format letter grades', function () {
  this.spy(I18n, 'n');
  GradeFormatHelper.formatGrade('A');
  equal(I18n.n.callCount, 0, 'I18n.n was not called');
});

test('returns the defaultValue option when grade is undefined', function () {
  equal(GradeFormatHelper.formatGrade(undefined, { defaultValue: 'no grade' }), 'no grade');
});

test('returns the defaultValue option when grade is null', function () {
  equal(GradeFormatHelper.formatGrade(null, { defaultValue: 'no grade' }), 'no grade');
});

test('returns the defaultValue option when grade is an empty string', function () {
  equal(GradeFormatHelper.formatGrade('', { defaultValue: 'no grade' }), 'no grade');
});

test('returns the grade when given undefined and no defaultValue option', function () {
  strictEqual(GradeFormatHelper.formatGrade(undefined), undefined);
});

test('returns the grade when given null and no defaultValue option', function () {
  strictEqual(GradeFormatHelper.formatGrade(null), null);
});

test('returns the grade when given an empty string and no defaultValue option', function () {
  strictEqual(GradeFormatHelper.formatGrade(''), '');
});

test('formats numerical integer grades as percent when given a gradingType of "percent"', function () {
  this.spy(I18n, 'n');
  GradeFormatHelper.formatGrade(10, { gradingType: 'percent' });
  const [value, options] = I18n.n.getCall(0).args;
  strictEqual(value, 10);
  strictEqual(options.percentage, true);
});

test('formats numerical decimal grades as percent when given a gradingType of "percent"', function () {
  this.spy(I18n, 'n');
  GradeFormatHelper.formatGrade(10.1, { gradingType: 'percent' });
  const [value, options] = I18n.n.getCall(0).args;
  strictEqual(value, 10.1);
  strictEqual(options.percentage, true);
});

test('formats string percentage grades as points when given a gradingType of "points"', function () {
  this.spy(I18n, 'n');
  GradeFormatHelper.formatGrade('10%', { gradingType: 'points' });
  const [value, options] = I18n.n.getCall(0).args;
  strictEqual(value, 10);
  strictEqual(options.percentage, false);
});

test('rounds grades to two decimal places', function () {
  equal(GradeFormatHelper.formatGrade(10.321), '10.32');
  equal(GradeFormatHelper.formatGrade(10.325), '10.33');
});

test('optionally rounds to a given precision', function () {
  equal(GradeFormatHelper.formatGrade(10.321, { precision: 3 }), '10.321');
});

test('optionally parses grades as non-localized', function () {
  this.stub(numberHelper, 'parse').withArgs('32.459').returns(32459);
  const formatted = GradeFormatHelper.formatGrade('32.459', { delocalize: false });

  strictEqual(numberHelper.parse.callCount, 0);
  strictEqual(formatted, '32.46');
});

QUnit.module('GradeFormatHelper#delocalizeGrade');

test('returns input value when input is not a string', function () {
  strictEqual(GradeFormatHelper.delocalizeGrade(1), 1);
  ok(isNaN(GradeFormatHelper.delocalizeGrade(NaN)));
  strictEqual(GradeFormatHelper.delocalizeGrade(null), null);
  strictEqual(GradeFormatHelper.delocalizeGrade(undefined), undefined);
  strictEqual(GradeFormatHelper.delocalizeGrade(true), true);
});

test('returns input value when input is not a percent or point value', function () {
  strictEqual(GradeFormatHelper.delocalizeGrade('A+'), 'A+');
  strictEqual(GradeFormatHelper.delocalizeGrade('F'), 'F');
  strictEqual(GradeFormatHelper.delocalizeGrade('Pass'), 'Pass');
});

test('returns non-localized point value when given a point value', function () {
  const sandbox = sinon.sandbox.create();
  sandbox.stub(numberHelper, 'parse').returns(123.45);
  equal(GradeFormatHelper.delocalizeGrade('123,45'), '123.45');
  ok(numberHelper.parse.calledWith('123,45'));
  sandbox.restore();
});

test('returns non-localized percent value when given a percent value', function () {
  const sandbox = sinon.sandbox.create();
  sandbox.stub(numberHelper, 'parse').returns(12.34);
  equal(GradeFormatHelper.delocalizeGrade('12,34%'), '12.34%');
  ok(numberHelper.parse.calledWith('12,34'));
  sandbox.restore();
});

QUnit.module('GradeFormatHelper#parseGrade');

test('parses stringified integer grades', function () {
  strictEqual(GradeFormatHelper.parseGrade('123'), 123);
});

test('parses stringified decimal grades', function () {
  strictEqual(GradeFormatHelper.parseGrade('123.456'), 123.456);
});

test('parses stringified integer percentages', function () {
  strictEqual(GradeFormatHelper.parseGrade('123%'), 123);
});

test('parses stringified decimal percentages', function () {
  strictEqual(GradeFormatHelper.parseGrade('123.456%'), 123.456);
});

test('uses numberHelper.parse to parse a stringified integer grade', function () {
  this.spy(numberHelper, 'parse');
  GradeFormatHelper.parseGrade('123');
  equal(numberHelper.parse.callCount, 1);
});

test('uses numberHelper.parse to parse a stringified decimal grade', function () {
  this.spy(numberHelper, 'parse');
  GradeFormatHelper.parseGrade('123.456');
  equal(numberHelper.parse.callCount, 1);
});

test('uses numberHelper.parse to parse a stringified integer percentage', function () {
  this.spy(numberHelper, 'parse');
  GradeFormatHelper.parseGrade('123%');
  equal(numberHelper.parse.callCount, 1);
});

test('uses numberHelper.parse to parse a stringified decimal percentage', function () {
  this.spy(numberHelper, 'parse');
  GradeFormatHelper.parseGrade('123.456%');
  equal(numberHelper.parse.callCount, 1);
});

test('returns numerical grades without parsing', function () {
  equal(GradeFormatHelper.parseGrade(123.45), 123.45);
});

test('returns letter grades without parsing', function () {
  equal(GradeFormatHelper.parseGrade('A'), 'A');
});

test('returns other string values without parsing', function () {
  equal(GradeFormatHelper.parseGrade('!123'), '!123');
});

test('returns undefined when given undefined', function () {
  strictEqual(GradeFormatHelper.parseGrade(undefined), undefined);
});

test('returns null when given null', function () {
  strictEqual(GradeFormatHelper.parseGrade(null), null);
});

test('returns an empty string when given an empty string', function () {
  strictEqual(GradeFormatHelper.parseGrade(''), '');
});

test('optionally parses grades without delocalizing', function () {
  this.spy(numberHelper, 'parse');
  GradeFormatHelper.parseGrade('123', { delocalize: false });
  equal(numberHelper.parse.callCount, 0);
});

test('parses stringified integer grades without delocalizing', function () {
  strictEqual(GradeFormatHelper.parseGrade('123', { delocalize: false }), 123);
});

test('parses stringified decimal grades without delocalizing', function () {
  strictEqual(GradeFormatHelper.parseGrade('123.456', { delocalize: false }), 123.456);
});

test('parses stringified integer percentages without delocalizing', function () {
  strictEqual(GradeFormatHelper.parseGrade('123%', { delocalize: false }), 123);
});

test('parses stringified decimal percentages without delocalizing', function () {
  strictEqual(GradeFormatHelper.parseGrade('123.456%', { delocalize: false }), 123.456);
});
