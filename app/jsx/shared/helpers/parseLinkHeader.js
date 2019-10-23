/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

/**
 * This is a version of app/coffeescripts/fn/parseLinkHeader.coffee
 * designed to work with axios instead of jQuery.
 *
 */

const regex = /<(http.*?)>; rel="([a-z]*)"/g

const parseLinkHeader = axiosResponse => {
  const links = {}
  const header = axiosResponse.headers ? axiosResponse.headers.link : null
  if (!header) {
    return links
  }
  let link = regex.exec(header)
  while (link) {
    links[link[2]] = link[1]
    link = regex.exec(header)
  }
  return links
}

export default parseLinkHeader
