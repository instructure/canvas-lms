import I18n from 'i18n!cyoe_assignment_sidebar'

  const GradingTypes = {
    points: {
      label: I18n.t('points'),
      key: 'points',
    },
    percent: {
      label: I18n.t('percent'),
      key: 'percent',
    },
    letter_grade: {
      label: I18n.t('letter grade'),
      key: 'letter_grade',
    },
    gpa_scale: {
      label: I18n.t('GPA scale'),
      key: 'gpa_scale',
    },
    other: {
      label: I18n.t('other'),
      key: 'other',
    },
  }

export default GradingTypes
