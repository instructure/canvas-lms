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

import {assignIn, isNumber} from 'lodash'

import Outcome from '@canvas/outcomes/backbone/models/Outcome'

import * as tz from '@canvas/datetime'

const I18n = useI18nScope('grade_summaryOutcome')

extend(GradeSummaryOutcome, Outcome)

function GradeSummaryOutcome() {
  return GradeSummaryOutcome.__super__.constructor.apply(this, arguments)
}

GradeSummaryOutcome.prototype.initialize = function () {
  GradeSummaryOutcome.__super__.initialize.apply(this, arguments)
  this.set('friendly_name', this.get('display_name') || this.get('title'))
  this.set('hover_name', this.get('display_name') ? this.get('title') : void 0)
  return this.set('scaled_score', this.scaledScore())
}

GradeSummaryOutcome.prototype.parse = function (response) {
  let ref, ref1
  return GradeSummaryOutcome.__super__.parse.call(
    this,
    assignIn(response, {
      submitted_or_assessed_at: tz.parse(response.submitted_or_assessed_at),
      question_bank_result:
        (ref = response.links) != null
          ? (ref1 = ref.alignment) != null
            ? ref1.includes('assessment_question_bank')
            : void 0
          : void 0,
    })
  )
}

GradeSummaryOutcome.prototype.status = function () {
  let mastery, score
  if (this.scoreDefined()) {
    score = this.score()
    mastery = this.get('mastery_points')
    if (score >= mastery + mastery / 2) {
      return 'exceeds'
    } else if (score >= mastery) {
      return 'mastery'
    } else if (score >= mastery / 2) {
      return 'near'
    } else {
      return 'remedial'
    }
  } else {
    return 'undefined'
  }
}

GradeSummaryOutcome.prototype.statusTooltip = function () {
  return {
    undefined: I18n.t('Unstarted'),
    remedial: I18n.t('Well Below Mastery'),
    near: I18n.t('Near Mastery'),
    mastery: I18n.t('Meets Mastery'),
    exceeds: I18n.t('Exceeds Mastery'),
  }[this.status()]
}

GradeSummaryOutcome.prototype.roundedScore = function () {
  if (this.scoreDefined()) {
    return Math.round(this.score() * 100.0) / 100.0
  } else {
    return null
  }
}

GradeSummaryOutcome.prototype.scoreDefined = function () {
  return isNumber(this.get('score'))
}

GradeSummaryOutcome.prototype.scaledScore = function () {
  const is_aggregate_score = this.get('question_bank_result')
  if (!(this.scoreDefined() && is_aggregate_score)) {
    return
  }
  if (this.get('points_possible') > 0) {
    return this.get('percent') * this.get('points_possible')
  } else {
    return this.get('percent') * this.get('mastery_points')
  }
}

GradeSummaryOutcome.prototype.score = function () {
  return this.get('scaled_score') || this.get('score')
}

GradeSummaryOutcome.prototype.percentProgress = function () {
  if (!this.scoreDefined()) {
    return 0
  }
  if (this.get('percent')) {
    return this.get('percent') * 100
  } else {
    return (this.score() / this.get('points_possible')) * 100
  }
}

GradeSummaryOutcome.prototype.masteryPercent = function () {
  return (this.get('mastery_points') / this.get('points_possible')) * 100
}

GradeSummaryOutcome.prototype.toJSON = function () {
  return assignIn(GradeSummaryOutcome.__super__.toJSON.apply(this, arguments), {
    status: this.status(),
    statusTooltip: this.statusTooltip(),
    roundedScore: this.roundedScore(),
    scoreDefined: this.scoreDefined(),
    percentProgress: this.percentProgress(),
    masteryPercent: this.masteryPercent(),
  })
}

export default GradeSummaryOutcome
