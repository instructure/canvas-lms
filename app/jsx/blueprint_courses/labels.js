import I18n from 'i18n!blueprint_settings'

const itemTypeLabels = {
  assignment: I18n.t('Assignment'),
  quiz: I18n.t('Quiz'),
  discussion_topic: I18n.t('Discussion'),
  wiki_page: I18n.t('Page'),
  attachment: I18n.t('File'),
}

const changeTypeLabels = {
  created: I18n.t('Created'),
  updated: I18n.t('Updated'),
  deleted: I18n.t('Deleted'),
}

const exceptionTypeLabels = {
  points: I18n.t('Points changed exceptions:'),
  content: I18n.t('Content changed exceptions:'),
  due_dates: I18n.t('Due Dates changed exceptions:'),
  availability_dates: I18n.t('Availability Dates changed exceptions:'),
}

const lockTypeLabel = {
  locked: I18n.t('Locked'),
  unlocked: I18n.t('Unlocked')
}

export {itemTypeLabels, changeTypeLabels, exceptionTypeLabels, lockTypeLabel}
