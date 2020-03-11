/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export default class CourseSettings {
  constructor(gradebook, settings) {
    this._gradebook = gradebook
    this._settings = settings

    this.handleUpdated = this.handleUpdated.bind(this)
  }

  get allowFinalGradeOverride() {
    return this._settings.allowFinalGradeOverride
  }

  setAllowFinalGradeOverride(allow) {
    this._settings.allowFinalGradeOverride = allow
  }

  handleUpdated(settings) {
    const previousSettings = {...this._settings}
    this._settings = {
      ...this._settings,
      ...settings
    }

    if (this._settings.allowFinalGradeOverride !== previousSettings.allowFinalGradeOverride) {
      this._gradebook.updateColumns()

      if (this._settings.allowFinalGradeOverride) {
        this._gradebook.finalGradeOverrides.loadFinalGradeOverrides()
      }
    }
  }
}
