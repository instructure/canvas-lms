/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import ScoreDistributionGraph from '../ScoreDistributionGraph'
import {formatNumber} from '../utils'

const I18n = useI18nScope('grade_summary')

export const scoreDistributionRow = (
  assignment,
  setOpenAssignmentDetailIds,
  openAssignmentDetailIds
) => {
  const wholeNumberOrDecimal = value => {
    if (value % 1 === 0) {
      return value
    }
    return formatNumber(value)
  }

  return (
    <Table.Row key={`score_distribution_${assignment._id}`}>
      <Table.Cell colSpan="5" textAlign="center">
        <Flex direction="column" width="100%">
          <Flex.Item>
            <View as="div" margin="small" padding="0 0 small 0" borderWidth="0 0 small 0">
              <Flex width="100%">
                <Flex.Item textAlign="start" shouldGrow={true}>
                  <Text weight="bold">{I18n.t('Score Details')}</Text>
                </Flex.Item>
                <Flex.Item textAlign="end">
                  <Link
                    as="button"
                    isWithinText={false}
                    onClick={() => {
                      const arr = [...openAssignmentDetailIds]
                      const index = arr.indexOf(assignment._id)
                      if (index > -1) {
                        arr.splice(index, 1)
                        setOpenAssignmentDetailIds(arr)
                      }
                    }}
                  >
                    {I18n.t('Close')}
                  </Link>
                </Flex.Item>
              </Flex>
            </View>
          </Flex.Item>
          <Flex.Item>
            <Flex>
              <Flex.Item>
                <View as="div" margin="0 0 0 small">
                  <Flex direction="column" justifyItems="start" alignItems="start">
                    <Flex.Item>
                      <View as="div" margin="0 0 small 0">
                        <Text>
                          {I18n.t('Mean:')} {wholeNumberOrDecimal(assignment.scoreStatistic.mean)}
                        </Text>
                      </View>
                    </Flex.Item>
                    <Flex.Item>
                      <View as="div" margin="0 0 small 0">
                        <Text>
                          {I18n.t('Median:')}{' '}
                          {wholeNumberOrDecimal(assignment.scoreStatistic.median)}
                        </Text>
                      </View>
                    </Flex.Item>
                  </Flex>
                </View>
              </Flex.Item>
              <Flex.Item>
                <Flex direction="column" justifyItems="start" alignItems="start">
                  <Flex.Item>
                    <View as="div" margin="0 0 small medium">
                      <Text>
                        {I18n.t('High:')} {wholeNumberOrDecimal(assignment.scoreStatistic.maximum)}
                      </Text>
                    </View>
                  </Flex.Item>
                  <Flex.Item>
                    <View as="div" margin="0 0 small medium">
                      <Text>
                        {I18n.t('Upper Quartile:')}{' '}
                        {wholeNumberOrDecimal(assignment.scoreStatistic.upperQ)}
                      </Text>
                    </View>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item>
                <Flex direction="column" justifyItems="start" alignItems="start">
                  <Flex.Item>
                    <View as="div" margin="0 0 small medium">
                      <Text>
                        {I18n.t('Low:')} {wholeNumberOrDecimal(assignment.scoreStatistic.minimum)}
                      </Text>
                    </View>
                  </Flex.Item>
                  <Flex.Item>
                    <View as="div" margin="0 0 small medium">
                      <Text>
                        {I18n.t('Lower Quartile:')}{' '}
                        {wholeNumberOrDecimal(assignment.scoreStatistic.lowerQ)}
                      </Text>
                    </View>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item shouldGrow={true} textAlign="end">
                <View as="div" margin="0 large 0 0">
                  <ScoreDistributionGraph assignment={assignment} />
                </View>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Table.Cell>
    </Table.Row>
  )
}
