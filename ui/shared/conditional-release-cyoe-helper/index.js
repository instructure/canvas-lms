/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {transformScore} from '@canvas/conditional-release-score'

const I18n = useI18nScope('format_range')

const isEnabled = () => ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED || false
const parseEnvData = () => {
  const activeRules =
    (ENV.CONDITIONAL_RELEASE_ENV && ENV.CONDITIONAL_RELEASE_ENV.active_rules) || []
  return {
    triggerAssignments: activeRules.reduce((triggers, rule) => {
      triggers[rule.trigger_assignment_id] = rule
      return triggers
    }, {}),
    releasedAssignments: activeRules.reduce((released, rule) => {
      rule.scoring_ranges.forEach(range => {
        range.assignment_sets.forEach(set => {
          set.assignment_set_associations.forEach(asg => {
            const id = asg.assignment_id
            released[id] = released[id] || []
            released[id].push({
              assignment_id: rule.trigger_assignment_id,
              assignment: rule.trigger_assignment_model,
              upper_bound: range.upper_bound,
              lower_bound: range.lower_bound,
            })
          })
        })
      })
      return released
    }, {}),
  }
}

let data = parseEnvData()
const isTrigger = asgId => data.triggerAssignments.hasOwnProperty(asgId)
const isReleased = asgId => data.releasedAssignments.hasOwnProperty(asgId)
const formatRange = asgId => {
  const ranges = data.releasedAssignments[asgId] || []
  if (ranges.length > 1) {
    return I18n.t('Multiple')
  } else if (ranges.length > 0) {
    const range = ranges[0]
    return I18n.t('%{upper} - %{lower}', {
      upper: transformScore(range.upper_bound, range.assignment, true),
      lower: transformScore(range.lower_bound, range.assignment, false),
    })
  } else {
    return null
  }
}

export default {
  isEnabled,
  reloadEnv() {
    data = parseEnvData()
  },
  getItemData(asgId, isGraded = true) {
    asgId = asgId && asgId.toString()
    return isEnabled()
      ? {
          isCyoeAble: asgId && isGraded,
          isTrigger: asgId && isGraded && isTrigger(asgId),
          isReleased: isReleased(asgId),
          releasedLabel: formatRange(asgId),
        }
      : {}
  },
}
