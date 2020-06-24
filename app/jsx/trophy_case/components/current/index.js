/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Table} from '@instructure/ui-table'
import ImageCell from './ImageCell'
import InfoCell from './InfoCell'
import DateCell from './DateCell'
import I18n from 'i18n!trophy_case'

export default function CurrentTrophies(props) {
  return (
    <Table caption={I18n.t('List of the currently attainable trophies')}>
      <Table.Body>
        {props.trophies.map(t => (
          <Table.Row key={t.trophy_key}>
            <Table.Cell>
              <ImageCell {...t} />
            </Table.Cell>
            <Table.Cell>
              <InfoCell {...t} />
            </Table.Cell>
            <Table.Cell textAlign="end">
              <DateCell {...t} />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table.Body>
    </Table>
  )
}
