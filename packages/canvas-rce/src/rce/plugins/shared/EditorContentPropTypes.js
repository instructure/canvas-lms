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

function dig(value, ...properties) {
  return properties.reduce((currentValue, property) => {
    if (currentValue && property in currentValue) {
      return currentValue[property]
    }
    return undefined
  }, value)
}

/*
 * This exists because the editor content exists inside of an iframe, which is a
 * different document with different references to HTMLImageElement. Simply
 * using the `instanceOf(HTMLImageElement)` approach with proptypes will fail
 * because the current window's HTMLImageElement and the iframe's
 * HTMLImageElement are not the same.
 */
export function htmlImageElement(props, propName, componentName) {
  const element = props[propName]
  const elementType = dig(element, 'ownerDocument', 'defaultView', 'HTMLImageElement')

  if (!(elementType && element instanceof elementType)) {
    return new Error(
      'Invalid prop `' +
        propName +
        '` supplied to `' +
        componentName +
        '`, expected instance of `HTMLImageElement`.'
    )
  }
}
