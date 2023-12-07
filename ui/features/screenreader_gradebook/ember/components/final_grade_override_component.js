/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Ember from 'ember'
import {scoreToGrade} from '@instructure/grading-utils'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const FinalGradeOverrideComponent = Ember.Component.extend({
  inputValue: null,
  internalInputValue: null,

  inputDescription: function () {
    const percentage = this.get('finalGradeOverride.percentage')
    const gradingStandard = this.get('gradingStandard')

    if (percentage == null || !gradingStandard) {
      return null
    }
    if (gradingStandard) {
      if (this.get('gradingStandardPointsBased')) {
        // points based grading schemes never show percentages
        return null
      }
    }
    return GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'})
  }.property('finalGradeOverride', 'gradingStandard', 'gradingStandardPointsBased'),

  finalGradeOverrideChanged: function () {
    const percentage = this.get('finalGradeOverride.percentage')
    const gradingStandard = this.get('gradingStandard')

    if (percentage == null) {
      this.set('internalInputValue', null)
    } else if (!gradingStandard) {
      this.set(
        'internalInputValue',
        GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'})
      )
    } else {
      this.set('internalInputValue', scoreToGrade(percentage, gradingStandard))
    }

    this.set('inputValue', this.get('internalInputValue'))
  }
    .observes('finalGradeOverride', 'gradingStandard')
    .on('init'),

  focusOut() {
    this.sendAction('onEditFinalGradeOverride', this.get('inputValue'))
    // Always show a valid grade in the input on blur.
    this.set('inputValue', this.get('internalInputValue'))
  },
})

export default FinalGradeOverrideComponent
