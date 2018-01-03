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
import I18n from 'i18n!sections_tooltip'

function sectionsOrTotalCount (props, propName, componentName) {
  if (!props.totalUserCount && !props.sections) {
    return new Error(`One of props 'totalUserCount' or 'sections' was not specified in '${componentName}'.`);
  }
  return null
}

export default function SectionsTooltip ({ sections, totalUserCount}) {
  let tipContent = ""
  if (sections) {
    tipContent = sections.map((sec) =>
      <Container key={sec.id} as='div' margin='xx-small'>
        <Text size='small'>{I18n.t('%{name} (%{count} Users)', {name: sec.name, count: sec.user_count})}</Text>
      </Container>
    )
  } else {
    tipContent = (
      <Container as='div' margin='xx-small'>
        <Text size='small'>{I18n.t('(%{count} Users)', {count: totalUserCount})}</Text>
      </Container>
    )
  }
  return (
    <span className='ic-section-tooltip'>
      <Tooltip tip={tipContent} placement='bottom'>
        <Link>
          {
            sections ?
            <Text size='small'>{I18n.t('%{section_count} Sections', {section_count: sections.length})}</Text>
            :
            <Text size='small'>{I18n.t('All Sections')}</Text>
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
