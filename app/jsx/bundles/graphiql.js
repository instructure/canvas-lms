import React from 'react'
import ReactDOM from 'react-dom'
import GraphiQL from 'graphiql'
import axios from 'axios'
import 'graphiql/graphiql.css'

function fetcher(params) {
  return axios
    .post('/api/graphql', JSON.stringify(params), {
      headers: {'Content-Type': 'application/json'}
    })
    .then(({data}) => data)
}

ReactDOM.render(<GraphiQL fetcher={fetcher} />, document.getElementById('graphiql'))
