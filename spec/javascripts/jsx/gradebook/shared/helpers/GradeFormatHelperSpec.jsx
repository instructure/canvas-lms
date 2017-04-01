define([
  'jsx/gradebook/shared/helpers/GradeFormatHelper',
  'i18n!gradebook',
  'jsx/shared/helpers/numberHelper'
], function (GradeFormatHelper, I18n, numberHelper) {
  QUnit.module('GradeFormatHelper#formatGrade', {
    setup () {
      this.stub(numberHelper, 'parse').returns(42);
      this.stub(numberHelper, 'validate', function (val) {
        return !isNaN(parseFloat(val));
      });
      this.stub(I18n, 'n').returns('42');
    }
  });

  test('should call numberHelper#parse and I18n#n when grade is an integer', () => {
    strictEqual(GradeFormatHelper.formatGrade(1000), '42');
    strictEqual(numberHelper.parse.callCount, 1);
    strictEqual(I18n.n.callCount, 1);
  });

  test('should call numberHelper#parse and I18n#n when grade is a decimal', () => {
    strictEqual(GradeFormatHelper.formatGrade(123.45), '42');
    strictEqual(numberHelper.parse.callCount, 1);
    strictEqual(I18n.n.callCount, 1);
  });

  test('should call numberHelper#parse and I18n#n when grade is an integer percentage', () => {
    strictEqual(GradeFormatHelper.formatGrade('32%'), '42');
    strictEqual(numberHelper.parse.callCount, 1);
    strictEqual(I18n.n.callCount, 1);
  });

  test('should call numberHelper#parse and I18n#n when grade is a decimal percentage', () => {
    strictEqual(GradeFormatHelper.formatGrade('32.45%'), '42');
    strictEqual(numberHelper.parse.callCount, 1);
    strictEqual(I18n.n.callCount, 1);
  });

  test('should not call numberHelper#parse and I18n#n when grade is a letter grade', () => {
    strictEqual(GradeFormatHelper.formatGrade('A'), 'A');
    strictEqual(numberHelper.parse.notCalled, true);
    strictEqual(I18n.n.notCalled, true);
  });

  test('should not call numberHelper#parse and I18n#n when grade is a mix of letters and numbers', () => {
    strictEqual(GradeFormatHelper.formatGrade('A3'), 'A3');
    strictEqual(numberHelper.parse.notCalled, true);
    strictEqual(I18n.n.notCalled, true);
  });

  test('should return input when input is undefined, null, or empty string and no defaultValue is given', () => {
    strictEqual(GradeFormatHelper.formatGrade(undefined), undefined);
    strictEqual(GradeFormatHelper.formatGrade(null), null);
    strictEqual(GradeFormatHelper.formatGrade(''), '');
  });

  test('should return opts.defaultValue when input is undefined, null or empty string', () => {
    const defaultValue = 'use this value when empty';
    strictEqual(GradeFormatHelper.formatGrade(undefined, {defaultValue}), defaultValue);
    strictEqual(GradeFormatHelper.formatGrade(null, {defaultValue}), defaultValue);
    strictEqual(GradeFormatHelper.formatGrade('', {defaultValue}), defaultValue);
  });

  test('should not return opts.defaultValue when input is not undefined, null, or empty', () => {
    const defaultValue = 'use this value when empty';
    notEqual(GradeFormatHelper.formatGrade('123', {defaultValue}), defaultValue);
    notEqual(GradeFormatHelper.formatGrade('12.34', {defaultValue}), defaultValue);
    notEqual(GradeFormatHelper.formatGrade('A', {defaultValue}), defaultValue);
    notEqual(GradeFormatHelper.formatGrade('foo', {defaultValue}), defaultValue);
    notEqual(GradeFormatHelper.formatGrade(' ', {defaultValue}), defaultValue);
  });

  test('providing gradingType in the options hash should override detected grade type', () => {
    GradeFormatHelper.formatGrade(10, { gradingType: 'percent' });
    ok(I18n.n.calledWith(42, { percentage: true }));

    GradeFormatHelper.formatGrade('10%', { gradingType: 'points' });
    ok(I18n.n.calledWith(42, { percentage: false }));

    GradeFormatHelper.formatGrade('10%');
    ok(I18n.n.calledWith(42, { percentage: true }));
  });

  test('providing precision overrides default rounding to two decimal places', () => {
    numberHelper.parse.restore();
    I18n.n.restore();

    let formatted = GradeFormatHelper.formatGrade(10.321);
    strictEqual(formatted, '10.32');

    formatted = GradeFormatHelper.formatGrade(10.325);
    strictEqual(formatted, '10.33');

    formatted = GradeFormatHelper.formatGrade(10.321, { precision: 3 });
    strictEqual(formatted, '10.321');
  });

  QUnit.module('GradeFormatHelper#delocalizeGrade');

  test('should return input value when input is not a string', () => {
    strictEqual(GradeFormatHelper.delocalizeGrade(1), 1);
    ok(isNaN(GradeFormatHelper.delocalizeGrade(NaN)));
    strictEqual(GradeFormatHelper.delocalizeGrade(null), null);
    strictEqual(GradeFormatHelper.delocalizeGrade(undefined), undefined);
    strictEqual(GradeFormatHelper.delocalizeGrade(true), true);
  });

  test('should return input value when input is not a percent or point value', () => {
    strictEqual(GradeFormatHelper.delocalizeGrade('A+'), 'A+');
    strictEqual(GradeFormatHelper.delocalizeGrade('F'), 'F');
    strictEqual(GradeFormatHelper.delocalizeGrade('Pass'), 'Pass');
  });

  test('should return non-localized point value when given a point value', () => {
    const sandbox = sinon.sandbox.create();
    sandbox.stub(numberHelper, 'parse').returns(123.45);
    equal(GradeFormatHelper.delocalizeGrade('123,45'), '123.45');
    ok(numberHelper.parse.calledWith('123,45'));
    sandbox.restore();
  });

  test('should return non-localized percent value when given a percent value', () => {
    const sandbox = sinon.sandbox.create();
    sandbox.stub(numberHelper, 'parse').returns(12.34);
    equal(GradeFormatHelper.delocalizeGrade('12,34%'), '12.34%');
    ok(numberHelper.parse.calledWith('12,34'));
    sandbox.restore();
  });
});
