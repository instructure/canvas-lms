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

import {IssueSummaryGroupData} from '../constants'
import {IssueSummaryGroup, IssueRuleType} from '../../../shared/react/types'

const getGroupByRuleTypeMapping = (): Record<IssueRuleType, IssueSummaryGroup> => {
  const lookup = {} as Record<IssueRuleType, IssueSummaryGroup>

  Object.entries(IssueSummaryGroupData).forEach(([category, {ruleTypes}]) => {
    ruleTypes.forEach(ruleType => {
      lookup[ruleType] = category as IssueSummaryGroup
    })
  })

  return lookup
}

const GroupByRuleType = getGroupByRuleTypeMapping()

export const getGroupedIssueSummaryData = (
  issuesByRuleType: Record<string, number>,
): Record<IssueSummaryGroup, number> => {
  const groupedIssueSummaryData = {} as Record<IssueSummaryGroup, number>

  Object.keys(IssueSummaryGroupData).forEach(group => {
    groupedIssueSummaryData[group as IssueSummaryGroup] = 0
  })

  Object.entries(issuesByRuleType).forEach(([ruleType, count]) => {
    const group = GroupByRuleType[ruleType as IssueRuleType]

    if (group) {
      groupedIssueSummaryData[group] += count
    }
  })

  return groupedIssueSummaryData
}
