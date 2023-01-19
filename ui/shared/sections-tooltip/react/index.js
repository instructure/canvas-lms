/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'
import {string} from 'prop-types'

const I18n = useI18nScope('sections_tooltip')

function sectionsOrTotalCount(props, propName, componentName) {
  if (!props.totalUserCount && !props.sections) {
    return new Error(
      `One of props 'totalUserCount' or 'sections' was not specified in '${componentName}'.`
    )
  }
  return null
}

export default function SectionsTooltip({sections, totalUserCount, prefix, textColor}) {
  let tipContent = ''
  const nonNullSections = sections || []
  let sectionsCountText = ''
  if (sections) {
    tipContent = sections.map(sec => (
      <View key={sec.id} as="div" margin="xx-small">
        <Text size="small">
          {I18n.t('%{name} (%{count} Users)', {name: sec.name, count: sec.user_count})}
        </Text>
      </View>
    ))
    sectionsCountText = I18n.t(
      {
        one: '1 Section',
        other: '%{count} Sections',
      },
      {count: sections ? sections.length : 0}
    )
  } else {
    tipContent = (
      <View as="div" margin="xx-small">
        <Text size="small">{I18n.t('(%{count} Users)', {count: totalUserCount})}</Text>
      </View>
    )
    sectionsCountText = I18n.t('All Sections')
  }

  return (
    <span className="ic-section-tooltip">
      <Tooltip as="span" renderTip={tipContent} placement="bottom">
        <Text size="small" color={textColor}>
          {prefix}
          {sectionsCountText}
          {nonNullSections.map(sec => (
            <ScreenReaderContent key={sec.id}>{sec.name}</ScreenReaderContent>
          ))}
        </Text>
      </Tooltip>
    </span>
  )
}

SectionsTooltip.propTypes = {
  totalUserCount: sectionsOrTotalCount,
  sections: sectionsOrTotalCount,
  prefix: string,
  textColor: string,
}

SectionsTooltip.defaultProps = {
  sections: null,
  totalUserCount: 0,
}
