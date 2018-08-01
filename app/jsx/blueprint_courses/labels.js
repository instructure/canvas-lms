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

import I18n from 'i18n!blueprint_settings'

const itemTypeLabels = {
  assignment: I18n.t('Assignment'),
  assignment_group: I18n.t('Assignment Group'),
  quiz: I18n.t('Quiz'),
  discussion_topic: I18n.t('Discussion'),
  wiki_page: I18n.t('Page'),
  attachment: I18n.t('File'),
  context_module: I18n.t('Module'),
  announcement: I18n.t('Announcement'),
  assessment_question_bank: I18n.t('Question Bank'),
  calendar_event: I18n.t('Event'),
  learning_outcome: I18n.t('Outcome'),
  learning_outcome_group: I18n.t('Outcome Group'),
  rubric: I18n.t('Rubric'),
  context_external_tool: I18n.t('External Tool'),
  folder: I18n.t('Folder'),
  syllabus: I18n.t('Syllabus')
}

const itemTypeLabelPlurals = {
  assignment: I18n.t('Assignments'),
  quiz: I18n.t('Quizzes'),
  discussion_topic: I18n.t('Discussions'),
  wiki_page: I18n.t('Pages'),
  attachment: I18n.t('Files'),
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
  settings: I18n.t('Settings changed exceptions:'),
  deleted: I18n.t('Deleted content exceptions:')
}

const lockTypeLabel = {
  locked: I18n.t('Locked'),
  unlocked: I18n.t('Unlocked'),
}

const lockLabels = {
  content: I18n.t('Content'),
  points: I18n.t('Points'),
  settings: I18n.t('Settings'),
  due_dates: I18n.t('Due Dates'),
  availability_dates: I18n.t('Availability Dates'),
}

export {itemTypeLabels, changeTypeLabels, exceptionTypeLabels, lockTypeLabel, lockLabels, itemTypeLabelPlurals}
