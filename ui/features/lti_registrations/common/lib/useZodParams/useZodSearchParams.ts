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
import {useSearchParams} from 'react-router-dom'
import * as z from 'zod'
import type {ParamsParseResult} from './ParamsParseResult'

/**
 * A zod schema that can parse a URL search param
 * The schema must be able to parse an optional string, or
 * array of strings
 */
export type SearchParamSchema<A> =
  | z.ZodSchema<A, any, string | undefined>
  | z.ZodSchema<A, any, string>
  | z.ZodSchema<A, any, string[]>

/**
 * A map of URL search param names to zod schemas
 */
export type SearchParameterSchemaMap = Record<string, SearchParamSchema<any>>

const parseWithZodToParamsParseResult = <A>(options: {
  schema: SearchParamSchema<A>
  key: string
  value: string | string[] | undefined
}): ParamsParseResult<A> => {
  const {schema, key, value} = options
  const result = schema.safeParse(value)
  return result.success
    ? {success: true, value: result.data}
    : {success: false, errors: [{param: key, error: result.error}]}
}

/**
 * Parses a single URL search param using a zod schema
 * @param schema zod schema to parse the param
 * @param key the name of the param
 * @param params the URLSearchParams object
 * @returns the successfully parsed value or errors
 */
export const parseSearchParam = <A>(
  schema: SearchParamSchema<A>,
  key: string,
  params: URLSearchParams
): ParamsParseResult<A> => {
  if (schema._def.typeName === 'ZodArray') {
    return parseWithZodToParamsParseResult({schema, key, value: params.getAll(key)})
  } else {
    const value = params.get(key)
    return parseWithZodToParamsParseResult({schema, key, value: value === null ? undefined : value})
  }
}

/**
 * Parses URL search params using zod schemas
 * Each schema must be a zod schema that can parse
 * a string or string array, since URLSearchParams
 * always returns strings/arrays of string.
 */
export const parseSearchParams = <Params extends SearchParameterSchemaMap>(
  schemas: Params,
  params: URLSearchParams
): ParamsParseResult<ParsedSearchParamsValue<Params>> => {
  return Object.keys(schemas).reduce(
    (acc, key) => {
      const result = parseSearchParam(schemas[key], key, params)
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
    {success: true, value: {}} as ParamsParseResult<ParsedSearchParamsValue<Params>>
  )
}

/**
 * Computes the return type of {@link parseSearchParams},
 * Uwnraps the zod schema at each key of the input object
 */
export type ParsedSearchParamsValue<Params extends SearchParameterSchemaMap> = {
  [K in keyof Params]: z.infer<Params[K]>
}

export type SearchParamsValueStrings<Params extends SearchParameterSchemaMap> = Partial<{
  [K in keyof Params]: string
}>

export type SetSearchParamsValueStrings<Params extends SearchParameterSchemaMap> = (
  params: SearchParamsValueStrings<Params>
) => void

/**
 * Parses URL search params using zod schemas
 * Built on {@link parseSearchParams}
 * and react router's {@link useSearchParams}
 * If the URL search params are invalid, the errors
 *
 *
 * @param paramSchemas A record of strings to zod schemas,
 *   where the key matches the name of the url parameter,
 *   and the zod schema to use to parse that parameter.
 * @returns a parse result, where success is true if
 *   every parameter was succesfully parsed
 *
 * @example
 *
 * const [params, setParams] = useZodSearchParams({
 *   query: z.string().optional(),
 *   sort: z.enum(['name', 'age']).default('name'),
 *   direction: z.enum(['asc', 'desc']).default('asc'),
 * })
 *
 * if(params.success){
 *   params.value
 * } else {
 *   // error
 * }
 *
 */
export const useZodSearchParams = <M extends SearchParameterSchemaMap>(paramSchemas: M) => {
  const [params, setParams] = useSearchParams()
  const parsedParams = React.useMemo(() => {
    return parseSearchParams(paramSchemas, params)
  }, [paramSchemas, params])
  const setParsedParams: SetSearchParamsValueStrings<typeof paramSchemas> = React.useCallback(
    params => {
      // if a key is undefined, remove it from the URL
      // if a key is not provided, don't touch it
      setParams(prev => {
        const newParams = new URLSearchParams(prev)
        Object.entries(params).forEach(([key, value]) => {
          if (value === undefined) {
            newParams.delete(key)
          } else if (value !== undefined) {
            newParams.set(key, value)
          }
        })
        return newParams
      })
    },
    [setParams]
  )
  return [parsedParams, setParsedParams] as const
}
