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
import {
  IconImageLine,
  IconLinkLine,
  IconPaintLine,
  IconHeaderLine,
  IconTableTopHeaderLine,
  IconBulletListLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

import {IssueSummaryGroup, IssueRuleType} from '../../shared/react/types'

const I18n = createI18nScope('accessibility_checker')

export const IssueSummaryGroups: IssueSummaryGroup[] = [
  'headings',
  'links',
  'img-alt-text',
  'tables',
  'lists',
  'low-contrast',
]

export const IssueSummaryGroupData: Record<
  IssueSummaryGroup,
  {icon: React.ComponentType; label: string; ruleTypes: IssueRuleType[]}
> = {
  headings: {
    icon: IconHeaderLine,
    label: I18n.t('Headings'),
    ruleTypes: ['headings-sequence', 'headings-start-at-h2'],
  },
  links: {
    icon: IconLinkLine,
    label: I18n.t('Links'),
    ruleTypes: ['link-text', 'link-purpose'],
  },
  'img-alt-text': {
    icon: IconImageLine,
    label: I18n.t('Image alt text'),
    ruleTypes: ['img-alt', 'img-alt-length', 'img-alt-filename'],
  },
  tables: {
    icon: IconTableTopHeaderLine,
    label: I18n.t('Tables'),
    ruleTypes: ['table-header-scope', 'table-header', 'table-caption'],
  },
  lists: {
    icon: IconBulletListLine,
    label: I18n.t('Lists'),
    ruleTypes: ['list-structure'],
  },
  'low-contrast': {
    icon: IconPaintLine,
    label: I18n.t('Low contrast'),
    ruleTypes: ['small-text-contrast', 'large-text-contrast'],
  },
}
