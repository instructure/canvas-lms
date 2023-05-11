// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {ICON_MAKER_ATTRIBUTE, ICON_MAKER_DOWNLOAD_URL_ATTR} from '../svg/constants'
import buildDownloadUrl from '../../shared/buildDownloadUrl'

const addIconMakerAttributes = (imageAttributes: {src: string}) => {
  imageAttributes[ICON_MAKER_ATTRIBUTE] = true
  imageAttributes[ICON_MAKER_DOWNLOAD_URL_ATTR] = buildDownloadUrl(imageAttributes.src)
}
export default addIconMakerAttributes
