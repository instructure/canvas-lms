/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!blueprint_settings_labels'

const itemTypeLabels = {
  get assignment() {
    return I18n.t('Assignment')
  },
  get assignment_group() {
    return I18n.t('Assignment Group')
  },
  get quiz() {
    return I18n.t('Quiz')
  },
  get discussion_topic() {
    return I18n.t('Discussion')
  },
  get wiki_page() {
    return I18n.t('Page')
  },
  get attachment() {
    return I18n.t('File')
  },
  get context_module() {
    return I18n.t('Module')
  },
  get announcement() {
    return I18n.t('Announcement')
  },
  get assessment_question_bank() {
    return I18n.t('Question Bank')
  },
  get calendar_event() {
    return I18n.t('Event')
  },
  get learning_outcome() {
    return I18n.t('Outcome')
  },
  get learning_outcome_group() {
    return I18n.t('Outcome Group')
  },
  get rubric() {
    return I18n.t('Rubric')
  },
  get context_external_tool() {
    return I18n.t('External Tool')
  },
  get folder() {
    return I18n.t('Folder')
  },
  get syllabus() {
    return I18n.t('Syllabus')
  },
  get settings() {
    return I18n.t('Settings')
  }
}

const itemTypeLabelPlurals = {
  get assignment() {
    return I18n.t('Assignments')
  },
  get quiz() {
    return I18n.t('Quizzes')
  },
  get discussion_topic() {
    return I18n.t('Discussions')
  },
  get wiki_page() {
    return I18n.t('Pages')
  },
  get attachment() {
    return I18n.t('Files')
  }
}

const changeTypeLabels = {
  get created() {
    return I18n.t('Created')
  },
  get updated() {
    return I18n.t('Updated')
  },
  get deleted() {
    return I18n.t('Deleted')
  }
}

const exceptionTypeLabels = {
  get points() {
    return I18n.t('Points changed exceptions:')
  },
  get content() {
    return I18n.t('Content changed exceptions:')
  },
  get due_dates() {
    return I18n.t('Due Dates changed exceptions:')
  },
  get availability_dates() {
    return I18n.t('Availability Dates changed exceptions:')
  },
  get settings() {
    return I18n.t('Settings changed exceptions:')
  },
  get deleted() {
    return I18n.t('Deleted content exceptions:')
  }
}

const lockTypeLabel = {
  get locked() {
    return I18n.t('Locked')
  },
  get unlocked() {
    return I18n.t('Unlocked')
  }
}

const lockLabels = {
  get content() {
    return I18n.t('Content')
  },
  get points() {
    return I18n.t('Points')
  },
  get settings() {
    return I18n.t('Settings')
  },
  get due_dates() {
    return I18n.t('Due Dates')
  },
  get availability_dates() {
    return I18n.t('Availability Dates')
  }
}

export {
  itemTypeLabels,
  changeTypeLabels,
  exceptionTypeLabels,
  lockTypeLabel,
  lockLabels,
  itemTypeLabelPlurals
}
