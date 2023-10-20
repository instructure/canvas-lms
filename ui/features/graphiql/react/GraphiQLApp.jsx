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
import {getIntrospectionQuery, buildClientSchema} from 'graphql'
import axios from '@canvas/axios'
import 'graphiql/graphiql.css'
import {makeDefaultArg, getDefaultScalarArgValue} from '../CustomArgs'
import StorageAPI from 'graphiql/dist/utility/StorageAPI'

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

    this._graphql = null
    this._storage = new StorageAPI()

    // "true" or missing => open. explicit "false" => closed
    const explorerPaneOpen = this._storage.get('explorerPaneOpen') !== 'false'

    this.state = {
      schema: null,
      explorerIsOpen: explorerPaneOpen,
    }
  }

  componentDidMount() {
    return fetcher({
      query: getIntrospectionQuery(),
    }).then(result => {
      this.setState({
        schema: buildClientSchema(result.data),
      })
    })
  }

  _handleEditQuery = query => {
    this.setState({query})
  }

  _handleToggleExplorer = () => {
    this.setState((state, _props) => {
      const isOpen = !state.explorerIsOpen
      this._storage.set('explorerPaneOpen', isOpen.toString())
      return {explorerIsOpen: isOpen}
    })
  }

  render() {
    const {query, schema, explorerIsOpen} = this.state

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
          ref={ref => {
            this._graphiql = ref
          }}
          fetcher={fetcher}
          schema={schema}
          query={query}
          onEditQuery={this._handleEditQuery}
        >
          <GraphiQL.Toolbar>
            <GraphiQL.Button
              onClick={() => this._graphiql.handlePrettifyQuery()}
              label="Prettify"
              title="Prettify Query (Shift-Ctrl-P)"
            />
            <GraphiQL.Button
              onClick={() => this._graphiql.handleToggleHistory()}
              label="History"
              title="Show History"
            />
            <GraphiQL.Button
              onClick={this._handleToggleExplorer}
              label="Explorer"
              title="Toggle Explorer"
            />
          </GraphiQL.Toolbar>
        </GraphiQL>
      </div>
    )
  }
}
