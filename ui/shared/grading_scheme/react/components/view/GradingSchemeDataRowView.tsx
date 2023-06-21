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
import {decimalToRoundedPercent} from '../../helpers/decimalToRoundedPercent'
import {Table} from '@instructure/ui-table'
import {GradingSchemeDataRow} from '@canvas/grading-scheme'

const I18n = useI18nScope('GradingSchemeManagement')

interface ComponentProps {
  dataRow: GradingSchemeDataRow
  maxScore: number
  isFirstRow: boolean
}

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any
const {Row, Cell} = Table as any

const GradingSchemeDataRowView: React.FC<ComponentProps> = ({dataRow, maxScore, isFirstRow}) => {
  return (
    <>
      <Row theme={{borderColor: 'transparent'}}>
        <Cell theme={{padding: 'none'}}>{dataRow.name}</Cell>
        <Cell theme={{padding: 'none'}}>
          <Flex display="inline-flex">
            <Item>
              <span aria-label={I18n.t('Upper limit of range')}>
                {isFirstRow ? '' : '< '}
                {decimalToRoundedPercent(maxScore)}%
              </span>
            </Item>
          </Flex>
        </Cell>
        <Cell theme={{padding: 'none'}}>
          <Flex>
            <Item padding="x-small">{I18n.t('to')}</Item>
            <Item>
              <span aria-label={I18n.t('Lower limit of range')}>
                {decimalToRoundedPercent(dataRow.value)}%
              </span>
            </Item>
          </Flex>
        </Cell>
      </Row>
    </>
  )
}

// Setting this component's display name to 'Row' is required so that
// instui-table (v7) allows this component to be contained by a Table Body
GradingSchemeDataRowView.displayName = 'Row'

export {GradingSchemeDataRowView}
