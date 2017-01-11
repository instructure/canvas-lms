define([
  'jsx/gradebook/shared/helpers/GradeFormatHelper',
  'i18n!gradebook',
  'jsx/shared/helpers/numberHelper'
], function (GradeFormatHelper, I18n, numberHelper) {
  module('GradeFormatHelper#formatGrade', {
    setup () {
      this.stub(numberHelper, 'parse').returns(42);
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
});
