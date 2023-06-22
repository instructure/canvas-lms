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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('blueprint_settings_labels')

const itemTypeLabels = {
  get announcement() {
    return I18n.t('Announcement')
  },
  get assessment_question_bank() {
    return I18n.t('Question Bank')
  },
  get assignment() {
    return I18n.t('Assignment')
  },
  get assignment_group() {
    return I18n.t('Assignment Group')
  },
  get attachment() {
    return I18n.t('File')
  },
  get calendar_event() {
    return I18n.t('Event')
  },
  get context_external_tool() {
    return I18n.t('External Tool')
  },
  get context_module() {
    return I18n.t('Module')
  },
  get course_pace() {
    return I18n.t('Course Pace')
  },
  get discussion_topic() {
    return I18n.t('Discussion')
  },
  get folder() {
    return I18n.t('Folder')
  },
  get learning_outcome() {
    return I18n.t('Outcome')
  },
  get learning_outcome_group() {
    return I18n.t('Outcome Group')
  },
  get media_track() {
    return I18n.t('Caption')
  },
  get quiz() {
    return I18n.t('Quiz')
  },
  get rubric() {
    return I18n.t('Rubric')
  },
  get settings() {
    return I18n.t('Settings')
  },
  get syllabus() {
    return I18n.t('Syllabus')
  },
  get wiki_page() {
    return I18n.t('Page')
  },
}

const itemTypeLabelPlurals = {
  get assignment() {
    return I18n.t('Assignments')
  },
  get attachment() {
    return I18n.t('Files')
  },
  get course_pace() {
    return I18n.t('Course Pace')
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
  },
  get initial_sync() {
    return I18n.t('Initial Sync Incomplete')
  },
}

const exceptionTypeLabels = {
  get availability_dates() {
    return I18n.t('Availability Dates changed exceptions:')
  },
  get content() {
    return I18n.t('Content changed exceptions:')
  },
  get deleted() {
    return I18n.t('Deleted content exceptions:')
  },
  get due_dates() {
    return I18n.t('Due Dates changed exceptions:')
  },
  get points() {
    return I18n.t('Points changed exceptions:')
  },
  get settings() {
    return I18n.t('Settings changed exceptions:')
  },
}

const lockTypeLabel = {
  get locked() {
    return I18n.t('Locked')
  },
  get unlocked() {
    return I18n.t('Unlocked')
  },
}

const lockLabels = {
  get availability_dates() {
    return I18n.t('Availability Dates')
  },
  get content() {
    return I18n.t('Content')
  },
  get due_dates() {
    return I18n.t('Due Dates')
  },
  get points() {
    return I18n.t('Points')
  },
  get settings() {
    return I18n.t('Settings')
  },
}

export {
  itemTypeLabels,
  changeTypeLabels,
  exceptionTypeLabels,
  lockTypeLabel,
  lockLabels,
  itemTypeLabelPlurals,
}
