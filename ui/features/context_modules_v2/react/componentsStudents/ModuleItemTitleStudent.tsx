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
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {ModuleItemContent, ModuleProgression} from '../utils/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useMemo} from 'react'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemTitleStudentProps {
  title: string
  content: ModuleItemContent
  progression?: ModuleProgression
  position?: number
  requireSequentialProgress?: boolean
  url: string
  onClick?: () => void
}

const missingTitleText = I18n.t('Untitled Item')

const ModuleItemTitleStudent = ({
  title,
  content,
  progression,
  position,
  requireSequentialProgress,
  url,
  onClick,
}: ModuleItemTitleStudentProps) => {
  const seamlessRedirectEnabled = window.ENV?.MODULE_FEATURES?.SEAMLESS_EXTERNAL_URL_REDIRECT

  const titleText = useMemo(() => {
    if (
      progression?.locked ||
      (requireSequentialProgress &&
        progression?.currentPosition &&
        position &&
        progression?.currentPosition < position)
    ) {
      return (
        <View as="div" padding="xx-small">
          <Text weight="bold" color="secondary" data-testid="module-item-title-locked">
            {title || missingTitleText}
          </Text>
        </View>
      )
    }

    if (content?.type === 'SubHeader') {
      return (
        <View as="div" padding="xx-small">
          <Text weight="bold" color="primary" data-testid="subheader-title-text">
            {title || missingTitleText}
          </Text>
        </View>
      )
    }

    const linkTarget =
      content?.type === 'ExternalUrl' && content?.newTab && seamlessRedirectEnabled
        ? '_blank'
        : undefined
    const linkRel = linkTarget ? 'noopener noreferrer' : undefined
    const linkUrl =
      content?.type === 'ExternalUrl' &&
      content?.newTab &&
      seamlessRedirectEnabled &&
      url.includes('?')
        ? `${url}&follow_redirect=1`
        : content?.type === 'ExternalUrl' && content?.newTab && seamlessRedirectEnabled
          ? `${url}?follow_redirect=1`
          : url

    return (
      <View as="div" padding="0 xx-small">
        <Link
          href={linkUrl}
          variant="standalone"
          onClick={onClick}
          target={linkTarget}
          rel={linkRel}
        >
          <Text weight="bold" color="primary" data-testid="module-item-title">
            {title || missingTitleText}
          </Text>
        </Link>
      </View>
    )
  }, [
    content,
    progression,
    position,
    requireSequentialProgress,
    url,
    onClick,
    seamlessRedirectEnabled,
  ])

  return titleText
}

export default ModuleItemTitleStudent
