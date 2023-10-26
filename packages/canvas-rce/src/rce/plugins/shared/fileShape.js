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
import {arrayOf, bool, number, oneOfType, shape, string, checkPropTypes} from 'prop-types'

export const fileShape = {
  content_type: string.isRequired,
  date: string.isRequired,
  display_name: string.isRequired,
  filename: string.isRequired,
  href: string.isRequired,
  id: oneOfType([number, string]).isRequired,
  thumbnail_url: string,
  preview_url: string,
  hidden_to_user: bool,
  lock_at: string,
  unlock_at: string,
  locked_for_user: bool,
  published: bool,
}

export const imageShape = {...fileShape, thumbnail_url: string}
export const mediaObjectShape = {
  ...imageShape,
  title: string.isRequired,
  embedded_iframe_url: string,
  media_entry_id: string,
}

export const fileOrMediaObjectShape = {
  content_type: string.isRequired,
  date: string.isRequired,
  display_name: string,
  filename: string,
  href: string,
  embedded_iframe_url: string,
  id: oneOfType([number, string]).isRequired,
  thumbnail_url: string,
  preview_url: string,
  hidden_to_user: bool,
  lock_at: string,
  unlock_at: string,
  locked_for_user: bool,
  published: bool,
}

export const documentQueryReturnShape = {
  files: arrayOf(shape(fileShape)).isRequired,
  bookmark: string,
  hasMore: bool,
  isLoading: bool,
  error: string,
}

export const imageQueryReturnShape = {
  files: arrayOf(shape(imageShape)).isRequired,
  bookmark: string,
  hasMore: bool,
  isLoading: bool,
  error: string,
}

export const mediaQueryReturnShape = {
  files: arrayOf(shape(mediaObjectShape)).isRequired,
  bookmark: string,
  hasMore: bool,
  isLoading: bool,
  error: string,
}

function createContentTrayDocumentShape(isRequired) {
  return function validateContentTrayDocuments(props, propName, componentName) {
    const p = props[propName]

    if (!p) {
      if (isRequired) {
        if (!p) {
          return new Error(
            `Required prop \`${propName}\` not supplied to \`${componentName}\`. Validation failed.`
          )
        }
      }
      return undefined
    } else {
      const files = p.user || p.course || p.group || p.User || p.Course || p.Group
      if (!files) {
        return new Error(
          `Invalid prop \`${propName}\` supplied to \`${componentName}\`. Missing "user"|"course"|"group" key.`
        )
      }
      if ('searchString' in p) {
        if (!(typeof p.searchString === 'string')) {
          return new Error(
            `Invalid prop \`${propName}\` supplied to \`${componentName}\`. "searchString" must be a string.`
          )
        }
      }
      if (propName === 'documents') {
        checkPropTypes(
          {docs: shape(documentQueryReturnShape)},
          {docs: files},
          componentName,
          componentName
        )
      } else if (propName === 'images') {
        checkPropTypes(
          {images: shape(imageQueryReturnShape)},
          {images: files},
          componentName,
          componentName
        )
      } else if (propName === 'media') {
        checkPropTypes(
          {media: shape(mediaQueryReturnShape)},
          {media: files},
          componentName,
          componentName
        )
      }
    }
  }
}

export const contentTrayDocumentShape = createContentTrayDocumentShape(false)
contentTrayDocumentShape.isRequired = createContentTrayDocumentShape(true)
