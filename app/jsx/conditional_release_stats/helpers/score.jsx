define([
  './grading-types',
  'i18n!cyoe_assignment_sidebar',
], (GradingTypes, I18n) => {
  // stack overflow suggests this implementation
  const isNumeric = (n) => {
    return !isNaN(parseFloat(n)) && isFinite(n)
  }

  const haveGradingScheme = (assignment) => {
    return assignment ? !!assignment.grading_scheme : false
  }

  const getGradingType = (assignment) => {
    let type = assignment ? assignment.grading_type : GradingTypes.percent.key
    if ((type === GradingTypes.letter_grade.key || type === GradingTypes.gpa_scale.key) && (!haveGradingScheme(assignment))) {
      return GradingTypes.percent.key
    }
    return type
  }

  const percentToScore = (score, assignment) => {
    const gradingType = getGradingType(assignment)
    if (gradingType === GradingTypes.points.key) {
      return percentToPoints(score, assignment)
    } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
      return percentToLetterGrade(score, assignment)
    } else {
      return percentToExternalPercent(score)
    }
  }

  const transformScore = (score, assignment, isUpperBound) => {
    // The backend stores nil for the upper and lowerbound scoring types
    if (!score) {
      if (isUpperBound) {
        score = '1'
      } else {
        score = '0'
      }
    }
    return formatScore(percentToScore(score, assignment), assignment)
  }

  const formatScore = (score, assignment) => {
    const gradingType = getGradingType(assignment)
    if (gradingType === GradingTypes.points.key) {
      return I18n.t('%{score} pts', { score })
    } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
      return score
    } else {
      return I18n.t('%{score}%', { score })
    }
  }

  const formatReaderOnlyScore = (score, assignment) => {
    const gradingType = getGradingType(assignment)
    if (gradingType === GradingTypes.points.key) {
      return I18n.t('%{score} points', { score })
    } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
      return I18n.t('%{score} letter grade', { score })
    } else {
      return I18n.t('%{score} percent', { score })
    }
  }

  const percentToPoints = (score, assignment) => {
    if (!isNumeric(score)) { return score }
    if (score === 0) { return '0' }
    const percent = parseFloat(score)
    const pointsPossible = Number(assignment.points_possible) || 100
    return Math.ceil(percent * pointsPossible).toString()
  }

  const percentToLetterGrade = (score, assignment) => {
    if (score === '') { return '' }
    const letterGrade = { letter: null, score: -Infinity }
    for (const k in assignment.grading_scheme) {
      const v = parseFloat(assignment.grading_scheme[k])
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
    formatReaderOnlyScore,
  }

  return scoreHelpers
})
