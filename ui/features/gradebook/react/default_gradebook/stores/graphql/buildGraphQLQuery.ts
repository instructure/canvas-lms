/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {DocumentNode, gql} from '@apollo/client'

type QueryNode = {
  alias?: string
  name: string
  args?: Record<string, any>
  fields?: (string | QueryNode)[]
}

function toGraphQLArgs(args: Record<string, any>): string {
  if (!args) return ''
  const entries = Object.entries(args).map(([k, v]) => {
    if (Array.isArray(v)) {
      return `${k}: [${v.map(x => JSON.stringify(x)).join(', ')}]`
    } else if (typeof v === 'object' && v !== null) {
      return `${k}: {${toGraphQLArgs(v)}}`
    } else if (typeof v === 'string') {
      // If the string looks like a variable (starts with $), do NOT wrap in quotes
      if (v.startsWith('$')) {
        return `${k}: ${v}`
      } else {
        return `${k}: ${JSON.stringify(v)}`
      }
    } else {
      return `${k}: ${v}`
    }
  })
  return entries.join(', ')
}

function buildQueryNode(node: QueryNode): string {
  const args = node.args ? `(${toGraphQLArgs(node.args)})` : ''
  const fields = node.fields
    ? node.fields.map(f => (typeof f === 'string' ? f : buildQueryNode(f))).join('\n')
    : ''
  return `${node.alias ? node.alias + ':' : ''}${node.name}${args} {${fields}}`
}

export function buildGraphQLQuery(
  nodes: QueryNode[],
  operation = 'query',
  operationName?: string,
  variables?: string,
): DocumentNode {
  const opName = operationName ? ` ${operationName}` : ''
  const vars = variables ? `(${variables})` : ''
  const queryString = `\n${operation}${opName}${vars} {\n${nodes.map(buildQueryNode).join('\n')}\n}`
  return gql(queryString)
}

// input is a number as string
export function encode(s: string): string {
  return `alias_${s}`
}

export function decode(s: string): string {
  return s.replace(/^alias_/, '')
}
