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

import React, {useState, useCallback} from 'react'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {Responsive} from '@instructure/ui-responsive'
import {string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import * as tz from '@canvas/datetime'
import {encodeQueryString} from '@canvas/query-string-encoding'

const I18n = useI18nScope('bounced_emails')

BouncedEmailsView.propTypes = {
  accountId: string.isRequired,
}

export default function BouncedEmailsView({accountId}) {
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState()
  const [searchTerm, setSearchTerm] = useState('')
  const [after, setAfter] = useState()
  const [before, setBefore] = useState()
  const [fetchError, setFetchError] = useState('')
  const [csvReportPath, setCsvReportPath] = useState()

  const formatDate = date => {
    return tz.format(date, 'date.formats.medium')
  }

  // so, uh, the report localizes column names, and we're just identifying them by position
  // that's maybe a little brittle :(
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const renderTableHeader = header => {
    return (
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="name">{header[1] /* Name */}</Table.ColHeader>
          <Table.ColHeader id="path">{header[4] /* Path */}</Table.ColHeader>
          <Table.ColHeader id="date" width="9rem">
            {header[5] /* Date of most recent bounce */}
          </Table.ColHeader>
          <Table.ColHeader id="reason" width="50%">
            {header[6] /* Bounce reason */}
          </Table.ColHeader>
        </Table.Row>
      </Table.Head>
    )
  }

  const renderTableRows = useCallback(body_data => {
    return body_data.map(row => (
      <Table.Row key={row[2] /* communication channel id */}>
        <Table.Cell>
          <a href={`/about/${row[0]}`}>{row[1]}</a>
        </Table.Cell>
        <Table.Cell>
          <a href={`mailto:${row[4]}`}>{row[4]}</a>
        </Table.Cell>
        <Table.Cell>
          <FriendlyDatetime dateTime={row[5]} format={I18n.t('#date.formats.medium')} />
        </Table.Cell>
        <Table.Cell>
          <Text wrap="break-word">{row[6]}</Text>
        </Table.Cell>
      </Table.Row>
    ))
  }, [])

  const renderTableBody = useCallback(
    body_data => {
      return <Table.Body>{renderTableRows(body_data)}</Table.Body>
    },
    [renderTableRows]
  )

  const onFetch = useCallback(
    ({json}) => {
      setData(json)
      setFetchError('')
      setLoading(false)
    },
    [setLoading, setData]
  )

  const onError = useCallback(() => {
    setLoading(false)
    setFetchError(I18n.t('Failed to perform search'))
  }, [setLoading, setFetchError])

  const performSearch = useCallback(() => {
    const path = `/api/v1/accounts/${accountId}/bounced_communication_channels/`
    const params = {order: 'desc'}
    if (searchTerm) {
      params.pattern = searchTerm
    }
    if (before) {
      params.before = before.toISOString()
    }
    if (after) {
      params.after = after.toISOString()
    }
    setLoading(true)
    setCsvReportPath(
      `/api/v1/accounts/${accountId}/bounced_communication_channels.csv?${encodeQueryString(
        params
      )}`
    )
    doFetchApi({path, params}).then(onFetch).catch(onError)
  }, [accountId, searchTerm, onFetch, onError, before, after])

  const renderTable = useCallback(
    table_data => {
      if (loading) {
        return <Spinner renderTitle={I18n.t('Loading')} margin="large auto 0 auto" />
      }
      if (!table_data) {
        return null
      }
      if (table_data.length <= 1) {
        // the only returned row is the table header
        return <Text color="secondary">{I18n.t('No results')}</Text>
      }
      return (
        <>
          {csvReportPath && (
            <Link href={csvReportPath}>{I18n.t('Download these results as CSV')}</Link>
          )}
          <Responsive
            query={{small: {maxWidth: '1000px'}, large: {minWidth: '1000px'}}}
            props={{small: {layout: 'stacked'}, large: {layout: 'fixed'}}}
          >
            {props => (
              <Table caption={I18n.t('Bounced Emails')} {...props}>
                {renderTableHeader(table_data[0])}
                {renderTableBody(table_data.slice(1))}
              </Table>
            )}
          </Responsive>
        </>
      )
    },
    [loading, renderTableHeader, renderTableBody, csvReportPath]
  )

  return (
    <>
      <View as="div" margin="0 0 small 0">
        <TextInput
          renderLabel={I18n.t('Address (use * as wildcard)')}
          placeholder={I18n.t('mfoster@*')}
          value={searchTerm}
          onChange={(_event, value) => {
            setSearchTerm(value)
          }}
        />
      </View>
      <View as="div" margin="0 0 small 0">
        <CanvasDateInput
          renderLabel={I18n.t('Last bounced after')}
          formatDate={formatDate}
          onSelectedDateChange={setAfter}
        />
        &emsp;
        <CanvasDateInput
          renderLabel={I18n.t('Last bounced before')}
          formatDate={formatDate}
          onSelectedDateChange={setBefore}
        />
      </View>
      <View as="div" margin="0 0 small 0">
        <Button color="primary" margin="small 0 0 0" onClick={performSearch}>
          {I18n.t('Search')}
        </Button>
      </View>
      {fetchError ? <Text color="danger">{fetchError}</Text> : renderTable(data)}
    </>
  )
}
