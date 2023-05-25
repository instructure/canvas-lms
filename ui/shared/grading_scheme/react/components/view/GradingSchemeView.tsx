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

import {calculateMaxScoreForDataRow} from '../../helpers/calculateMaxScoreForDataRow'
import {GradingSchemeDataRowView} from './GradingSchemeDataRowView'
import {Heading} from '@instructure/ui-heading'
import {GradingScheme} from '@canvas/grading-scheme'

const I18n = useI18nScope('GradingSchemes')

interface ComponentProps {
  gradingScheme: GradingScheme
  allowEdit: boolean
  allowDelete: boolean
  onEditRequested?: () => any
  onDeleteRequested?: () => any
}

// Doing this to avoid TS2339 errors -- TODO: remove once we're on InstUI 8
const {Item} = Flex as any
const {Head, Row, ColHeader, Body} = Table as any

export const GradingSchemeView: React.FC<ComponentProps> = ({
  gradingScheme,
  allowEdit,
  allowDelete,
  onEditRequested,
  onDeleteRequested,
}) => {
  return (
    <View as="div" data-testid={`grading_scheme_${gradingScheme.id}`}>
      <Flex>
        <Item shouldGrow={true} shouldShrink={true} padding="none medium none none">
          <Heading level="h3" margin="0 0 x-small">
            {gradingScheme.title}
          </Heading>
        </Item>
        <Item>
          {allowEdit ? (
            <IconButton
              onClick={onEditRequested}
              margin="none x-small none none"
              screenReaderLabel={I18n.t('Edit grading scheme')}
              data-testid={`grading_scheme_${gradingScheme.id}_edit_button`}
            >
              <IconEditLine />
            </IconButton>
          ) : (
            <></>
          )}
          {allowDelete ? (
            <IconButton
              onClick={onDeleteRequested}
              screenReaderLabel={I18n.t('Delete grading scheme')}
              data-testid={`grading_scheme_${gradingScheme.id}_delete_button`}
            >
              <IconTrashLine />
            </IconButton>
          ) : (
            <></>
          )}
        </Item>
      </Flex>
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
              {/* <Row theme={{borderColor: 'white'}}> */}
              <Row>
                <ColHeader theme={{padding: 'none'}} id="1">
                  {I18n.t('Letter Grade')}
                </ColHeader>
                <ColHeader theme={{padding: 'none'}} id="2">
                  {I18n.t('Range')}
                </ColHeader>
              </Row>
            </Head>
            <Body>
              {gradingScheme.data.map((dataRow, idx, array) => (
                <GradingSchemeDataRowView
                  key={shortid()}
                  dataRow={dataRow}
                  maxScore={calculateMaxScoreForDataRow(idx, array)}
                  isFirstRow={idx === 0}
                />
              ))}
            </Body>
          </Table>
        </Item>
      </Flex>
    </View>
  )
}
