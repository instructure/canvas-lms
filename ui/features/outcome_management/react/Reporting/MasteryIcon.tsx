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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Img} from '@instructure/ui-img'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import type {MasteryLevel} from './types'
import type {MasteryLevelResult} from '@canvas/outcomes/react/utils/icons'
import {colors} from '@instructure/canvas-theme'

const I18n = createI18nScope('outcome_management')

interface MasteryIconProps {
  masteryLevel: MasteryLevelResult
  description?: string
}

const masteryLevelToIcon: Record<MasteryLevel, {url: string; alt: string}> = {
  mastery: {
    url: '/images/outcomes/mastery.svg',
    alt: I18n.t('Mastery'),
  },
  near_mastery: {
    url: '/images/outcomes/near_mastery.svg',
    alt: I18n.t('Near Mastery'),
  },
  exceeds_mastery: {
    url: '/images/outcomes/exceeds_mastery.svg',
    alt: I18n.t('Exceeds Mastery'),
  },
  remediation: {
    url: '/images/outcomes/remediation.svg',
    alt: I18n.t('Remediation'),
  },
  unassessed: {
    url: '/images/outcomes/unassessed.svg',
    alt: I18n.t('Unassessed'),
  },
  no_evidence: {
    url: '/images/outcomes/no_evidence.svg',
    alt: I18n.t('No Evidence'),
  },
}

const MasteryIcon = ({masteryLevel, description}: MasteryIconProps) => {
  // If masteryLevel is a number, render a numeric badge
  if (typeof masteryLevel === 'number') {
    const label = description || I18n.t('Level %{level}', {level: masteryLevel})

    return (
      <>
        <Text size="small" weight="bold" color="primary">
          {masteryLevel}
        </Text>
        <ScreenReaderContent>{label}</ScreenReaderContent>
      </>
    )
  }

  // Otherwise, use icon mapping for standard mastery levels
  const {url, alt} = masteryLevelToIcon[masteryLevel as MasteryLevel]

  return (
    <>
      <Img width="100%" height="100%" src={url} alt={alt} />
      <ScreenReaderContent>{alt}</ScreenReaderContent>
    </>
  )
}

export default MasteryIcon
