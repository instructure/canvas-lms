define([
  'lodash',
  'i18n!assignment_categories',
], (_, I18n) => {
  const OTHER = {
    label: I18n.t('Other'),
    id: 'other',
    submissionTypes: [
      '',
    ],
  }

  const Categories = {
    list: [
      {
        label: I18n.t('Assignments'),
        id: 'assignment',
        contentTypeClass: 'assignment',
        submissionTypes: [
          'online_upload',
          'online_text_entry',
          'online_url',
          'on_paper',
          'external_tool',
          'not_graded',
          'media_recording',
          'none',
        ],
      },
      {
        label: I18n.t('Quizzes'),
        id: 'quiz',
        contentTypeClass: 'quiz',
        submissionTypes: [
          'online_quiz',
        ],
      },
      {
        label: I18n.t('Discussions'),
        id: 'discussion',
        contentTypeClass: 'discussion_topic',
        submissionTypes: [
          'discussion_topic',
        ],
      },
      {
        label: I18n.t('Wiki'),
        id: 'document',
        contentTypeClass: 'wiki_page',
        submissionTypes: [
          'wiki_page',
        ],
      },
      OTHER,
    ],
  }

  Categories.getCategory = (assg) => {
    const category = _.find(Categories.list, cat => {
      return assg.submission_types.length &&
             _.find(assg.submission_types, sub => cat.submissionTypes.indexOf(sub) !== -1)
    })
    return category || Categories.OTHER
  }

  return Categories
})
