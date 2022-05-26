/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {memo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconAssignmentLine, IconRubricLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'
import {alignmentShape} from './shapes'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentItem = ({id, type, title, url, moduleTitle, moduleUrl}) => {
  const renderIcon = alignmentType =>
    String(alignmentType).toLowerCase() === 'rubric' ? (
      <IconRubricLine data-testid="alignment-item-rubric-icon" />
    ) : (
      <IconAssignmentLine data-testid="alignment-item-assignment-icon" />
    )

  return (
    <Flex key={id} as="div" alignItems="start" padding="x-small 0 0" data-testid="alignment-item">
      <Flex.Item as="div" size="1.5rem">
        <div
          style={{
            display: 'inline-flex',
            alignSelf: 'center',
            fontSize: '1rem',
            padding: '0.5rem 0 0'
          }}
        >
          {renderIcon(type)}
        </div>
      </Flex.Item>
      <Flex.Item size="50%" shouldGrow>
        <Flex direction="column">
          <div style={{padding: '0.25rem'}}>
            <Link interaction="enabled" isWithinText={false} href={url} target="_blank">
              <Text size="medium">{title}</Text>
            </Link>
          </div>
          <div style={{padding: '0.25rem'}}>
            <Text size="small">{`${I18n.t('Module')}:`}</Text>
            <span style={{paddingLeft: '0.375rem'}}>
              {moduleTitle && moduleUrl ? (
                <Link interaction="enabled" isWithinText={false} href={moduleUrl} target="_blank">
                  <Text size="small">{moduleTitle}</Text>
                </Link>
              ) : (
                <Text size="small" color="secondary">
                  {I18n.t('None')}
                </Text>
              )}
            </span>
          </div>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

AlignmentItem.propTypes = alignmentShape.isRequired

export default memo(AlignmentItem)
