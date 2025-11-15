/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('nutrition_facts')

export const ICON_COLORS = {primary: '#273540', secondary: '#FFFFFF'}

export const STATIC_TEXT = {
  title: '',
  dataPermissionLevelsTitle: I18n.t('Data Permission Levels'),
  dataPermissionLevelsCurrentFeatureText: I18n.t('Current Feature:'),
  dataPermissionLevelsCloseIconButtonScreenReaderLabel: I18n.t('Close'),
  dataPermissionLevelsCloseButtonText: I18n.t('Close'),
  dataPermissionLevelsModalLabel: I18n.t('This is a Data Permission Levels modal'),
  dataPermissionLevelsTriggerText: I18n.t('Data Permission Levels'),
  nutritionFactsModalLabel: I18n.t('This is a modal for AI facts'),
  nutritionFactsTitle: I18n.t('Nutrition Facts'),
  nutritionFactsCloseButtonText: I18n.t('Close'),
  nutritionFactsCloseIconButtonScreenReaderLabel: I18n.t('Close'),
  nutritionFactsTriggerText: I18n.t('Nutrition Facts'),
}
