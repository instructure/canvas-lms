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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import React, {useCallback} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {Link} from '@instructure/ui-link'
import {InfoColumn, InfoColumnHeader} from './InfoColumn'

const I18n = useI18nScope('jobs_v2')

export default function JobsTable({bucket, jobs, caption, onClickJob}) {
  const renderJobRow = useCallback(
    job => {
      const cellTheme = {fontSize: '0.75rem'}

      return (
        <Table.Row key={job.id}>
          <Table.RowHeader>
            <Link onClick={() => onClickJob(job)}>{job.id}</Link>
          </Table.RowHeader>
          <Table.Cell theme={cellTheme}>{job.tag}</Table.Cell>
          <Table.Cell theme={cellTheme}>{job.strand}</Table.Cell>
          <Table.Cell theme={cellTheme}>{job.singleton}</Table.Cell>
          <Table.Cell>
            <InfoColumn bucket={bucket} info={job.info} />
          </Table.Cell>
        </Table.Row>
      )
    },
    [bucket, onClickJob]
  )

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
                <Table.ColHeader id="id">{I18n.t('ID')}</Table.ColHeader>
                <Table.ColHeader id="tag">{I18n.t('Tag')}</Table.ColHeader>
                <Table.ColHeader id="strand">{I18n.t('Strand')}</Table.ColHeader>
                <Table.ColHeader id="singleton">{I18n.t('Singleton')}</Table.ColHeader>
                <Table.ColHeader id="info">
                  <InfoColumnHeader bucket={bucket} />
                </Table.ColHeader>
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
