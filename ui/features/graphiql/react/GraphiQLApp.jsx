/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import GraphiQL from 'graphiql'
import GraphiQLExplorer from 'graphiql-explorer'
import {ToolbarButton, PrettifyIcon, ChevronLeftIcon, ChevronDownIcon} from '@graphiql/react'
import {getIntrospectionQuery, buildClientSchema} from 'graphql'
import axios from '@canvas/axios'
import 'graphiql/graphiql.css'
import './graphiql-overrides.css'
import {makeDefaultArg, getDefaultScalarArgValue} from '../CustomArgs'

function fetcher(params) {
  return axios
    .post('/api/graphql', JSON.stringify(params), {
      headers: {'Content-Type': 'application/json'},
    })
    .then(({data}) => data)
}

export default class GraphiQLApp extends React.Component {
  constructor(props) {
    super(props)

    this._graphql = React.createRef()

    this.state = {
      schema: null,
      explorerIsOpen: true,
      error: null,
    }
  }

  componentDidMount() {
    return fetcher({
      query: getIntrospectionQuery(),
    })
      .then(result => {
        if (result && result.data) {
          this.setState({
            schema: buildClientSchema(result.data),
          })
        } else {
          console.error('Failed to fetch schema:', result)
          this.setState({error: 'An error occurred while fetching the schema.'})
        }
      })
      .catch(error => {
        console.error('Error fetching schema:', error)
        this.setState({error: 'An error occurred while fetching the schema.'})
      })
  }

  _handleEditQuery = query => {
    this.setState({query})
  }

  _handleToggleExplorer = () => {
    this.setState(state => ({
      explorerIsOpen: !state.explorerIsOpen,
    }))
  }

  render() {
    const {query, schema, explorerIsOpen, error} = this.state

    if (error) {
      return <div>{error}</div>
    }

    if (!schema) {
      return <div>Loading schema...</div>
    }

    return (
      <div className="graphiql-container">
        <GraphiQLExplorer
          schema={schema}
          query={query}
          onEdit={this._handleEditQuery}
          explorerIsOpen={explorerIsOpen}
          onToggleExplorer={this._handleToggleExplorer}
          getDefaultScalarArgValue={getDefaultScalarArgValue}
          makeDefaultArg={makeDefaultArg}
        />
        <GraphiQL
          ref={this._graphql}
          fetcher={fetcher}
          schema={schema}
          query={query}
          onEditQuery={this._handleEditQuery}
        >
          <GraphiQL.Toolbar>
            <ToolbarButton
              onClick={() => this.graphiqlRef.current?.handlePrettifyQuery()}
              title="Prettify Query (Shift-Ctrl-P)"
            >
              <PrettifyIcon className="graphiql-toolbar-icon" aria-hidden="true" />
            </ToolbarButton>
            <ToolbarButton onClick={this._handleToggleExplorer} title="Toggle Explorer">
              {explorerIsOpen ? (
                <ChevronLeftIcon className="graphiql-chevron-icon" aria-hidden="true" />
              ) : (
                <ChevronDownIcon className="graphiql-chevron-icon" aria-hidden="true" />
              )}
            </ToolbarButton>
          </GraphiQL.Toolbar>
        </GraphiQL>
      </div>
    )
  }
}
