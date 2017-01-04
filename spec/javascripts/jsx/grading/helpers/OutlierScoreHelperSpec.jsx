define([
  'jsx/grading/helpers/OutlierScoreHelper',
  'compiled/gradebook/GradebookTranslations'
], (OutlierScoreHelper, GRADEBOOK_TRANSLATIONS) => {

  module('#hasWarning', () => {
    test('returns true for exacty 1.5 times points possible', () => {
      ok(new OutlierScoreHelper(150, 100).hasWarning());
    });

    test('returns true when above 1.5 times and decimcal is present', () => {
      ok(new OutlierScoreHelper(150.01, 100).hasWarning());
    });

    test('returns true when value is negative', () => {
      ok(new OutlierScoreHelper(-1, 100).hasWarning());
    });

    test('returns false when value is less than 1.5 times', () => {
      notOk(new OutlierScoreHelper(149.99, 100).hasWarning());
    });

    test('returns false for 0 points', () => {
      notOk(new OutlierScoreHelper(0, 100).hasWarning());
    });

    test('returns false for 0 points possible', () => {
      notOk(new OutlierScoreHelper(10, 0).hasWarning());
    });

    test('return false for null score', () => {
      notOk(new OutlierScoreHelper(null, 100).hasWarning());
    });

    test('return false for null points possible', () => {
      notOk(new OutlierScoreHelper(10, null).hasWarning());
    });

    test('return false for NaN score', () => {
      notOk(new OutlierScoreHelper(NaN, 100).hasWarning());
    });

    test('return false for NaN pointsPossible', () => {
      notOk(new OutlierScoreHelper(10, NaN).hasWarning());
    });
  });

  module('#warningMessage', {
    setup() {
      this.tooManyPointsWarning =
        GRADEBOOK_TRANSLATIONS.submission_too_many_points_warning;
      this.negativePointsWarning =
        GRADEBOOK_TRANSLATIONS.submission_negative_points_warning;
    }
  });

  test('positive score outside 1.5 multipler returns too many points warning',
    function() {
    const outlierScore = new OutlierScoreHelper(150, 100);
    equal(outlierScore.warningMessage(), this.tooManyPointsWarning);
  });

  test('negative score returns negative points warning', function() {
    const outlierScore = new OutlierScoreHelper(-1, 100);
    equal(outlierScore.warningMessage(), this.negativePointsWarning);
  });

  test('score within range returns null', function() {
    const outlierScore = new OutlierScoreHelper(100, 100);
    equal(outlierScore.warningMessage(), null);
  });
});
