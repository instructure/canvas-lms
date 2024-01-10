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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentStatItem = ({type, count, percent, average}) => {
  const {isMobileView} = useCanvasContext()
  const statPercentage = I18n.toPercentage((percent * 100).toFixed(), {precision: 0})
  const statAverage = I18n.n(average.toFixed(1), {precision: 1})
  let statName, statDescription, statType
  if (type === 'outcome') {
    statName = I18n.t(
      {
        one: '%{count} OUTCOME',
        other: '%{count} OUTCOMES',
      },
      {
        count: count || 0,
      }
    )
    statType = I18n.t('Coverage')
    statDescription = I18n.t('Avg. Alignments per Outcome')
  } else if (type === 'artifact') {
    statName = I18n.t(
      {
        one: '%{count} ASSESSABLE ARTIFACT',
        other: '%{count} ASSESSABLE ARTIFACTS',
      },
      {
        count: count || 0,
      }
    )
    statType = I18n.t('With Alignments')
    statDescription = I18n.t('Avg. Alignments per Artifact')
  }

  const renderTooltip = () => {
    const tooltipText = I18n.t(
      'Assessable artifacts include assignments, quizzes, and graded discussions'
    )
    return (
      <Tooltip
        on={['click', 'hover', 'focus']}
        color="primary"
        renderTip={
          <View as="div" width="12rem" textAlign="center">
            <Text size="small">{tooltipText}</Text>
          </View>
        }
      >
        <div
          style={{
            fontSize: isMobileView ? '0.75rem' : '1rem',
            padding: isMobileView ? '0 0 0.15rem 0.2rem' : '0 0 0.2rem 0.3rem',
          }}
        >
          <IconInfoLine tabIndex="0" data-testid="outcome-alignment-stat-info-icon" />
          <div style={{position: 'relative'}}>
            <ScreenReaderContent>{tooltipText}</ScreenReaderContent>
          </div>
        </div>
      </Tooltip>
    )
  }

  return (
    <View
      as="span"
      display="inline-block"
      width={isMobileView ? '100%' : '30rem'}
      padding="small"
      margin="0 small 0 0"
      borderRadius="medium"
      background="primary"
      shadow="resting"
      data-testid="outcome-alignment-stat-item"
    >
      <Flex as="div" direction="column">
        <Flex.Item as="div">
          <Flex>
            <Flex.Item>
              <Text
                size={isMobileView ? 'medium' : 'large'}
                data-testid="outcome-alignment-stat-name"
              >
                {statName}
              </Text>
            </Flex.Item>
            {type === 'artifact' && <Flex.Item>{renderTooltip()}</Flex.Item>}
          </Flex>
        </Flex.Item>
        <Flex.Item as="div">
          <Flex
            as="div"
            direction={isMobileView ? 'column' : 'row'}
            wrap={isMobileView ? 'no-wrap' : 'wrap'}
          >
            <Flex.Item as="div">
              <Text
                size={isMobileView ? 'small' : 'large'}
                weight="bold"
                data-testid="outcome-alignment-stat-percent"
              >
                {statPercentage}
              </Text>
              <View padding="0 small 0 xx-small">
                <Text
                  size={isMobileView ? 'small' : 'medium'}
                  data-testid="outcome-alignment-stat-type"
                >
                  {statType}
                </Text>
              </View>
            </Flex.Item>
            <Flex.Item as="div">
              <Text
                size={isMobileView ? 'small' : 'large'}
                weight="bold"
                data-testid="outcome-alignment-stat-average"
              >
                {statAverage}
              </Text>
              <View padding="0 small 0 xx-small">
                <Text
                  size={isMobileView ? 'small' : 'medium'}
                  data-testid="outcome-alignment-stat-description"
                >
                  {statDescription}
                </Text>
              </View>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

AlignmentStatItem.propTypes = {
  type: PropTypes.oneOf(['outcome', 'artifact']).isRequired,
  count: PropTypes.number.isRequired,
  percent: PropTypes.number.isRequired,
  average: PropTypes.number.isRequired,
}

export default AlignmentStatItem
