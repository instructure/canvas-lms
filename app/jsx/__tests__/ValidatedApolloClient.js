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

import {ApolloClient} from 'apollo-client'
import {buildSchema} from 'graphql'
import {InMemoryCache} from 'apollo-cache-inmemory'
import {MockLink} from '@apollo/react-testing'
import {validateGraphQLOperation} from './validateGraphQLOperation'

// uses this.__myThing__ pattern to avoid conflicts with ApolloClient's members
export default class ValidatedApolloClient extends ApolloClient {
  constructor(options) {
    options = {
      addTypename: true,
      mocks: [],
      ...options
    }
    // now we can use the final options to create the other objects we need, if
    // they aren't already specified.
    if (!options.link) options.link = new MockLink(options.mocks, options.addTypename)
    if (!options.cache) options.cache = new InMemoryCache({addTypename: options.addTypename})
    super(options)
    this.__schema__ =
      typeof options.schema === 'string' ? buildSchema(options.schema) : options.schema
  }

  watchQuery(options) {
    this.__validateOperation__(options)
    return super.watchQuery(options)
  }

  query(options) {
    this.__validateOperation__(options)
    return super.query(options)
  }

  mutate(options) {
    this.__validateOperation__({query: options.mutation, ...options})
    return super.mutate(options)
  }

  __validateOperation__({query, variables}) {
    const errors = validateGraphQLOperation(this.__schema__, query, variables)
    if (errors.length > 0) {
      appendValidationErrors(errors)
      const allErrorMessages = errors.map(err => err.message)
      throw new Error(allErrorMessages.join('\n'))
    }
  }
}

let validationErrors = []

export function currentValidationErrors() {
  return [...validationErrors]
}

function appendValidationErrors(errs) {
  validationErrors = validationErrors.concat(errs)
  // They might just be checking that the client methods throw and not
  // validating the errors afterward. If they're not checking or cleaning up,
  // prevent an indefinite memory leak.
  if (validationErrors.length > 100) validationErrors.splice(0, validationErrors.length - 100)
}

export function cleanupValidationErrors() {
  const errs = validationErrors
  validationErrors = []
  return errs
}

export function checkForValidationErrors() {
  const errs = cleanupValidationErrors()
  if (errs.length > 0) {
    throw new Error(errs.map(err => err.message).join('\n'))
  }
}
