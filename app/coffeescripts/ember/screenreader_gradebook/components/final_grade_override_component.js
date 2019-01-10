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
import {scoreToGrade} from 'jsx/gradebook/GradingSchemeHelper'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'

const FinalGradeOverrideComponent = Ember.Component.extend({
  overrideGrade: function() {
    const percentage = this.get('finalGradeOverrides.percentage')
    const gradingStandard = this.get('gradingStandard')

    if (percentage == null) {
      return null
    } else if (!gradingStandard) {
      return GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'})
    }

    return scoreToGrade(percentage, gradingStandard)
  }.property('finalGradeOverrides'),

  overridePercent: function() {
    const percentage = this.get('finalGradeOverrides.percentage')
    const gradingStandard = this.get('gradingStandard')

    if (percentage == null || !gradingStandard) {
      return null
    }
    return GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'})
  }.property('finalGradeOverrides')
})

export default FinalGradeOverrideComponent
