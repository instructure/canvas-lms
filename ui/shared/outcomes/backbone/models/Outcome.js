/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {map, find, extend as lodashExtend} from 'lodash'
import Backbone from '@canvas/backbone'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'

const I18n = useI18nScope('modelsOutcome')

extend(Outcome, Backbone.Model)

function Outcome() {
  return Outcome.__super__.constructor.apply(this, arguments)
}

Outcome.prototype.defaults = {
  mastery_points: 3,
  points_possible: 5,
  ratings: [
    {
      description: I18n.t('criteria.exceeds_expectations', 'Exceeds Expectations'),
      points: 5,
    },
    {
      description: I18n.t('criteria.meets_expectations', 'Meets Expectations'),
      points: 3,
    },
    {
      description: I18n.t('criteria.does_not_meet_expectations', 'Does Not Meet Expectations'),
      points: 0,
    },
  ],
}

Outcome.prototype.setMasteryScales = function () {
  const ratings = ENV.MASTERY_SCALE.outcome_proficiency.ratings
  return this.set({
    ratings,
    mastery_points: find(
      ratings,
      (function (_this) {
        return function (r) {
          return r.mastery
        }
      })(this)
    ).points,
    // eslint-disable-next-line prefer-spread
    points_possible: Math.max.apply(
      Math,
      map(ratings, function (r) {
        return r.points
      })
    ),
  })
}

Outcome.prototype.defaultCalculationInt = function () {
  return {
    n_mastery: 5,
    weighted_average: 65,
    decaying_average: 65,
    standard_decaying_average: 65,
  }[this.get('calculation_method')]
}

Outcome.prototype.initialize = function () {
  let ref
  if (!this.get('calculation_method')) {
    this.setDefaultCalcSettings()
  }
  if (
    ENV.ACCOUNT_LEVEL_MASTERY_SCALES &&
    ((ref = ENV.MASTERY_SCALE) != null ? ref.outcome_proficiency : void 0)
  ) {
    this.setMasteryScales()
  }
  this.on(
    'change:calculation_method',
    (function (_this) {
      return function (model, _changedTo) {
        return model.set({
          calculation_int: _this.defaultCalculationInt(),
        })
      }
    })(this)
  )
  return Outcome.__super__.initialize.apply(this, arguments)
}

Outcome.prototype.setDefaultCalcSettings = function () {
  let default_calculation_method = 'decaying_average'

  if (ENV.OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION) {
    default_calculation_method = 'weighted_average'
  }

  return this.set({
    calculation_method: default_calculation_method,
    calculation_int: '65',
  })
}

Outcome.prototype.calculationMethodContent = function () {
  return new CalculationMethodContent(this)
}

Outcome.prototype.calculationMethods = function () {
  return this.calculationMethodContent().toJSON()
}

Outcome.prototype.name = function () {
  return this.get('title')
}

Outcome.prototype.canManage = function () {
  return this.get('can_edit') || this.canManageInContext()
}

Outcome.prototype.canManageInContext = function () {
  let ref, ref1
  return (
    ((ref = ENV.ROOT_OUTCOME_GROUP) != null ? ref.context_type : void 0) === 'Course' &&
    ((ref1 = ENV.PERMISSIONS) != null ? ref1.manage_outcomes : void 0) &&
    ENV.current_user_is_admin
  )
}

Outcome.prototype.isNative = function () {
  return (
    this.outcomeLink &&
    this.get('context_id') === this.outcomeLink.context_id &&
    this.get('context_type') === this.outcomeLink.context_type
  )
}

Outcome.prototype.isAbbreviated = function () {
  return !this.has('description')
}

Outcome.prototype.parse = function (resp) {
  if (resp.outcome) {
    this.outcomeLink = resp
    this.outcomeGroup = resp.outcome_group
    return resp.outcome
  } else {
    return resp
  }
}

Outcome.prototype.present = function () {
  return lodashExtend({}, this.toJSON(), this.calculationMethodContent().present())
}

Outcome.prototype.setUrlTo = function (action) {
  return (this.url = function () {
    switch (action) {
      case 'add':
        return this.outcomeGroup.outcomes_url
      case 'edit':
        return this.get('url')
      case 'delete':
        return this.outcomeLink.url
    }
  }.call(this))
}

Outcome.prototype.save = function (_data, _saveOpts) {
  if (ENV.ACCOUNT_LEVEL_MASTERY_SCALES) {
    this.unset('mastery_points')
    this.unset('points_possible')
    this.unset('ratings')
    this.unset('calculation_method')
    this.unset('calculation_int')
  }
  return Outcome.__super__.save.apply(this, arguments)
}

export default Outcome
