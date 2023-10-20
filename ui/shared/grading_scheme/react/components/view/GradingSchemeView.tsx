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
import shortid from '@canvas/shortid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
// @ts-expect-error -- TODO: remove once we're on InstUI 8
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'

import {calculateHighRangeForDataRow} from '../../helpers/calculateHighRangeForDataRow'
import {GradingSchemeDataRowView} from './GradingSchemeDataRowView'
import {Heading} from '@instructure/ui-heading'
import {GradingScheme} from '@canvas/grading-scheme'

const I18n = useI18nScope('GradingSchemes')

interface ComponentProps {
  gradingScheme: GradingScheme
  pointsBasedGradingSchemesEnabled: boolean
  disableEdit: boolean
  disableDelete: boolean
  onEditRequested?: () => any
  onDeleteRequested?: () => any
}

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any
const {Head, Row, ColHeader, Body} = Table as any

export const GradingSchemeView: React.FC<ComponentProps> = ({
  gradingScheme,
  pointsBasedGradingSchemesEnabled,
  disableEdit = false,
  disableDelete = false,
  onEditRequested,
  onDeleteRequested,
}) => {
  return (
    <View
      as="div"
      margin="none none none x-large"
      data-testid={`grading_scheme_${gradingScheme.id}`}
    >
      <Flex>
        <Item shouldGrow={true} shouldShrink={true} padding="none medium none none">
          <Heading level="h3" margin="0 0 x-small">
            <ScreenReaderContent>{I18n.t('Grading scheme title')}</ScreenReaderContent>
            {gradingScheme.title}
          </Heading>
        </Item>
        <Item>
          <IconButton
            onClick={onEditRequested}
            margin="none x-small none none"
            screenReaderLabel={I18n.t('Edit grading scheme')}
            data-testid={`grading_scheme_${gradingScheme.id}_edit_button`}
            disabled={disableEdit}
            withBorder={false}
            withBackground={false}
          >
            <IconEditLine />
          </IconButton>

          <IconButton
            onClick={onDeleteRequested}
            screenReaderLabel={I18n.t('Delete grading scheme')}
            data-testid={`grading_scheme_${gradingScheme.id}_delete_button`}
            disabled={disableDelete}
            withBackground={false}
            withBorder={false}
          >
            <IconTrashLine />
          </IconButton>
        </Item>
      </Flex>
      <View>
        {pointsBasedGradingSchemesEnabled ? (
          <View as="div" padding="none none small none" withVisualDebug={false}>
            <RadioInputGroup
              layout="columns"
              name={`points_based_${gradingScheme.id}`}
              defaultValue={String(gradingScheme.points_based)}
              description={I18n.t('Grade by')}
              disabled={true}
            >
              <RadioInput value="false" label={I18n.t('Percentage')} />
              <RadioInput value="true" label={I18n.t('Points')} />
            </RadioInputGroup>
          </View>
        ) : (
          <></>
        )}
      </View>
      <Flex>
        <Item>
          <Table
            caption={I18n.t(
              'A table that contains the grading scheme data.  Each row contains a name, a maximum percentage, and a minimum percentage.'
            )}
            layout="fixed"
            data-testid={`grading_scheme_${gradingScheme.id}_data_table`}
          >
            <Head>
              <Row theme={{borderColor: 'transparent'}}>
                <ColHeader theme={{padding: 'none'}} id="1" width="30%">
                  {I18n.t('Letter Grade')}
                </ColHeader>
                <ColHeader theme={{padding: 'none'}} id="2" width="70%" colSpan={2}>
                  {I18n.t('Range')}
                </ColHeader>
              </Row>
            </Head>
            <Body>
              {gradingScheme.data.map((dataRow, idx, array) => (
                <GradingSchemeDataRowView
                  key={shortid()}
                  dataRow={dataRow}
                  highRange={calculateHighRangeForDataRow(idx, array)}
                  isFirstRow={idx === 0}
                  schemeScaleFactor={
                    pointsBasedGradingSchemesEnabled ? gradingScheme.scaling_factor : 1.0
                  }
                  viewAsPercentage={!gradingScheme.points_based}
                />
              ))}
            </Body>
          </Table>
        </Item>
      </Flex>
    </View>
  )
}
