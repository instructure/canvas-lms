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
import Tooltip from '@instructure/ui-core/lib/components/Tooltip'
import Text from '@instructure/ui-core/lib/components/Text'
import Link from '@instructure/ui-core/lib/components/Link'
import Container from '@instructure/ui-core/lib/components/Container'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import I18n from 'i18n!sections_tooltip'

function sectionsOrTotalCount (props, propName, componentName) {
  if (!props.totalUserCount && !props.sections) {
    return new Error(`One of props 'totalUserCount' or 'sections' was not specified in '${componentName}'.`);
  }
  return null
}

export default function SectionsTooltip ({ sections, totalUserCount}) {
  let tipContent = ""
  const nonNullSections = sections ? sections : []
  let sectionsCountText = ""
  if (sections) {
    tipContent = sections.map((sec) =>
      <Container key={sec.id} as='div' margin='xx-small'>
        <Text size='small'>{I18n.t('%{name} (%{count} Users)', {name: sec.name, count: sec.user_count})}</Text>
      </Container>
    )
    sectionsCountText =  I18n.t({
        one: '1 Section',
        other: '%{count} Sections'
      }, { count: (sections ? sections.length : 0) })
  } else {
    tipContent = (
      <Container as='div' margin='xx-small'>
        <Text size='small'>{I18n.t('(%{count} Users)', {count: totalUserCount})}</Text>
      </Container>
    )
    sectionsCountText = I18n.t('All Sections')
  }

  return (
    <span className='ic-section-tooltip'>
      <Tooltip tip={tipContent} placement='bottom'>
        <Link>
          {
            <Text size='small'>{sectionsCountText}
              {nonNullSections.map(sec => (
                <ScreenReaderContent key={sec.id}>
                  {sec.name}
                </ScreenReaderContent>
              ))}
            </Text>
          }
        </Link>
      </Tooltip>
    </span>
  )
}

SectionsTooltip.propTypes = {
  totalUserCount: sectionsOrTotalCount,
  sections: sectionsOrTotalCount
}

SectionsTooltip.defaultProps = {
  sections: null,
  totalUserCount: 0,
}
