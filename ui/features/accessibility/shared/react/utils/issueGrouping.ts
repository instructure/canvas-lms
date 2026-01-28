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

import {IssueRuleType} from '../../../shared/react/types'

type RuleGroup = 'table' | 'alt-text' | 'contrast' | 'links' | 'formatting' | 'headings' | 'unknown'

export const GroupLabelByRuleGroup: Record<RuleGroup, string> = {
  table: 'Table',
  'alt-text': 'Alt text',
  contrast: 'Contrast',
  links: 'Links',
  formatting: 'Formatting',
  headings: 'Headings',
  unknown: 'Unknown',
} as const

export const RuleGroupByRuleType: Record<IssueRuleType, RuleGroup> = {
  'table-caption': 'table',
  'table-header': 'table',
  'table-header-scope': 'table',
  'img-alt': 'alt-text',
  'img-alt-length': 'alt-text',
  'img-alt-filename': 'alt-text',
  'small-text-contrast': 'contrast',
  'large-text-contrast': 'contrast',
  'adjacent-links': 'links',
  'list-structure': 'formatting',
  'headings-sequence': 'headings',
  'headings-start-at-h2': 'headings',
  'paragraphs-for-headings': 'headings',
  'has-lang-entry': 'unknown',
  'link-purpose': 'unknown',
  'link-text': 'unknown',
}

export const RuleLabelByRuleType: Record<IssueRuleType, string> = {
  'table-caption': 'Missing caption',
  'table-header': 'Missing heading',
  'table-header-scope': 'Heading scope missing',
  'img-alt': 'Missing',
  'img-alt-length': 'Too long',
  'img-alt-filename': 'Is filename',
  'small-text-contrast': 'Small text contrast',
  'large-text-contrast': 'Large text contrast',
  'adjacent-links': 'Adjacent',
  'list-structure': 'List',
  'headings-sequence': 'Skipped level',
  'headings-start-at-h2': 'H1 in content',
  'paragraphs-for-headings': 'Too long',
  'has-lang-entry': 'Unknown',
  'link-purpose': 'Unknown',
  'link-text': 'Unknown',
} as const

export function getIssueGrouping(ruleId: IssueRuleType): {
  groupLabel: string
  ruleLabel: string
} {
  return {
    groupLabel: GroupLabelByRuleGroup[RuleGroupByRuleType[ruleId]],
    ruleLabel: RuleLabelByRuleType[ruleId],
  }
}
