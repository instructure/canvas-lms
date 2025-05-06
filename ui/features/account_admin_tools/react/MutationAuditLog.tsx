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

import {ApolloProvider, Query, gql, createClient} from '@canvas/apollo-v3'
import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import * as tz from '@instructure/moment-utils'
import * as z from 'zod'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'
import {useForm, type SubmitHandler, Controller} from 'react-hook-form'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'

type User = {name: string}

type LogEntry = {
  assetString: string
  mutationId: string
  mutationName: string
  timestamp: string
  user: User
  realUser: User
  params: object
}

type PageInfo = {
  endCursor?: string
  hasNextPage: boolean
}

type QueryData = {
  auditLogs?: {
    __typename: string
    mutationLogs: {
      __typename: string
      nodes: Array<LogEntry>
      pageInfo: PageInfo
    }
  }
}

const I18n = createI18nScope('mutationActivity')

function formatDate(date: Date) {
  return tz.format(date, 'date.formats.medium_with_weekday') ?? ''
}

const defaultValues = {
  assetString: '',
  startDate: undefined,
  endDate: undefined,
}

const createValidationSchema = () =>
  z.object({
    assetString: z.string().min(1, I18n.t('Asset String is required.')),
    startDate: z.date().optional(),
    endDate: z.date().optional(),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

interface AuditLogFormProps {
  onSubmit: (data: FormValues) => void
}

const AuditLogForm = ({onSubmit}: AuditLogFormProps) => {
  const {
    control,
    formState: {errors},
    handleSubmit,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})

  const submit: SubmitHandler<FormValues> = ({assetString, startDate, endDate}) => {
    onSubmit({assetString, startDate, endDate})
  }

  return (
    <View background="secondary" as="div" padding="medium" borderWidth="small">
      <form onSubmit={handleSubmit(submit)} style={{margin: 0}} noValidate={true}>
        <Controller
          name="assetString"
          control={control}
          render={({field}) => (
            <TextInput
              {...field}
              renderLabel={I18n.t('Asset String')}
              placeholder="course_123"
              isRequired={true}
              messages={getFormErrorMessage(errors, 'assetString')}
            />
          )}
        />

        <div style={{marginTop: '1.5em'}} />

        <Grid>
          <Grid.Row>
            <Grid.Col>
              <Controller
                name="startDate"
                control={control}
                render={({field: {ref, ...restField}}) => (
                  <CanvasDateInput2
                    {...restField}
                    renderLabel={I18n.t('Start Date')}
                    onSelectedDateChange={startDate => {
                      if (!startDate) {
                        return
                      }

                      restField.onChange(startDate)
                    }}
                    formatDate={formatDate}
                    selectedDate={restField.value}
                    withRunningValue={true}
                    interaction={undefined}
                  />
                )}
              />
            </Grid.Col>
            <Grid.Col>
              <Controller
                name="endDate"
                control={control}
                render={({field: {ref, ...restField}}) => (
                  <CanvasDateInput2
                    {...restField}
                    renderLabel={I18n.t('End Date')}
                    onSelectedDateChange={endDate => {
                      if (!endDate) {
                        return
                      }

                      restField.onChange(endDate)
                    }}
                    formatDate={formatDate}
                    selectedDate={restField.value}
                    withRunningValue={true}
                    interaction={undefined}
                  />
                )}
              />
            </Grid.Col>
            <Grid.Col vAlign="bottom">
              <Button color="primary" type="submit">
                {I18n.t('Find')}
              </Button>
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </form>
    </View>
  )
}

interface UserCellDataProps {
  user: User
  realUser: User
}

const UserCellData = ({user, realUser}: UserCellDataProps) =>
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

interface LoadMoreButtonProps {
  pageInfo: PageInfo
  onClick: () => void
}

const LoadMoreButton = ({pageInfo: {hasNextPage}, onClick}: LoadMoreButtonProps) => (
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

interface LogEntryRowProps {
  logEntry: LogEntry
}

const LogEntryRow = ({logEntry}: LogEntryRowProps) => {
  const [showingParams, setShowingParams] = useState(false)

  return (
    <>
      <Table.Row>
        <Table.Cell>{logEntry.timestamp}</Table.Cell>
        <Table.Cell>{logEntry.mutationName}</Table.Cell>
        <Table.Cell>
          <UserCellData user={logEntry.user} realUser={logEntry.realUser} />
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
LogEntryRow.displayName = 'Row'

interface AuditLogResultsProps extends FormValues {
  pageSize: number
}

const AuditLogResults = ({assetString, startDate, endDate, pageSize}: AuditLogResultsProps) => {
  if (!assetString) return null

  return (
    <Query<QueryData>
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

        const {nodes: logEntries, pageInfo} = data.auditLogs?.mutationLogs ?? {}

        if (logEntries?.length && pageInfo) {
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
                  <LogEntryRow key={logEntry.mutationId} logEntry={logEntry} />
                ))}
                <LoadMoreButton
                  pageInfo={pageInfo}
                  onClick={() => {
                    return fetchMore({
                      variables: {
                        assetString,
                        startDate,
                        endDate,
                        first: pageSize,
                        after: pageInfo.endCursor,
                      },
                      // @ts-expect-error
                      updateQuery: (prevData: Required<QueryData>, {fetchMoreResult: newData}) => {
                        return {
                          auditLogs: {
                            __typename: prevData.auditLogs.__typename,
                            mutationLogs: {
                              __typename: prevData.auditLogs.mutationLogs.__typename,
                              nodes: [
                                ...prevData.auditLogs.mutationLogs.nodes,
                                ...(newData?.auditLogs?.mutationLogs?.nodes ?? []),
                              ],
                              pageInfo: newData?.auditLogs?.mutationLogs.pageInfo ?? {
                                hasNextPage: false,
                              },
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
  const [auditParams, setAuditParams] = useState<FormValues>({
    assetString: '',
    startDate: undefined,
    endDate: undefined,
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
