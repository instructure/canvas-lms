define([
  'compiled/gradebook2/GradebookTranslations'
  ], function(GRADEBOOK_TRANSLATIONS) {

  const MULTIPLIER = 1.5;

  const isNegativePoints = function(score) {
    return score < 0;
  };

  const isTooManyPoints = function(score, pointsPossible) {
    if (pointsPossible === 0 || pointsPossible == null) { return false; }
    const outlierBoundary = pointsPossible * MULTIPLIER;
    return score >= outlierBoundary;
  };

  class OutlierScoreHelper {
    constructor(score, pointsPossible) {
      this.score = score;
      this.pointsPossible = pointsPossible;
    }

    hasWarning() {
      // mutually exclusive
      return isNegativePoints(this.score) || isTooManyPoints(this.score, this.pointsPossible);
    }

    warningMessage() {
      if (isNegativePoints(this.score)) {
        return GRADEBOOK_TRANSLATIONS.submission_negative_points_warning;
      } else if (isTooManyPoints(this.score, this.pointsPossible)) {
        return GRADEBOOK_TRANSLATIONS.submission_too_many_points_warning;
      } else {
        return null;
      }
    }
  };

  return OutlierScoreHelper;
});
