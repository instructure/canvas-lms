/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_bulk_edit'
import React from 'react'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

function BulkEditOverrideTitle({assignment, override}) {
  const [visibleTitle, srSubTitle, size, indent] = override.base
    ? [assignment.name, I18n.t('default dates'), 'large', '0']
    : [override.title, override.title, 'medium', 'xx-large']

  return (
    <View as="div" padding={`0 0 0 ${indent}`}>
      <Tooltip renderTip={visibleTitle}>
        <Text as="div" size={size}>
          <PresentationContent>
            <div className="ellipsis">{visibleTitle}</div>
          </PresentationContent>
          <ScreenReaderContent>{`${assignment.name}: ${srSubTitle}`}</ScreenReaderContent>
        </Text>
      </Tooltip>
    </View>
  )
}

export default React.memo(BulkEditOverrideTitle)
