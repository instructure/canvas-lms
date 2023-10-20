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

import {validate, specifiedRules, coerceValue, GraphQLError} from 'graphql'

export function validateGraphQLOperation(schema, query, variables = {}, extraRules = []) {
  const validationRules = [
    ...specifiedRules,
    ValidateNoExtraVariables(variables),
    ValidateVariableValueMatchesType(variables),
    ...extraRules,
  ]
  const errors = validate(schema, query, validationRules)
  return errors
}

function ValidateNoExtraVariables(variables = {}) {
  const variableNames = new Set(Object.keys(variables))
  return context => ({
    VariableDefinition: node => {
      const variableName = node.variable.name.value
      variableNames.delete(variableName)
    },
    Document: {
      leave: () => {
        variableNames.forEach(variableName =>
          context.reportError(
            new GraphQLError(`Extra variable passed to graphql operation: "${variableName}"`)
          )
        )
      },
    },
  })
}

// This also detects missing variables (undefined can't be coerced into a non-nullable value)
function ValidateVariableValueMatchesType(variables = {}) {
  return context => ({
    VariableDefinition: node => {
      const variableName = node.variable.name.value
      const variableValue = variables[variableName]
      const variableType = context.getInputType()
      const {errors = []} = coerceValue(variableValue, variableType)
      errors.forEach(err =>
        context.reportError(
          new GraphQLError(`Unable to coerce variable: "${variableName}": ${err}`)
        )
      )
    },
  })
}
