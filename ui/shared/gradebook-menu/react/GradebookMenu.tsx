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

import React, {useState} from 'react'
import {
  IconArrowOpenDownSolid,
  IconMiniArrowDownSolid,
  IconArrowOpenUpSolid,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

// Doing this to avoid TS2339 errors. Remove once we're on InstUI 8
const {Group, Item, Separator} = Menu as any

export type GradiantVariantName =
  | 'DefaultGradebook'
  | 'DefaultGradebookLearningMastery'
  | 'GradebookHistory'
  | 'IndividualGradebook'
  | 'EnhancedIndividualGradebook'

const activeLabels = {
  DefaultGradebook: I18n.t('Gradebook'),
  DefaultGradebookLearningMastery: I18n.t('Learning Mastery Gradebook'),
  GradebookHistory: I18n.t('Gradebook History'),
  IndividualGradebook: I18n.t('Individual Gradebook'),
  EnhancedIndividualGradebook: I18n.t('Individual Gradebook'),
}

type Props = {
  courseUrl: string
  learningMasteryEnabled?: boolean
  enhancedIndividualGradebookEnabled?: boolean
  variant: GradiantVariantName
  customTrigger?: any
}

export default function GradebookMenu({
  courseUrl,
  learningMasteryEnabled,
  enhancedIndividualGradebookEnabled,
  variant,
  customTrigger,
}: Props) {
  const [toggleGradebookMenu, setToggleGradebookMenu] = useState(false)

  const handleRenderArrowIcon = () => {
    setToggleGradebookMenu(!toggleGradebookMenu)
  }

  const getMenuTrigger = () => {
    // EVAL-3711 Remove Evaluate ICE feature flag
    const trigger = window.ENV.FEATURES.instui_nav ? (
      <IconButton
        size="small"
        margin="0 0 0 x-small"
        withBorder={false}
        withBackground={false}
        screenReaderLabel={I18n.t('Gradebook Menu Dropdown')}
        data-testid="gradebook-select-dropdown"
      >
        {toggleGradebookMenu ? <IconArrowOpenUpSolid /> : <IconArrowOpenDownSolid />}
      </IconButton>
    ) : (
      <Link isWithinText={false} as="button" data-testid="gradebook-select-dropdown">
        {activeLabels[variant]} <IconMiniArrowDownSolid />
      </Link>
    )
    return customTrigger || trigger
  }

  const menuTrigger = getMenuTrigger()

  return (
    <>
      <Flex>
        {/* EVAL-3711 Remove Evaluate ICE feature flag */}
        {window.ENV.FEATURES.instui_nav && (
          <Heading
            level="h1"
            data-testid="gradebook-title"
            margin="0"
            themeOverride={{h1FontWeight: 700, lineHeight: 1.05}}
          >
            {activeLabels[variant]}
          </Heading>
        )}
        {/* EVAL-3711 Remove Evaluate ICE feature flag */}
        <Menu
          trigger={menuTrigger}
          onToggle={window.ENV.FEATURES.instui_nav ? handleRenderArrowIcon : undefined}
        >
          <Group selected={[variant]} onSelect={() => {}} label={I18n.t('Change Gradebook view')}>
            <Item
              href={`${courseUrl}/gradebook/change_gradebook_version?version=gradebook`}
              value="DefaultGradebook"
            >
              <span
                data-menu-item-id="default-gradebook"
                data-testid="default-gradebook-menu-option"
              >
                {I18n.t('Traditional Gradebook')}
              </span>
            </Item>

            {learningMasteryEnabled && (
              <Item
                href={`${courseUrl}/gradebook?view=learning_mastery`}
                value="DefaultGradebookLearningMastery"
              >
                <span data-menu-item-id="learning-mastery">
                  {I18n.t('Learning Mastery Gradebook')}
                </span>
              </Item>
            )}

            {enhancedIndividualGradebookEnabled ? (
              <Item
                href={`${courseUrl}/gradebook/change_gradebook_version?version=individual_enhanced`}
                value="EnhancedIndividualGradebook"
              >
                <span data-menu-item-id="individual-gradebook">
                  {I18n.t('Individual Gradebook')}
                </span>
              </Item>
            ) : (
              <Item
                href={`${courseUrl}/gradebook/change_gradebook_version?version=individual`}
                value="IndividualGradebook"
              >
                <span data-menu-item-id="individual-gradebook">
                  {I18n.t('Individual Gradebook')}
                </span>
              </Item>
            )}

            <Separator key="separator" />

            <Item href={`${courseUrl}/gradebook/history`} value="GradebookHistory">
              <span data-menu-item-id="gradebook-history">{I18n.t('Gradebook History')}</span>
            </Item>
          </Group>
        </Menu>
      </Flex>
    </>
  )
}
