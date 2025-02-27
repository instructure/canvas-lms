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

import React, {useState, useEffect} from 'react'
import {useLocation, Link} from 'react-router-dom'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import FilePreviewModal from './FilePreviewModal'
import {type File, type Folder} from '../../../interfaces/File'
import {getIcon} from '../../../utils/fileFolderUtils'
import {generateUrlPath} from '../../../utils/folderUtils'
import {generatePreviewUrlPath} from '../../../utils/fileUtils'

interface NameLinkProps {
  item: File | Folder
  isStacked: boolean
}

const NameLink = ({item, isStacked}: NameLinkProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const location = useLocation()

  useEffect(() => {
    const searchParams = new URLSearchParams(location.search)
    const previewId = searchParams.get('preview')
    if (previewId == item.id) {
      setIsModalOpen(true)
    }
  }, [location.search, item.id])

  const handleLinkClick = (e: React.MouseEvent) => {
    if (isFile) {
      e.preventDefault()
      setIsModalOpen(true)
      const searchParams = new URLSearchParams(location.search)
      searchParams.set('preview', item.id)
      window.history.pushState({}, '', urlPath())
    }
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
  }
  const isFile = 'display_name' in item
  const name = isFile ? item.display_name : item.name
  const iconUrl = isFile ? item.thumbnail_url : undefined
  const icon = getIcon(item, isFile, iconUrl)
  const pxSize = isStacked ? '18px' : '36px'

  const renderIconComponent = () => {
    if (iconUrl) {
      return (
        <Img
          src={iconUrl}
          width={pxSize}
          height={pxSize}
          margin="0 x-small 0 0"
          alt=""
          data-testid="name-icon"
        />
      )
    }
    return isStacked ? (
      <>{icon}</>
    ) : (
      <span style={{fontSize: '2em', margin: '0 .5rem 0 0'}}>{icon}</span>
    )
  }

  const renderTextComponent = () => {
    return isStacked ? (
      <View margin="0 0 0 xx-small">
        <Text>{name}</Text>
      </View>
    ) : (
      <div style={{whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden'}}>
        <Text>{name}</Text>
      </div>
    )
  }

  const renderFilePreviewModal = () => {
    if (!isFile) return null

    return <FilePreviewModal isOpen={isModalOpen} onClose={handleCloseModal} item={item as File} />
  }

  const urlPath = () => {
    if (isFile) {
      return generatePreviewUrlPath(item as File)
    } else {
      return generateUrlPath(item)
    }
  }

  return (
    <>
      <Link to={urlPath()} data-testid={name} onClick={handleLinkClick}>
        {isStacked ? (
          <>
            {renderIconComponent()}
            {renderTextComponent()}
          </>
        ) : (
          <Flex>
            <Flex.Item margin="0 0 x-small 0">{renderIconComponent()}</Flex.Item>
            <Flex.Item
              margin="0 0 0 small"
              shouldShrink={true}
              shouldGrow={false}
              overflowX="hidden"
            >
              {renderTextComponent()}
            </Flex.Item>
          </Flex>
        )}
      </Link>
      {renderFilePreviewModal()}
    </>
  )
}

export default NameLink
