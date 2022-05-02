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

import React from 'react'
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconInfoLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentStatItem = ({type, count, percent, average}) => {
  let statName, statDescription, statType
  if (type === 'outcome') {
    statName = I18n.t(
      {
        one: '%{count} OUTCOME',
        other: '%{count} OUTCOMES'
      },
      {
        count: count || 0
      }
    )
    statType = I18n.t('Coverage')
    statDescription = I18n.t('Avg. Alignments per Outcome')
  } else if (type === 'artifact') {
    statName = I18n.t(
      {
        one: '%{count} ALIGNABLE ARTIFACT',
        other: '%{count} ALIGNABLE ARTIFACTS'
      },
      {
        count: count || 0
      }
    )
    statType = I18n.t('With Alignments')
    statDescription = I18n.t('Avg. Alignments per Artifact')
  }

  const renderTooltip = () => (
    <Tooltip
      on={['click', 'hover', 'focus']}
      color="primary"
      renderTip={
        <View as="div" width="12rem" textAlign="center">
          <Text size="small">{I18n.t('Outcomes may be aligned to rubrics and quizzes')}</Text>
        </View>
      }
    >
      <div style={{padding: '0 0 0.2rem 0.3rem'}}>
        <IconInfoLine tabIndex="0" data-testid="outcome-alignment-stat-info-icon" />
      </div>
    </Tooltip>
  )

  return (
    <View
      as="span"
      display="inline-block"
      width="28rem"
      padding="small"
      borderRadius="medium"
      background="primary"
      shadow="resting"
      data-testid="outcome-alignment-stat-item"
    >
      <Flex as="div" direction="column">
        <Flex.Item as="div">
          <Flex>
            <Flex.Item>
              <Text size="large">{statName}</Text>
            </Flex.Item>
            {type === 'artifact' && <Flex.Item>{renderTooltip()}</Flex.Item>}
          </Flex>
        </Flex.Item>
        <Flex.Item as="div">
          <Text size="large" weight="bold">
            {`${(percent * 100).toFixed()}%`}
          </Text>
          <View padding="0 small 0 xx-small">
            <Text size="small">{statType}</Text>
          </View>
          <Text size="large" weight="bold">
            {average.toFixed(1)}
          </Text>
          <View padding="0 small 0 xx-small">
            <Text size="small">{statDescription}</Text>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

AlignmentStatItem.propTypes = {
  type: PropTypes.oneOf(['outcome', 'artifact']).isRequired,
  count: PropTypes.number.isRequired,
  percent: PropTypes.number.isRequired,
  average: PropTypes.number.isRequired
}

export default AlignmentStatItem
