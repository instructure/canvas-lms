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

import {View} from '@instructure/ui-view'
import ImageList from '../../instructure_image/Images'
import {useStoreProps} from '../../shared/StoreContext'
import {ICON_MAKER_ICONS} from '../registerEditToolbar'

const SavedButtonList = ({onImageEmbed}) => {
  const storeProps = useStoreProps()
  const {files, bookmark, isLoading, hasMore} = storeProps.images[storeProps.contextType]

  return (
    <View>
      <ImageList
        fetchInitialImages={() => storeProps.fetchInitialImages({category: ICON_MAKER_ICONS})}
        fetchNextImages={() => storeProps.fetchNextImages({category: ICON_MAKER_ICONS})}
        contextType={storeProps.contextType}
        images={{
          [storeProps.contextType]: {
            files,
            bookmark,
            hasMore,
            isLoading
          }
        }}
        sortBy={{
          sort: 'date_added',
          order: 'desc'
        }}
        onImageEmbed={onImageEmbed}
      />
    </View>
  )
}

export default SavedButtonList
