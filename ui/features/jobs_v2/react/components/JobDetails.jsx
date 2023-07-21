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
import React, {useCallback, useState} from 'react'
import {Table} from '@instructure/ui-table'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import CopyToClipboardButton from '@canvas/copy-to-clipboard-button'
import RequeueButton from './RequeueButton'

const I18n = useI18nScope('jobs_v2')

export default function JobDetails({job, timeZone, onRequeue}) {
  const [openModal, setOpenModal] = useState('')

  const formatDate = useDateTimeFormat('date.formats.full_compact', timeZone)

  const formatLockedBy = useCallback(locked_by => {
    if (!locked_by) return null

    const ip_parts = locked_by.match(/job(\d\d\d)(\d\d\d)(\d\d\d)(\d\d\d)/)
    if (ip_parts?.length === 5) {
      const ip = ip_parts
        .slice(1)
        .map(part => parseInt(part, 10))
        .join('.')
      return (
        <>
          <span>{locked_by}</span> &mdash; <span>{ip}</span> <CopyToClipboardButton value={ip} />
        </>
      )
    } else {
      return locked_by
    }
  }, [])

  const formatRequeue = id => {
    return id || <RequeueButton id={job.id} onRequeue={onRequeue} />
  }

  const renderRow = useCallback(
    (title, attr, formatFn) => {
      if (job.hasOwnProperty(attr)) {
        return (
          <Table.Row>
            <Table.RowHeader>{title}</Table.RowHeader>
            <Table.Cell>{formatFn ? formatFn(job[attr]) : job[attr]}</Table.Cell>
          </Table.Row>
        )
      }
    },
    [job]
  )

  const renderModalRow = useCallback(
    (title, attr) => {
      if (job.hasOwnProperty(attr)) {
        return (
          <Table.Row>
            <Table.RowHeader>{title}</Table.RowHeader>
            <Table.Cell>
              <Link onClick={() => setOpenModal(attr)}>{I18n.t('(show)')}</Link>
              <Modal
                open={openModal === attr}
                onDismiss={() => setOpenModal('')}
                label={title}
                shouldCloseOnDocumentClick={true}
              >
                <Modal.Header>
                  <CloseButton
                    placement="end"
                    offset="small"
                    onClick={() => setOpenModal('')}
                    screenReaderLabel={I18n.t('Close')}
                  />
                  <Heading>{title}</Heading>
                </Modal.Header>
                <Modal.Body>
                  <pre>{job[attr]}</pre>
                </Modal.Body>
              </Modal>
            </Table.Cell>
          </Table.Row>
        )
      }
    },
    [job, openModal, setOpenModal]
  )

  if (!job) return <Text>{I18n.t('No job selected')}</Text>

  return (
    <Table caption={I18n.t('Job details')}>
      <Table.Body>
        {renderRow(I18n.t('ID'), 'id')}
        {renderRow(I18n.t('Tag'), 'tag')}
        {renderRow(I18n.t('Strand'), 'strand')}
        {renderRow(I18n.t('Singleton'), 'singleton')}
        {renderRow(I18n.t('Shard'), 'shard_id')}
        {renderRow(I18n.t('Max Concurrent'), 'max_concurrent')}
        {renderRow(I18n.t('Priority'), 'priority')}
        {renderRow(I18n.t('Attempt'), 'attempts')}
        {renderRow(I18n.t('Max Attempts'), 'max_attempts')}
        {renderRow(I18n.t('Locked By'), 'locked_by', formatLockedBy)}
        {renderRow(I18n.t('Run At'), 'run_at', formatDate)}
        {renderRow(I18n.t('Locked At'), 'locked_at', formatDate)}
        {renderRow(I18n.t('Failed At'), 'failed_at', formatDate)}
        {renderRow(I18n.t('Original Job ID'), 'original_job_id')}
        {renderRow(I18n.t('Requeued Job ID'), 'requeued_job_id', formatRequeue)}
        {renderModalRow(I18n.t('Handler'), 'handler')}
        {renderModalRow(I18n.t('Last Error'), 'last_error')}
      </Table.Body>
    </Table>
  )
}
