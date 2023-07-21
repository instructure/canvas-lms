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

import React, {useState} from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('jobs_v2')

export default function StuckList({shard, type}) {
  const [list, setList] = useState()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState()

  useFetchApi(
    {
      path: `/api/v1/jobs2/stuck/${type}s`,
      params: {job_shard: shard.id},
      loading: setLoading,
      success: setList,
      error: setError,
      fetchAllPages: true,
    },
    []
  )

  const StuckTable = ({caption}) => {
    return (
      <Table caption={caption} margin="0 0 small 0">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="cluster">
              {type === 'singleton' ? I18n.t('Singleton') : I18n.t('Strand')}
            </Table.ColHeader>
            <Table.ColHeader textAlign="end" id="running">
              {I18n.t('Job Count')}
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {list.map(row => (
            <Table.Row key={row.name}>
              <Table.Cell>
                {shard.domain ? (
                  <Link
                    target="_blank"
                    href={`//${
                      shard.domain
                    }/jobs_v2?group_type=${type}&group_text=${encodeURIComponent(
                      row.name
                    )}&bucket=queued`}
                  >
                    {row.name}
                  </Link>
                ) : (
                  <Text color="primary">{row.name}</Text>
                )}
              </Table.Cell>
              <Table.Cell textAlign="end">{row.count}</Table.Cell>
            </Table.Row>
          ))}
        </Table.Body>
      </Table>
    )
  }

  const caption = type === 'singleton' ? I18n.t('Blocked singletons') : I18n.t('Blocked strands')
  return (
    <>
      {list?.length > 0 ? <StuckTable caption={caption} /> : null}
      {loading ? <Spinner size="small" renderTitle={I18n.t('Loading')} /> : null}
      {error && <Alert variant="error">{`${error}`}</Alert>}
    </>
  )
}
