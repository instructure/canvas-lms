/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useParams, type Params} from 'react-router-dom'
import * as z from 'zod'
import {parseWithZodToParamsParseResult, type ParamsParseResult} from './ParamsParseResult'

/**
 * A zod schema that can parse a URL param
 * The schema must be able to parse a string
 */
export type UrlParamSchema<A> = z.ZodSchema<A, any, string>

/**
 * A map of URL search param names to zod schemas
 */
export type UrlParamSchemaMap = Record<string, UrlParamSchema<any>>

/**
 * Computes the return type of {@link parseUrlParams},
 * Uwnraps the zod schema at each key of the input object
 */
export type ParsedUrlParamsValue<Params extends UrlParamSchemaMap> = {
  [K in keyof Params]: z.infer<Params[K]>
}

const parseUrlParam = <A>(
  schema: UrlParamSchema<A>,
  key: string,
  params: Params<string>
): ParamsParseResult<A> => {
  const value = params[key]
  if (typeof value === 'undefined') {
    return {
      success: false,
      errors: [
        {
          param: key,
          error: new z.ZodError([
            {
              code: z.ZodIssueCode.custom,
              path: [],
              message: "React router didn't provide a value, param may be missing in URL template",
              params: {},
            },
          ]),
        },
      ],
    }
  } else {
    return parseWithZodToParamsParseResult({schema, key, value})
  }
}

/**
 * Parses url params from react router using a zod schema
 * @param schemas the schemas for mapped by the url param name
 * @param params the url params from react router
 * @returns The parameters if all params are parsed successfully, otherwise errors
 */
export const parseUrlParams = <ParamSchemas extends UrlParamSchemaMap>(
  schemas: ParamSchemas,
  params: Params<string>
): ParamsParseResult<ParsedUrlParamsValue<ParamSchemas>> => {
  return Object.entries(schemas).reduce(
    (acc, [key, schema]) => {
      const result = parseUrlParam(schema, key, params)
      if (acc.success && result.success) {
        return {success: true, value: {...acc.value, [key]: result.value}} as const
      } else if (acc.success && !result.success) {
        return result
      } else if (!acc.success && !result.success) {
        return {success: false, errors: [...acc.errors, ...result.errors]} as const
      } else {
        return acc
      }
    },
    {success: true, value: {}} as ParamsParseResult<ParsedUrlParamsValue<ParamSchemas>>
  )
}

/**
 * Parses URL path params using zod schemas
 * Each schema must be a zod schema that can parse
 * a string, since react router's useParams
 * always returns strings.
 *
 * @param paramSchemas A record of strings to zod schemas,
 *   where the key matches the name of the path parameter,
 *   and the zod schema to use to parse that parameter.
 * @returns a parse result, where success is true if
 *   every parameter was succesfully parsed
 */
export const useZodParams = <M extends UrlParamSchemaMap>(paramSchemas: M) => {
  const params = useParams()
  const parsedParams = React.useMemo(() => {
    return parseUrlParams(paramSchemas, params)
  }, [paramSchemas, params])
  return parsedParams
}
