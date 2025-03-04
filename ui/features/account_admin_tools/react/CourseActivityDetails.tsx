/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Grid} from '@instructure/ui-grid'
import {Table} from '@instructure/ui-table'
import {dateString, timeString} from '@canvas/datetime/date-functions'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('course_logging_details')

type EventType =
  | {event_type: 'copied_to' | 'copied_from' | 'reset_to' | 'reset_from'; event_data: undefined}
  | {
      event_type: 'created'
      event_data: Record<string, string>
    }
  | {
      event_type: 'updated'
      event_data: Record<string, {from: string; to: string}>
    }

type Course = {
  id: string
  name: string
}

export type CourseActivityDetailsProps = {
  id: string
  created_at: string
  copied_to?: Course
  copied_from?: Course
  reset_to?: Course
  reset_from?: Course
  event_source_present: string
  event_type_present: string
  event_source: string
  user?: {
    name: string
  }
  links?: {
    sis_batch: string
  }
  onClose: () => void
} & EventType

const CourseActivityDetails = ({
  id,
  created_at,
  copied_to,
  copied_from,
  reset_to,
  reset_from,
  event_source_present,
  event_type_present,
  event_source,
  event_type,
  event_data,
  user,
  links,
  onClose,
}: CourseActivityDetailsProps) => {
  const title = I18n.t('Event Details')
  const tableCaption = I18n.t('Event details table')

  return (
    <Modal
      open={true}
      onDismiss={onClose}
      size="medium"
      label={title}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="medium" padding="small 0 0 0">
          <Grid rowSpacing="small">
            <Grid.Row>
              <Grid.Col width={2}>
                <Text weight="bold">{I18n.t('Event ID')}:</Text>
              </Grid.Col>
              <Grid.Col width={10} data-testid="event-id">
                <Text>{id}</Text>
              </Grid.Col>
            </Grid.Row>
            <Grid.Row>
              <Grid.Col width={2}>
                <Text weight="bold">{I18n.t('Date')}:</Text>
              </Grid.Col>
              <Grid.Col width={10}>
                <Text>{dateString(created_at, {format: 'medium'})}</Text>
              </Grid.Col>
            </Grid.Row>
            <Grid.Row>
              <Grid.Col width={2}>
                <Text weight="bold">{I18n.t('Time')}:</Text>
              </Grid.Col>
              <Grid.Col width={10}>
                <Text>{timeString(created_at)}</Text>
              </Grid.Col>
            </Grid.Row>
            <Grid.Row>
              <Grid.Col width={2}>
                <Text weight="bold">{I18n.t('User')}:</Text>
              </Grid.Col>
              <Grid.Col width={10}>
                <Text>{user?.name ?? '-'}</Text>
              </Grid.Col>
            </Grid.Row>
            <Grid.Row>
              <Grid.Col width={2}>
                <Text weight="bold">{I18n.t('Source')}:</Text>
              </Grid.Col>
              <Grid.Col width={10} data-testid="event-source">
                <Text>{event_source_present}</Text>
              </Grid.Col>
            </Grid.Row>
            {event_source === 'sis' && (
              <Grid.Row>
                <Grid.Col width={2}>
                  <Text weight="bold">{I18n.t('SIS Batch')}:</Text>
                </Grid.Col>
                <Grid.Col width={10} data-testid="event-sis-batch">
                  <Text>{links?.sis_batch ?? '-'}</Text>
                </Grid.Col>
              </Grid.Row>
            )}
            <Grid.Row>
              <Grid.Col width={2}>
                <Text weight="bold">{I18n.t('Type')}:</Text>
              </Grid.Col>
              <Grid.Col width={10} data-testid="event-type">
                <Text>{event_type_present}</Text>
              </Grid.Col>
            </Grid.Row>
            {event_type === 'copied_to' && (
              <Grid.Row>
                <Grid.Col width={2}>
                  <Text weight="bold">{I18n.t('Copied To')}:</Text>
                </Grid.Col>
                <Grid.Col width={10}>
                  {copied_to ? (
                    <Link href={`/courses/${copied_to.id}`} data-testid="event-copied-to">
                      {copied_to.name}
                    </Link>
                  ) : (
                    <Text>-</Text>
                  )}
                </Grid.Col>
              </Grid.Row>
            )}
            {event_type === 'copied_from' && (
              <Grid.Row>
                <Grid.Col width={2}>
                  <Text weight="bold">{I18n.t('Copied From')}:</Text>
                </Grid.Col>
                <Grid.Col width={10}>
                  {copied_from ? (
                    <Link href={`/courses/${copied_from.id}`} data-testid="event-copied-from">
                      {copied_from.name}
                    </Link>
                  ) : (
                    <Text>-</Text>
                  )}
                </Grid.Col>
              </Grid.Row>
            )}
            {event_type === 'reset_from' && (
              <Grid.Row>
                <Grid.Col width={2}>
                  <Text weight="bold">{I18n.t('Reset From')}:</Text>
                </Grid.Col>
                <Grid.Col width={10}>
                  {reset_from ? (
                    <Link href={`/courses/${reset_from.id}`} data-testid="event-reset-from">
                      {reset_from.name}
                    </Link>
                  ) : (
                    <Text>-</Text>
                  )}
                </Grid.Col>
              </Grid.Row>
            )}
            {event_type === 'reset_to' && (
              <Grid.Row>
                <Grid.Col width={2}>
                  <Text weight="bold">{I18n.t('Reset To')}:</Text>
                </Grid.Col>
                <Grid.Col width={10}>
                  {reset_to ? (
                    <Link href={`/courses/${reset_to.id}`} data-testid="event-reset-to">
                      {reset_to.name}
                    </Link>
                  ) : (
                    <Text>-</Text>
                  )}
                </Grid.Col>
              </Grid.Row>
            )}
          </Grid>
          {event_type === 'created' && (
            <Table caption={tableCaption}>
              <Table.Head>
                <Table.Row>
                  <Table.ColHeader id="Field">{I18n.t('Field')}</Table.ColHeader>
                  <Table.ColHeader id="Value">{I18n.t('Value')}</Table.ColHeader>
                </Table.Row>
              </Table.Head>
              <Table.Body>
                {Object.entries(event_data).map(([key, value]) => (
                  <Table.Row key={`${key}=${value}`}>
                    <Table.RowHeader>{key}</Table.RowHeader>
                    <Table.Cell>{value}</Table.Cell>
                  </Table.Row>
                ))}
              </Table.Body>
            </Table>
          )}
          {event_type === 'updated' && (
            <Table caption={tableCaption}>
              <Table.Head>
                <Table.Row>
                  <Table.ColHeader id="Field">{I18n.t('Field')}</Table.ColHeader>
                  <Table.ColHeader id="From">{I18n.t('From')}</Table.ColHeader>
                  <Table.ColHeader id="To">{I18n.t('To')}</Table.ColHeader>
                </Table.Row>
              </Table.Head>
              <Table.Body>
                {Object.entries(event_data).map(([key, {from, to}]) => (
                  <Table.Row key={`${key}=${from}-${to}`}>
                    <Table.RowHeader>{key}</Table.RowHeader>
                    <Table.Cell>{from}</Table.Cell>
                    <Table.Cell>{to}</Table.Cell>
                  </Table.Row>
                ))}
              </Table.Body>
            </Table>
          )}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="submit" color="primary" onClick={onClose}>
          {I18n.t('Ok, Thanks')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default CourseActivityDetails
