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

import {ApolloProvider, Query, gql, createClient} from 'jsx/canvas-apollo'
import React, {useState} from 'react'
import I18n from 'i18n!mutationActivity'
import {Button} from '@instructure/ui-buttons'
import {DateInput, TextInput} from '@instructure/ui-forms'
import {Heading, Table} from '@instructure/ui-elements'
import {Spinner} from '@instructure/ui-spinner'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {View} from '@instructure/ui-layout'

const AuditLogForm = ({onSubmit}) => {
  const [assetString, setAssetString] = useState('')
  const [startDate, setStartDate] = useState(null)
  const [endDate, setEndDate] = useState(null)
  const makeDateHandler = setter => (_e, isoDate, _raw, conversionFailed) => {
    if (!conversionFailed) setter(isoDate)
  }
  const formDisabled = assetString.length === 0

  const submit = e => {
    e.preventDefault()
    if (formDisabled) return
    onSubmit({assetString, startDate, endDate})
  }

  return (
    <View background="light" as="div" padding="medium" borderWidth="small">
      <form onSubmit={submit} style={{margin: 0}}>
        <TextInput
          label={I18n.t('Asset String')}
          placeholder="course_123"
          value={assetString}
          onChange={e => {
            setAssetString(e.target.value)
          }}
          required
        />
        <br />

        <DateInput
          label={I18n.t('Start Date')}
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          onDateChange={makeDateHandler(setStartDate)}
          dateValue={startDate}
        />
        <br />

        <DateInput
          label={I18n.t('End Date')}
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          onDateChange={makeDateHandler(setEndDate)}
          dateValue={endDate}
        />
        <br />

        <Button variant="primary" type="submit" margin="small 0 0" disabled={formDisabled}>
          {I18n.t('Find')}
        </Button>
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
  <tr>
    <td colSpan={4}>
      {hasNextPage ? (
        <Button onClick={onClick}>{I18n.t('Load more')}</Button>
      ) : (
        I18n.t('No more results')
      )}
    </td>
  </tr>
)

const LogEntry = ({logEntry}) => {
  const [showingParams, setShowingParams] = useState(false)

  return (
    <>
      <tr>
        <td>{logEntry.timestamp}</td>
        <td>{logEntry.mutationName}</td>
        <td>
          <User user={logEntry.user} realUser={logEntry.realUser} />
        </td>
        <td>
          <Button variant="link" onClick={() => setShowingParams(!showingParams)}>
            {showingParams ? I18n.t('Hide params') : I18n.t('Show params')}
          </Button>
        </td>
      </tr>
      {showingParams ? (
        <tr>
          <td colSpan={4}>
            <pre>{JSON.stringify(logEntry.params, null, 2)}</pre>
          </td>
        </tr>
      ) : null}
    </>
  )
}

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
            <Table
              caption={
                <ScreenReaderContent>
                  {I18n.t('mutations on %{search}', {search: assetString})}
                </ScreenReaderContent>
              }
            >
              <thead>
                <tr>
                  <th scope="col">{I18n.t('Timestamp')}</th>
                  <th scope="col">{I18n.t('Mutation')}</th>
                  <th scope="col">{I18n.t('Performed by')}</th>
                  <th scope="col">{I18n.t('Parameters')}</th>
                </tr>
              </thead>
              <tbody>
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
                        after: pageInfo.endCursor
                      },
                      updateQuery: (prevData, {fetchMoreResult: newData}) => {
                        return {
                          auditLogs: {
                            __typename: prevData.auditLogs.__typename,
                            mutationLogs: {
                              __typename: prevData.auditLogs.mutationLogs.__typename,
                              nodes: [
                                ...prevData.auditLogs.mutationLogs.nodes,
                                ...newData.auditLogs.mutationLogs.nodes
                              ],
                              pageInfo: newData.auditLogs.mutationLogs.pageInfo
                            }
                          }
                        }
                      }
                    })
                  }}
                />
              </tbody>
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
    endDate: null
  })

  return (
    <ApolloProvider client={createClient()}>
      <Heading level="h2" margin="0 0 small">
        {I18n.t('GraphQL Mutation Activity')}
      </Heading>

      <AuditLogForm onSubmit={auditParams => setAuditParams(auditParams)} />

      <AuditLogResults {...auditParams} pageSize={250} />
    </ApolloProvider>
  )
}

export default AuditLogApp
export {AuditLogForm, AuditLogResults, MUTATION_LOG_QUERY}
