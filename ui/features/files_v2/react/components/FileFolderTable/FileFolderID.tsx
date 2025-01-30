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
import {type File, type Folder} from '../../../interfaces/File'
import {getIcon} from '../../../utils/fileFolderUtils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {formatFileSize} from "@canvas/util/fileHelper";
import {View} from "@instructure/ui-view";
import {Flex} from "@instructure/ui-flex";

const I18n = createI18nScope('files_v2')

const FileFolderID = ({item} : { item: File | Folder }) => (
  <View as="div" borderWidth="small" borderRadius="medium" padding="xxx-small">
    <Flex>
      <View as="div" margin="none small none xx-small">
        {
          item.thumbnail_url
            ? (<img alt={I18n.t('File thumbnail')} src={item.thumbnail_url} style={{
              border: '1px solid #D9D9D9',
              height: '36px',
              width: '36px'
            }}/>)
            : (
                <span style={{fontSize: '2em'}}>
                  {getIcon(item, !!item.folder_id)}
                </span>
            )
        }
      </View>
      <View as="div">
        {
          (<b>{item.filename || item.name}</b>)
        }
        <br/>
        {
          item.size
            ? formatFileSize(item.size)
            : I18n.t('Folder')
        }
      </View>
    </Flex>
  </View>
)

export default FileFolderID
