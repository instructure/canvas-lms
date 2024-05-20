//
// Copyright (C) 2019 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under the
// terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import {ApolloProvider, Query, gql, createClient} from '@canvas/apollo'
import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'

const I18n = useI18nScope('mutationActivity')

function formatDate(date) {
  return tz.format(date, 'date.formats.medium_with_weekday')
}

const AuditLogForm = ({onSubmit}) => {
  const [assetString, setAssetString] = useState('')
  const [startDate, setStartDate] = useState(null)
  const [endDate, setEndDate] = useState(null)
  const makeDateHandler = setter => value => {
    if (value) setter(value)
  }
  const formDisabled = assetString.length === 0

  const submit = e => {
    e.preventDefault()
    if (formDisabled) return
    onSubmit({assetString, startDate, endDate})
  }

  return (
    <View background="secondary" as="div" padding="medium" borderWidth="small">
      <form onSubmit={submit} style={{margin: 0}}>
        <TextInput
          renderLabel={I18n.t('Asset String')}
          placeholder="course_123"
          value={assetString}
          onChange={e => {
            setAssetString(e.target.value)
          }}
          isRequired={true}
        />

        <div style={{marginTop: '1.5em'}} />

        <Grid>
          <Grid.Row>
            <Grid.Col>
              <CanvasDateInput
                renderLabel={I18n.t('Start Date')}
                onSelectedDateChange={makeDateHandler(setStartDate)}
                formatDate={formatDate}
                selectedDate={startDate}
                placement="top center"
                withRunningValue={true}
              />
            </Grid.Col>
            <Grid.Col>
              <CanvasDateInput
                renderLabel={I18n.t('End Date')}
                onSelectedDateChange={makeDateHandler(setEndDate)}
                formatDate={formatDate}
                selectedDate={endDate}
                placement="top center"
                withRunningValue={true}
              />
            </Grid.Col>
            <Grid.Col vAlign="middle">
              <Button color="primary" type="submit" margin="small 0 0" disabled={formDisabled}>
                {I18n.t('Find')}
              </Button>
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </form>
    </View>
  )
}

const User = ({user, realUser}) =>
  realUser
    ? I18n.t('%{user1} masquerading as %{user2}', {user1: realUser.name, user2: user.name})
    : user.name

const MUTATION_LOG_QUERY = gql`
  query searchMutationLog(
    $assetString: String!
    $startDate: DateTime
    $endDate: DateTime
    $first: Int!
    $after: String
  ) {
    auditLogs {
      mutationLogs(
        assetString: $assetString
        startTime: $startDate
        endTime: $endDate
        first: $first
        after: $after
      ) {
        nodes {
          assetString
          mutationId
          mutationName
          timestamp
          user {
            _id
            name
          }
          realUser {
            _id
            name
          }
          params
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
  }
`
const LoadMoreButton = ({pageInfo: {hasNextPage}, onClick}) => (
  <Table.Row>
    <Table.Cell colSpan={4}>
      {hasNextPage ? (
        <Button onClick={onClick}>{I18n.t('Load more')}</Button>
      ) : (
        I18n.t('No more results')
      )}
    </Table.Cell>
  </Table.Row>
)
LoadMoreButton.displayName = 'Row'

const LogEntry = ({logEntry}) => {
  const [showingParams, setShowingParams] = useState(false)

  return (
    <>
      <Table.Row>
        <Table.Cell>{logEntry.timestamp}</Table.Cell>
        <Table.Cell>{logEntry.mutationName}</Table.Cell>
        <Table.Cell>
          <User user={logEntry.user} realUser={logEntry.realUser} />
        </Table.Cell>
        <Table.Cell>
          <Link as="button" isWithinText={false} onClick={() => setShowingParams(!showingParams)}>
            {showingParams ? I18n.t('Hide params') : I18n.t('Show params')}
          </Link>
        </Table.Cell>
      </Table.Row>
      {showingParams ? (
        <Table.Row>
          <Table.Cell colSpan={4}>
            <pre>{JSON.stringify(logEntry.params, null, 2)}</pre>
          </Table.Cell>
        </Table.Row>
      ) : null}
    </>
  )
}
LogEntry.displayName = 'Row'

const AuditLogResults = ({assetString, startDate, endDate, pageSize}) => {
  if (!assetString) return null

  return (
    <Query
      query={MUTATION_LOG_QUERY}
      variables={{assetString, startDate, endDate, first: pageSize}}
    >
      {({loading, error, data, fetchMore}) => {
        if (error) {
          return <p>{I18n.t('Something went wrong.')}</p>
        }
        if (loading || !data) {
          return <Spinner renderTitle={I18n.t('Loading')} />
        }

        const {nodes: logEntries, pageInfo} = data.auditLogs.mutationLogs

        if (logEntries.length) {
          return (
            <Table caption={I18n.t('mutations on %{search}', {search: assetString})}>
              <Table.Head>
                <Table.Row>
                  <Table.ColHeader id="mutations-timestamp">{I18n.t('Timestamp')}</Table.ColHeader>
                  <Table.ColHeader id="mutations-mutation">{I18n.t('Mutation')}</Table.ColHeader>
                  <Table.ColHeader id="mutations-by">{I18n.t('Performed by')}</Table.ColHeader>
                  <Table.ColHeader id="mutations-parms">{I18n.t('Parameters')}</Table.ColHeader>
                </Table.Row>
              </Table.Head>
              <Table.Body>
                {logEntries.map(logEntry => (
                  <LogEntry key={logEntry.mutationId} logEntry={logEntry} />
                ))}
                <LoadMoreButton
                  pageInfo={data.auditLogs.mutationLogs.pageInfo}
                  onClick={() => {
                    return fetchMore({
                      variables: {
                        assetString,
                        startDate,
                        endDate,
                        first: pageSize,
                        after: pageInfo.endCursor,
                      },
                      updateQuery: (prevData, {fetchMoreResult: newData}) => {
                        return {
                          auditLogs: {
                            __typename: prevData.auditLogs.__typename,
                            mutationLogs: {
                              __typename: prevData.auditLogs.mutationLogs.__typename,
                              nodes: [
                                ...prevData.auditLogs.mutationLogs.nodes,
                                ...newData.auditLogs.mutationLogs.nodes,
                              ],
                              pageInfo: newData.auditLogs.mutationLogs.pageInfo,
                            },
                          },
                        }
                      },
                    })
                  }}
                />
              </Table.Body>
            </Table>
          )
        } else {
          return <p>{I18n.t('No results found.')}</p>
        }
      }}
    </Query>
  )
}

const AuditLogApp = () => {
  const [auditParams, setAuditParams] = useState({
    assetString: null,
    startDate: null,
    endDate: null,
  })

  return (
    <ApolloProvider client={createClient()}>
      <Heading level="h2" margin="0 0 small">
        {I18n.t('GraphQL Mutation Activity')}
      </Heading>

      <AuditLogForm onSubmit={setAuditParams} />

      <AuditLogResults {...auditParams} pageSize={250} />
    </ApolloProvider>
  )
}

export default AuditLogApp
export {AuditLogForm, AuditLogResults, MUTATION_LOG_QUERY}
