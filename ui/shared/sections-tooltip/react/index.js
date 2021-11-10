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
import PropTypes from 'prop-types'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!sections_tooltip'

function renderTooltip(tipContent, children) {
  if (tipContent === null) {
    return children
  } else {
    return (
      <Tooltip tip={tipContent} placement="bottom">
        <span>{children}</span>
      </Tooltip>
    )
  }
}

export default function SectionsTooltip({sections}) {
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
        other: '%{count} Sections'
      },
      {count: sections ? sections.length : 0}
    )
  } else {
    tipContent = null
    sectionsCountText = I18n.t('All Sections')
  }

  return (
    <span className="ic-section-tooltip">
      {renderTooltip(
        tipContent,
        <Text size="small">
          {sectionsCountText}
          {nonNullSections.map(sec => (
            <ScreenReaderContent key={sec.id}>{sec.name}</ScreenReaderContent>
          ))}
        </Text>
      )}
    </span>
  )
}

SectionsTooltip.propTypes = {
  sections: PropTypes.arrayOf(PropTypes.object)
}

SectionsTooltip.defaultProps = {
  sections: null
}
