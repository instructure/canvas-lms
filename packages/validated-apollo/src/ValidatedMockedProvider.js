/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, bool, element, object, oneOfType, string} from 'prop-types'
import {ApolloProvider} from 'react-apollo'
import ValidatedApolloClient from './ValidatedApolloClient'

export default class ValidatedMockedProvider extends React.Component {
  static propTypes = {
    // props are used implicitly by passing them to the client constructor
    /* eslint-disable react/no-unused-prop-types */
    schema: oneOfType([string, object]).isRequired,
    children: element.isRequired,
    mocks: arrayOf(object),
    addTypename: bool,
    link: object,
    cache: object,
    /* eslint-enable react/no-unused-prop-types */
  }

  constructor(props) {
    super(props)
    this.client = new ValidatedApolloClient({...props})
  }

  render() {
    return React.createElement(ApolloProvider, {client: this.client}, this.props.children)
  }
}
