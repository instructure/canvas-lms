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

// If file is not present locally, run `bundle exec rails graphql:schema`. This
// file is generated automatically on a jenkins run
import canvasSchemaString from '../../../schema.graphql'
import ValidatedMockedProvider from 'validated-apollo/src/ValidatedMockedProvider'

// Muck with the schema string so it will accept @client directives
// This is easier than trying to remove the @client directives from already parsed gql`` queries
const modifiedCanvasSchemaString = `directive @client on FIELD\n\n${canvasSchemaString}`

export default function CanvasValidatedMockedProvider(props) {
  return <ValidatedMockedProvider schema={modifiedCanvasSchemaString} resolvers={[]} {...props} />
}
