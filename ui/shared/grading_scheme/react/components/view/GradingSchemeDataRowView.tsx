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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import type {GradingSchemeDataRow} from '@instructure/grading-utils'
import {roundToTwoDecimalPlaces} from '../../helpers/roundDecimalPlaces'

const I18n = useI18nScope('GradingSchemeManagement')

interface ComponentProps {
  schemeScaleFactor: number
  dataRow: GradingSchemeDataRow
  highRange: number
  isFirstRow: boolean
  viewAsPercentage: boolean
}

const GradingSchemeDataRowView: React.FC<ComponentProps> = ({
  dataRow,
  highRange,
  isFirstRow,
  schemeScaleFactor,
  viewAsPercentage,
}) => {
  const [entryScale /* setEntryScale */] = useState<number>(
    schemeScaleFactor * (viewAsPercentage ? 100 : 1)
  )
  function renderHighRange() {
    return String(roundToTwoDecimalPlaces(highRange * entryScale))
  }

  function renderLowRange() {
    return String(roundToTwoDecimalPlaces(dataRow.value * entryScale))
  }

  return (
    <>
      <Table.Row themeOverride={{borderColor: 'transparent'}}>
        <Table.Cell themeOverride={{padding: '0.5rem 0'}}>{dataRow.name}</Table.Cell>
        <Table.Cell themeOverride={{padding: '0.5rem 0'}}>
          <Flex display="inline-flex">
            <Flex.Item>
              <span aria-label={I18n.t('Upper limit of range')}>
                {isFirstRow ? '' : '< '}
                {renderHighRange()}
                {viewAsPercentage ? <>%</> : <></>}
              </span>
            </Flex.Item>
            <Flex.Item padding="none small">{I18n.t('to')}</Flex.Item>
            <Flex.Item>
              <span aria-label={I18n.t('Lower limit of range')}>
                {renderLowRange()}
                {viewAsPercentage ? <>%</> : <></>}
              </span>
            </Flex.Item>
          </Flex>
        </Table.Cell>
      </Table.Row>
    </>
  )
}

// Setting this component's display name to 'Row' is required so that
// instui-table (v7) allows this component to be contained by a Table Body
GradingSchemeDataRowView.displayName = 'Row'

export {GradingSchemeDataRowView}
