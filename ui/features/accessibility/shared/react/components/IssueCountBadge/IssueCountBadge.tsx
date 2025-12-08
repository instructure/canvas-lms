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

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Badge, BadgeProps} from '@instructure/ui-badge'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

const DEFAULT_MAX_COUNT = 100

const badgeThemeOverride: BadgeProps['themeOverride'] = (_componentTheme, currentTheme) => ({
  colorDanger: currentTheme.colors.primitives.orange45,
  fontWeight: 700,
  padding: '0.5rem',
  fontSize: '1rem',
  size: '1.375rem',
})

export const formatBadgeOutput = (formattedCount: string) => {
  const altText =
    formattedCount === '1' ? I18n.t('1 Issue') : I18n.t('%{count} Issues', {count: formattedCount})

  return (
    <AccessibleContent alt={altText} data-testid="issue-count-badge">
      {formattedCount}
    </AccessibleContent>
  )
}

export const IssueCountBadge = ({
  issueCount,
  maxCount = DEFAULT_MAX_COUNT,
}: {
  issueCount: number
  maxCount?: number
}) => {
  return (
    <Badge
      standalone
      variant="danger"
      countUntil={maxCount}
      themeOverride={badgeThemeOverride}
      count={issueCount}
      formatOverflowText={(_count: number, countUntil: number) => `${countUntil - 1}+`}
      formatOutput={formatBadgeOutput}
    />
  )
}
