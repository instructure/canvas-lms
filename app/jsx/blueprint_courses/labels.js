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
  quiz: I18n.t('Quiz'),
  discussion_topic: I18n.t('Discussion'),
  wiki_page: I18n.t('Page'),
  attachment: I18n.t('File'),
  context_module: I18n.t('Module'),
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
  settings: I18n.t('Settings changed exceptions:')
}

const lockTypeLabel = {
  locked: I18n.t('Locked'),
  unlocked: I18n.t('Unlocked')
}

export {itemTypeLabels, changeTypeLabels, exceptionTypeLabels, lockTypeLabel}
