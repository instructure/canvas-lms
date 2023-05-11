// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Menu} from '@instructure/ui-menu'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item, Separator} = Menu as any

// The following gradebooks use this component as their menu selector,
// so any one of them may be the "active" variant
type ActiveVariant = 'DefaultGradebook' | 'DefaultGradebookLearningMastery' | 'GradebookHistory'

// Individual Gradebook can be selected via this menu, but it uses its own
// component to switch between the different gradebooks instead of this one, and
// so cannot be the current selection
type SelectableVariant = ActiveVariant | 'IndividualGradebook'

type MenuOption = SelectableVariant | 'Separator'

type VariantConfig = {
  readonly href: (baseUrl: string) => string
  readonly key: string
  readonly menuLabel: string
}
type ActiveVariantConfig = VariantConfig & {
  readonly activeLabel: string
  readonly activeOptions: MenuOption[]
}

type VariantMap = {
  [key in SelectableVariant]: VariantConfig | ActiveVariantConfig
}

const variants: VariantMap = {
  DefaultGradebook: {
    activeLabel: I18n.t('Gradebook'),
    activeOptions: [
      'DefaultGradebookLearningMastery',
      'IndividualGradebook',
      'Separator',
      'GradebookHistory',
    ],
    href: courseUrl => `${courseUrl}/gradebook?view=gradebook`,
    key: 'default-gradebook',
    menuLabel: I18n.t('Gradebook…'),
  },
  DefaultGradebookLearningMastery: {
    activeLabel: I18n.t('Learning Mastery Grade Book'),
    activeOptions: ['DefaultGradebook', 'IndividualGradebook', 'Separator', 'GradebookHistory'],
    href: courseUrl => `${courseUrl}/gradebook?view=learning_mastery`,
    key: 'learning-mastery',
    menuLabel: I18n.t('Learning Mastery…'),
  },
  GradebookHistory: {
    activeLabel: I18n.t('Gradebook History'),
    activeOptions: ['DefaultGradebook', 'IndividualGradebook', 'DefaultGradebookLearningMastery'],
    href: courseUrl => `${courseUrl}/gradebook/history`,
    key: 'gradebook-history',
    menuLabel: I18n.t('Gradebook History…'),
  },
  IndividualGradebook: {
    href: courseUrl => `${courseUrl}/gradebook/change_gradebook_version?version=individual`,
    key: 'individual-gradebook',
    menuLabel: I18n.t('Individual Gradebook…'),
  },
}

type Props = {
  courseUrl: string
  learningMasteryEnabled: boolean
  variant: string
}

const GradebookMenu = ({courseUrl, learningMasteryEnabled, variant}: Props) => {
  const selectedItem = variants[variant] as ActiveVariantConfig
  if (selectedItem == null) {
    return null
  }

  const trigger = (
    <Link isWithinText={false} as="button">
      {selectedItem.activeLabel} <IconMiniArrowDownSolid />
    </Link>
  )

  const renderMenuOption = option => (
    <Item href={option.href(courseUrl)} key={option.key}>
      <span data-menu-item-id={option.key}>{option.menuLabel}</span>
    </Item>
  )

  const availableOptions = selectedItem.activeOptions.filter(
    item => item !== 'DefaultGradebookLearningMastery' || learningMasteryEnabled
  )

  return (
    <Menu trigger={trigger}>
      {availableOptions.map(optionId =>
        optionId === 'Separator' ? (
          <Separator key="separator" />
        ) : (
          renderMenuOption(variants[optionId])
        )
      )}
    </Menu>
  )
}

export default GradebookMenu
