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

import I18n from 'i18n!rubrics'

const confirmationMessage = () => {
  if (ENV.context_asset_string.includes('course')) {
    return I18n.t("Are you sure you want to delete this rubric? This action will remove this rubric association from all assignments in the current course, and delete any existing associated assessments.")
  }
  else {
    return I18n.t("Are you sure you want to delete this rubric? Any course currently associated with this rubric will still have access to it, but no new courses will be able to use it.")
  }
}

export default confirmationMessage