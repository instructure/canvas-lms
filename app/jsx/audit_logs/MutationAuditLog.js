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
import Button from '@instructure/ui-buttons/lib/components/Button'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Table from '@instructure/ui-elements/lib/components/Table'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import View from '@instructure/ui-layout/lib/components/View'

const AuditLogForm = ({onSubmit}) => {
  const [assetString, setAssetString] = useState('')

  const submit = e => {
    e.preventDefault()
    onSubmit({assetString})
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
        />

        <Button variant="primary" type="submit" margin="small 0 0">
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
  query searchMutationLog($assetString: String!) {
    auditLogs {
      mutationLogs(assetString: $assetString) {
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
      }
    }
  }
`

const AuditLogResults = ({assetString}) => {
  if (!assetString) return null

  return (
    <Query query={MUTATION_LOG_QUERY} variables={{assetString}}>
      {({loading, error, data}) => {
        if (error) {
          return <p>{I18n.t("Something went wrong.")}</p>
        }
        if (loading || !data) {
          return <Spinner title={I18n.t('Loading...')} />
        }

        const logEntries = data.auditLogs.mutationLogs.nodes
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
                  <tr key={logEntry.mutationId}>
                    <td>
                      {logEntry.timestamp}
                    </td>
                    <td>{logEntry.mutationName}</td>
                    <td>
                      <User user={logEntry.user} realUser={logEntry.realUser} />
                    </td>
                    <td>...{/* TODO */}</td>
                  </tr>
                ))}
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
  const [assetString, setAssetString] = useState(null)

  return (
    <ApolloProvider client={createClient()}>
      <Heading level="h2" margin="0 0 small">
        {I18n.t('GraphQL Mutation Activity')}
      </Heading>

      <AuditLogForm onSubmit={({assetString}) => setAssetString(assetString)} />

      <AuditLogResults assetString={assetString} />
    </ApolloProvider>
  )
}

export default AuditLogApp
export {AuditLogForm, AuditLogResults, MUTATION_LOG_QUERY}
