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
import {IconCopyLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {calculateHighRangeForDataRow} from '../../helpers/calculateHighRangeForDataRow'
import {GradingSchemeDataRowView} from './GradingSchemeDataRowView'
import {Heading} from '@instructure/ui-heading'
import type {GradingScheme} from '../../../index'

const I18n = useI18nScope('GradingSchemes')

interface ComponentProps {
  gradingSchemeTemplate: GradingScheme
  allowDuplicate: boolean
  onDuplicationRequested?: () => any
}

export const GradingSchemeTemplateView: React.FC<ComponentProps> = ({
  gradingSchemeTemplate,
  allowDuplicate,
  onDuplicationRequested,
}) => {
  return (
    <View as="div" margin="none none none x-large" data-testid="default_canvas_grading_scheme">
      <Flex>
        <Flex.Item shouldGrow={true} shouldShrink={true} padding="none medium none none">
          <Heading level="h3" margin="0 0 x-small">
            <ScreenReaderContent>{I18n.t('Grading scheme title')}</ScreenReaderContent>
            {gradingSchemeTemplate.title}
          </Heading>
        </Flex.Item>
        <Flex.Item>
          {allowDuplicate ? (
            <Tooltip renderTip={I18n.t('edit a copy')} placement="bottom">
              <IconButton
                withBackground={false}
                withBorder={false}
                onClick={onDuplicationRequested}
                screenReaderLabel={I18n.t('Edit a copy of this grading scheme')}
                data-testid="default_canvas_grading_scheme_duplicate_button"
              >
                <IconCopyLine />
              </IconButton>
            </Tooltip>
          ) : (
            <></>
          )}
        </Flex.Item>
      </Flex>
      <Flex>
        <Flex.Item>
          <Table
            caption={I18n.t(
              'A table that contains the default canvas grading scheme data.  Each row contains a name, a maximum percentage, and a minimum percentage.'
            )}
            layout="fixed"
            data-testid="default_canvas_grading_scheme_data_table"
          >
            <Table.Head>
              <Table.Row themeOverride={{borderColor: 'transparent'}}>
                <Table.ColHeader themeOverride={{padding: 'none'}} id="1">
                  {I18n.t('Letter Grade')}
                </Table.ColHeader>
                <Table.ColHeader themeOverride={{padding: 'none'}} id="2">
                  {I18n.t('Range')}
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {gradingSchemeTemplate.data.map((dataRow, idx, array) => (
                <GradingSchemeDataRowView
                  key={shortid()}
                  dataRow={dataRow}
                  highRange={calculateHighRangeForDataRow(idx, array)}
                  isFirstRow={idx === 0}
                  schemeScaleFactor={1.0}
                  viewAsPercentage={true}
                />
              ))}
            </Table.Body>
          </Table>
        </Flex.Item>
      </Flex>
    </View>
  )
}
