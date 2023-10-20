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

import React from 'react'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconAdminToolsLine, IconRefreshLine, IconWarningSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Pill} from '@instructure/ui-pill'
import CopyToClipboardButton from '@canvas/copy-to-clipboard-button'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('jobs_v2')

export default function JobStatsTable({clusters, onRefresh, onUnblock, onShowStuckModal}) {
  const ShardIndicator = ({policy, shards}) => {
    return (
      <>
        <Tooltip
          renderTip={I18n.t('The following shards set %{policy}: %{list}', {
            policy,
            list: shards.join(', '),
          })}
        >
          <Pill color="warning" margin="0 0 0 small">
            {policy.replace('_', ' ')}
          </Pill>
        </Tooltip>
        <CopyToClipboardButton
          value={shards.join(', ')}
          buttonProps={{
            withBackground: false,
            withBorder: false,
          }}
          tooltip={true}
          tooltipText={I18n.t('Copy list of shard ids')}
        />
      </>
    )
  }

  const rowName = row => row.database_server_id || row.id || 'default'
  const unblockText = I18n.t('Unblock')

  return (
    <Table caption={I18n.t('Job Stats by Cluster')}>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="cluster">{I18n.t('Cluster')}</Table.ColHeader>
          <Table.ColHeader textAlign="end" id="running">
            {I18n.t('Running')}
          </Table.ColHeader>
          <Table.ColHeader textAlign="end" id="queued">
            {I18n.t('Queued')}
          </Table.ColHeader>
          <Table.ColHeader textAlign="end" id="future">
            {I18n.t('Future')}
          </Table.ColHeader>
          <Table.ColHeader textAlign="end" id="blocked">
            {I18n.t('Blocked')}
          </Table.ColHeader>
          <Table.ColHeader id="actions" width="10rem">
            <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
          </Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {clusters.map(row => (
          <Table.Row key={row.id}>
            <Table.Cell>
              {row.domain ? (
                <Link href={`//${row.domain}/jobs_v2`}>{rowName(row)}</Link>
              ) : (
                <Text color="primary">{rowName(row)}</Text>
              )}
              {row.jobs_held_shard_ids.length > 0 ? (
                <ShardIndicator policy="jobs_held" shards={row.jobs_held_shard_ids} />
              ) : null}
              {row.block_stranded_shard_ids.length > 0 ? (
                <ShardIndicator policy="block_stranded" shards={row.block_stranded_shard_ids} />
              ) : null}
            </Table.Cell>
            <Table.Cell textAlign="end">{row.counts.running}</Table.Cell>
            <Table.Cell textAlign="end">{row.counts.queued}</Table.Cell>
            <Table.Cell textAlign="end">{row.counts.future}</Table.Cell>
            <Table.Cell textAlign="end">
              {row.counts.blocked > 0 ? (
                <Link role="button" onClick={() => onShowStuckModal(row)}>
                  {row.counts.blocked}
                </Link>
              ) : (
                0
              )}
            </Table.Cell>
            <Table.Cell>
              <Tooltip renderTip={I18n.t('Refresh')}>
                <IconButton
                  withBackground={false}
                  withBorder={false}
                  interaction={row.loading ? 'disabled' : 'enabled'}
                  screenReaderLabel={I18n.t('Refresh')}
                  onClick={() => onRefresh(row.id)}
                >
                  <IconRefreshLine />
                </IconButton>
              </Tooltip>
              {ENV?.manage_jobs && row.counts.blocked > 0 ? (
                <Tooltip renderTip={unblockText}>
                  <IconButton
                    withBackground={false}
                    withBorder={false}
                    interaction={
                      row.loading || row.block_stranded || row.jobs_held ? 'disabled' : 'enabled'
                    }
                    screenReaderLabel={unblockText}
                    onClick={() => onUnblock(row.id)}
                  >
                    <IconAdminToolsLine />
                  </IconButton>
                </Tooltip>
              ) : null}
              {row.loading ? <Spinner renderTitle={row.message} size="x-small" /> : null}
              {row.error ? (
                <Tooltip
                  renderTip={I18n.t('Error updating %{cluster}: %{error}', {
                    cluster: rowName(row),
                    error: row.error,
                  })}
                >
                  <IconWarningSolid color="error" />
                </Tooltip>
              ) : null}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table.Body>
    </Table>
  )
}
