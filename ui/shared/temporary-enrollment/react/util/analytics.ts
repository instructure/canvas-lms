/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

// constant for data analytics attribute
export const DATA_ANALYTICS_ATTRIBUTE = 'data-analytics'

export type AnalyticProps = {
  // using data analytics attribute constant as a key
  [DATA_ANALYTICS_ATTRIBUTE]: string
}

/**
 * Generate analytic props with optional configurations
 *
 * This function is a Higher-Order Function (HOF) that returns a generator
 * function for creating analytic props; you can specify an optional prefix and
 * delimiter to customize the output.
 *
 * @example
 * // Create a generator function with an optional prefix and delimiter
 * const analyticPropsGenerator = createAnalyticPropsGenerator('page', '_');
 * // Generate props for a specific element
 * const analyticProps = analyticPropsGenerator('home');
 * // Resulting `analyticProps` object: { 'data-analytics': 'page_home' }
 * // Finally, spread it into an element
 * <div {...analyticProps} />
 *
 * @param {string} [prefix=''] Analytics prefix
 * @param {string} [delimiter=''] Delimiter for prop object return value
 * @returns {function} Generator function that produces an object with a
 *                     `data-analytics` property
 */
export const createAnalyticPropsGenerator = (
  prefix: string = '',
  delimiter: string = ''
): ((uniqueKey: string) => AnalyticProps) => {
  // return generator function that takes uniqueKey and generates AnalyticProps
  return (uniqueKey: string): AnalyticProps => {
    // return object literal with 'data-analytics' property with the combined
    // value of prefix, delimiter, and uniqueKey
    return {
      [DATA_ANALYTICS_ATTRIBUTE]: `${prefix}${delimiter}${uniqueKey}`,
    }
  }
}

/**
 * Sets analytic properties on a DOM element’s ref
 *
 * @param {HTMLElement | null} ref DOM element ref
 * @param {AnalyticProps} analyticProps Analytic properties to be set
 *
 * Specific to analytics, this function is useful when the element belongs to an
 * externally controlled component or when direct attribute setting is not possible
 */
export const setAnalyticPropsOnRef = (ref: HTMLElement | null, analyticProps: AnalyticProps) => {
  if (ref) {
    for (const [key, value] of Object.entries(analyticProps)) {
      // update the DOM element’s attribute(s)
      ref.setAttribute(key, value)
    }
  }
}
