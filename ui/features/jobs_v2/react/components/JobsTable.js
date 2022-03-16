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

import I18n from 'i18n!jobs_v2'
import {Table} from '@instructure/ui-table'
import React from 'react'
import {Responsive} from '@instructure/ui-responsive'

function renderJobRow(job) {
  const cellTheme = {fontSize: '0.75rem'}

  return (
    <Table.Row key={job.id}>
      <Table.RowHeader>{job.id}</Table.RowHeader>
      <Table.Cell theme={cellTheme}>{job.tag}</Table.Cell>
      <Table.Cell theme={cellTheme}>{job.strand}</Table.Cell>
      <Table.Cell theme={cellTheme}>{job.singleton}</Table.Cell>
      <Table.Cell theme={cellTheme}>{job.run_at}</Table.Cell>
    </Table.Row>
  )
}

export default function JobsTable({jobs, caption}) {
  return (
    <div>
      <Responsive
        query={{
          small: {maxWidth: '60rem'},
          large: {minWidth: '60rem'}
        }}
        props={{
          small: {layout: 'stacked'},
          large: {layout: 'auto'}
        }}
      >
        {props => (
          <Table caption={caption} {...props}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader>{I18n.t('ID')}</Table.ColHeader>
                <Table.ColHeader>{I18n.t('Tag')}</Table.ColHeader>
                <Table.ColHeader>{I18n.t('Strand')}</Table.ColHeader>
                <Table.ColHeader>{I18n.t('Singleton')}</Table.ColHeader>
                <Table.ColHeader>{I18n.t('Run At')}</Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {jobs.map(job => {
                return renderJobRow(job)
              })}
            </Table.Body>
          </Table>
        )}
      </Responsive>
    </div>
  )
}
