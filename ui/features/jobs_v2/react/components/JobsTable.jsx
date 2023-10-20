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
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {Link} from '@instructure/ui-link'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {InfoColumn, InfoColumnHeader} from './InfoColumn'
import SortColumnHeader from './SortColumnHeader'
import CopyToClipboardButton from '@canvas/copy-to-clipboard-button'

const I18n = useI18nScope('jobs_v2')

function CopyToClipboardTruncatedValue({value, onClick}) {
  if (!value) {
    return <Text color="secondary">-</Text>
  }

  return (
    <div className="copy-button-container">
      <Flex>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Tooltip renderTip={value}>
            <Link onClick={() => onClick(value)}>
              <TruncateText>{value}</TruncateText>
            </Link>
          </Tooltip>
        </Flex.Item>
        <Flex.Item>
          <div className="copy-button-container-cell">
            <CopyToClipboardButton value={value} />
          </div>
        </Flex.Item>
      </Flex>
    </div>
  )
}

export default function JobsTable({
  bucket,
  jobs,
  caption,
  sortColumn,
  onClickJob,
  onClickHeader,
  onClickFilter,
  timeZone,
}) {
  const renderJobRow = useCallback(
    job => {
      return (
        <Table.Row key={job.id}>
          <Table.RowHeader>
            <Link onClick={() => onClickJob(job)}>{job.id}</Link>
          </Table.RowHeader>
          <Table.Cell>
            <CopyToClipboardTruncatedValue
              value={job.tag}
              onClick={tag => onClickFilter('tag', tag)}
            />
          </Table.Cell>
          <Table.Cell>
            <CopyToClipboardTruncatedValue
              value={job.strand}
              onClick={strand => onClickFilter('strand', strand)}
            />
            <CopyToClipboardTruncatedValue
              value={job.singleton}
              onClick={singleton => onClickFilter('singleton', singleton)}
            />
          </Table.Cell>
          <Table.Cell>
            {job.locked_by === 'on hold' ? (
              <Text color="alert">{I18n.t('hold')}</Text>
            ) : (
              `${job.attempts} / ${job.max_attempts}`
            )}
          </Table.Cell>
          <Table.Cell>{job.priority}</Table.Cell>
          <Table.Cell>
            <InfoColumn timeZone={timeZone} bucket={bucket} info={job.info} />
          </Table.Cell>
        </Table.Row>
      )
    },
    [bucket, onClickFilter, onClickJob, timeZone]
  )

  const renderColHeader = useCallback(
    (attr, content, {sortable, width} = {}) => {
      if (typeof sortable === 'undefined' || sortable) {
        return (
          <Table.ColHeader id={attr} width={width}>
            <SortColumnHeader
              bucket={bucket}
              attr={attr}
              content={content}
              sortColumn={sortColumn}
              onClickHeader={onClickHeader}
            />
          </Table.ColHeader>
        )
      } else {
        return (
          <Table.ColHeader id={attr} width={width}>
            {content}
          </Table.ColHeader>
        )
      }
    },
    [bucket, sortColumn, onClickHeader]
  )

  return (
    <div>
      <Responsive
        query={{
          small: {maxWidth: '719px'},
          large: {minWidth: '720px'},
        }}
        props={{
          small: {layout: 'stacked'},
          large: {layout: 'fixed'},
        }}
      >
        {props => (
          <Table caption={caption} {...props}>
            <Table.Head>
              <Table.Row>
                {renderColHeader('id', I18n.t('ID'), {width: '8rem'})}
                {renderColHeader('tag', I18n.t('Tag'))}
                {renderColHeader('strand_singleton', I18n.t('Strand / Singleton'))}
                {renderColHeader('attempt', I18n.t('Attempt'), {sortable: false, width: '5rem'})}
                {renderColHeader('priority', I18n.t('Priority'), {sortable: false, width: '5rem'})}
                {renderColHeader('info', <InfoColumnHeader bucket={bucket} />, {width: '11rem'})}
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
