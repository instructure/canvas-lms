import GradingTypes from './grading-types'
import I18n from 'i18n!cyoe_assignment_sidebar'
import numberHelper from 'jsx/shared/helpers/numberHelper'

  // stack overflow suggests this implementation
const isNumeric = (n) => {
  const parsed = numberHelper.parse(n)
  return !isNaN(parsed) && isFinite(parsed)
}

const haveGradingScheme = assignment => assignment ? !!assignment.grading_scheme : false

const getGradingType = (assignment) => {
  const type = assignment ? assignment.grading_type : GradingTypes.percent.key
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
    return I18n.t('%{score} pts', {
      score: I18n.n(score, { precision: 2, strip_insignificant_zeros: true })
    })
  } else if (gradingType === GradingTypes.letter_grade.key || gradingType === GradingTypes.gpa_scale.key) {
    return score
  } else {
    return I18n.n(score, { precision: 2, percentage: true, strip_insignificant_zeros: true })
  }
}

const percentToPoints = (score, assignment) => {
  if (!isNumeric(score)) { return score }
  if (score === 0) { return '0' }
  const percent = numberHelper.parse(score)
  const pointsPossible = Number(assignment.points_possible) || 100
  return Math.ceil(percent * pointsPossible)
}

const percentToLetterGrade = (score, assignment) => {
  if (score === '') { return '' }
  const parsed = numberHelper.parse(score)
  const letterGrade = { letter: null, score: -Infinity }
  for (const k in assignment.grading_scheme) {
    const v = numberHelper.parse(assignment.grading_scheme[k])
    if ((v <= parsed && v > letterGrade.score) || (v === 0 && v > parsed)) {
      letterGrade.score = v
      letterGrade.letter = k
    }
  }
  return letterGrade.letter ? letterGrade.letter : parsed
}

const percentToExternalPercent = (score) => {
  if (!isNumeric(score)) { return score }
  return Math.floor(score * 100)
}

const i18nGrade = (grade, assignment) => {
  if (typeof grade === 'string' &&
        assignment.grading_type !== GradingTypes.letter_grade.key &&
        assignment.grading_type !== GradingTypes.gpa_scale.key) {
    const number = numberHelper.parse(grade.replace(/%$/, ''))
    if (!isNaN(number)) {
      return formatScore(number, assignment)
    }
  }
  return grade
}

const scoreHelpers = {
  transformScore,
  i18nGrade,
}

export default scoreHelpers
