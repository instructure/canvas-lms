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
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {calculateHighRangeForDataRow} from '../../helpers/calculateHighRangeForDataRow'
import {GradingSchemeDataRowView} from './GradingSchemeDataRowView'
import {Heading} from '@instructure/ui-heading'
import type {GradingScheme} from '../../../index'

const I18n = useI18nScope('GradingSchemes')

interface ComponentProps {
  gradingScheme: GradingScheme
  archivedGradingSchemesEnabled: boolean
  disableDelete: boolean
  onEditRequested?: () => any
  onDeleteRequested?: () => any
  disableEdit?: boolean
  archivedGradingSchemesDisableEdit?: boolean
}

export const GradingSchemeView: React.FC<ComponentProps> = ({
  gradingScheme,
  archivedGradingSchemesEnabled,
  disableEdit = false,
  disableDelete = false,
  archivedGradingSchemesDisableEdit = false,
  onEditRequested,
  onDeleteRequested,
}) => {
  return (
    <View
      as="div"
      margin={archivedGradingSchemesEnabled ? 'none none none xxx-small' : 'none none none x-large'}
      data-testid={`grading_scheme_${gradingScheme.id}`}
    >
      {archivedGradingSchemesEnabled ? (
        <></>
      ) : (
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true} padding="none medium none none">
            <Heading level="h3" margin="0 0 x-small">
              <ScreenReaderContent>{I18n.t('Grading scheme title')}</ScreenReaderContent>
              {gradingScheme.title}
            </Heading>
          </Flex.Item>
          <Flex.Item>
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
          </Flex.Item>
        </Flex>
      )}
      <View>
        <View as="div" padding="none none medium none" withVisualDebug={false}>
          <Flex justifyItems="space-between" alignItems="start">
            <Flex.Item>
              <Heading level="h4" style={{margin: '0px 0px 4px', lineHeight: '24px'}}>
                {I18n.t('Grade By')}
              </Heading>
              {gradingScheme.points_based ? I18n.t('Points') : I18n.t('Percentage')}
            </Flex.Item>
            {archivedGradingSchemesEnabled && gradingScheme.id !== '' ? (
              <Flex.Item>
                <IconButton
                  screenReaderLabel={I18n.t('Edit Grading Scheme')}
                  onClick={onEditRequested}
                  data-testid={`grading-scheme-${gradingScheme.id}-edit-button`}
                  disabled={archivedGradingSchemesDisableEdit}
                >
                  <IconEditLine />
                </IconButton>
              </Flex.Item>
            ) : (
              <></>
            )}
          </Flex>
        </View>
      </View>
      <Flex>
        <Flex.Item>
          <Table
            caption={I18n.t(
              'A table that contains the grading scheme data.  Each row contains a name, a maximum percentage, and a minimum percentage.'
            )}
            layout="fixed"
            data-testid={`grading_scheme_${gradingScheme.id}_data_table`}
          >
            <Table.Head>
              <Table.Row themeOverride={{borderColor: 'transparent'}}>
                <Table.ColHeader themeOverride={{padding: '0'}} id="1" width="30%">
                  {I18n.t('Letter Grade')}
                </Table.ColHeader>
                <Table.ColHeader themeOverride={{padding: '0'}} id="2" width="70%" colSpan={2}>
                  {I18n.t('Range')}
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {gradingScheme.data.map((dataRow, idx, array) => (
                <GradingSchemeDataRowView
                  key={shortid()}
                  dataRow={dataRow}
                  highRange={calculateHighRangeForDataRow(idx, array)}
                  isFirstRow={idx === 0}
                  schemeScaleFactor={gradingScheme.scaling_factor}
                  viewAsPercentage={!gradingScheme.points_based}
                />
              ))}
            </Table.Body>
          </Table>
        </Flex.Item>
      </Flex>
    </View>
  )
}
