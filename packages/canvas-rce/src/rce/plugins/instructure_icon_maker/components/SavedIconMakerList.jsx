/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import Images from '../../instructure_image/Images'
import {contentTrayDocumentShape} from '../../shared/fileShape'
import {ICON_MAKER_ICONS} from '../svg/constants'

const SavedIconMakerList = props => {
  const {
    sortBy,
    searchString,
    onImageEmbed,
    canvasOrigin,
    fetchInitialImages,
    fetchNextImages,
    contextType,
  } = {
    ...props,
  }
  const {files, bookmark, isLoading, hasMore} = props.images[contextType]

  return (
    <View>
      <Images
        fetchInitialImages={() => fetchInitialImages({category: ICON_MAKER_ICONS})}
        fetchNextImages={() => fetchNextImages({category: ICON_MAKER_ICONS})}
        contextType={contextType}
        images={{
          [contextType]: {
            files,
            bookmark,
            hasMore,
            isLoading,
          },
        }}
        canvasOrigin={canvasOrigin}
        sortBy={sortBy}
        searchString={searchString}
        onImageEmbed={onImageEmbed}
        isIconMaker={true}
      />
    </View>
  )
}

/* eslint-disable react/no-unused-prop-types */
SavedIconMakerList.propTypes = {
  sortBy: PropTypes.shape({
    sort: PropTypes.oneOf(['date_added', 'alphabetical']).isRequired,
    order: PropTypes.oneOf(['asc', 'desc']).isRequired,
  }),
  images: contentTrayDocumentShape.isRequired,
  contextType: PropTypes.string.isRequired,
  searchString: PropTypes.string,
  onImageEmbed: PropTypes.func,
  canvasOrigin: PropTypes.string,
  fetchInitialImages: PropTypes.func,
  fetchNextImages: PropTypes.func,
}

SavedIconMakerList.defaultProps = {
  sortBy: {
    sort: 'date_added',
    order: 'desc',
  },
  searchString: '',
  onImageEmbed: () => {},
}
/* eslint-enable react/no-unused-prop-types */

export default SavedIconMakerList
