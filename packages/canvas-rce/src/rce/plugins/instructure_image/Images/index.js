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

import React from 'react'

import formatMessage from '../../../../format-message'
import ImageList from '../ImageList'

export default function Images(props) {
  return (
    <div>
      <p>{formatMessage('Click any image to embed the image in the page.')}</p>

      <ImageList
        fetchImages={props.fetchImages}
        images={props.images}
        onImageEmbed={props.onImageEmbed}
      />
    </div>
  )
}

Images.propTypes = {
  ...ImageList.propTypes
}
