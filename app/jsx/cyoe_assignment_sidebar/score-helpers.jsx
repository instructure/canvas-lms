define([
  './grading-types',
  'i18n!cyoe_assignment_sidebar'
  ], (GradingTypes, I18n)=> {

  // stack overflow suggests this implementation
  const isNumeric = (n) => {
    return !isNaN(parseFloat(n)) && isFinite(n)
  }

  const percentToScore = (score, assignment) => {
    const gradingType = assignment ? assignment['grading_type'] : GradingTypes.percent.key
    if (gradingType === GradingTypes.points.key) {
      return percentToPoints(score, assignment)
    } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
      return percentToLetterGrade(score, assignment)
    } else if (gradingType === GradingTypes.percent.key) {
      return percentToExternalPercent(score)
    } else {
      return score
    }
  }

  const transformScore = (score, assignment, isUpperBound) => {
    // The backend stores nil for the upper and lowerbound scoring types
    if (!score) {
      if (isUpperBound) {
        score = score || '1.0'
      } else {
        score = score || '0'
      }
    }
    return formatScore(percentToScore(score, assignment), assignment)
  }

  const formatScore = (score, assignment) => {
    const gradingType = assignment ? assignment['grading_type'] : GradingTypes.percent.key
    if (gradingType === GradingTypes.points.key) {
      return I18n.t('%{score} pts', { score })
    } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
      return score
    } else if (gradingType === GradingTypes.percent.key) {
      return I18n.t('%{score}%', { score })
    } else {
      return score
    }
  }

  const formatReaderOnlyScore = (score, assignment) => {
    const gradingType = assignment ? assignment['grading_type'] : GradingTypes.percent.key
    if (gradingType === GradingTypes.points.key) {
      return I18n.t('%{score} points', { score })
    } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
      return I18n.t('%{score} letter grade', { score })
    } else if (gradingType === GradingTypes.percent.key) {
      return I18n.t('%{score} percent', { score })
    } else {
      return score
    }
  }

  const percentToPoints = (score, assignment) => {
    if (!assignment['points_possible']) { return '0' }
    if (score === 0) { return '0' }
    if (!isNumeric(score)) { return score }
    const percent = parseFloat(score)
    return Math.ceil(percent * assignment['points_possible']).toString()
  }

  const percentToLetterGrade = (score, assignment) => {
    if (score === '') { return '' }
    const letterGrade = { letter: null, score: -Infinity }
    const gradingScheme = assignment['grading_scheme']
    for(let k in gradingScheme){
      const v = parseFloat(gradingScheme[k])
      if ((v <= score && v > letterGrade.score) || (v === 0 && v > score)) {
        letterGrade.score = v
        letterGrade.letter = k
      }
    }

    return letterGrade.letter ? letterGrade.letter : score
  }

  const percentToExternalPercent = (score) => {
    if (!isNumeric(score)) { return score }
    return Math.floor(score * 100).toString()
  }

  const scoreHelpers = {
    percentToScore,
    transformScore,
    formatReaderOnlyScore
  }
  return scoreHelpers

})