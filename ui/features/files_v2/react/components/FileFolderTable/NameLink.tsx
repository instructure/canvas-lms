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
import {FilePreviewModal} from './FilePreviewModal'
import {type File, type Folder} from '../../../interfaces/File'
import {getIcon, getName} from '../../../utils/fileFolderUtils'
import {generateUrlPath} from '../../../utils/folderUtils'
import {generatePreviewUrlPath} from '../../../utils/fileUtils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {windowPathname} from '@canvas/util/globalUtils'

const I18n = createI18nScope('files_v2')
interface NameLinkProps {
  item: File | Folder
  collection: (File | Folder)[]
  isStacked: boolean
}

const NameLink = ({item, collection, isStacked}: NameLinkProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const location = useLocation()

  useEffect(() => {
    const searchParams = new URLSearchParams(location.search)
    const previewId = searchParams.get('preview')
    if (previewId === item.id.toString()) {
      setIsModalOpen(true)
    } else {
      setIsModalOpen(false)
    }
  }, [location.search, item.id])

  const handleLinkClick = (e: React.MouseEvent) => {
    if (isFile) {
      e.preventDefault()
      setIsModalOpen(true)
      const searchParams = new URLSearchParams(location.search)
      searchParams.set('preview', item.id.toString())
      const newPath = `${windowPathname()}?${searchParams.toString()}`
      window.history.pushState(null, '', newPath)
    } else if (item.locked_for_user) {
      e.preventDefault()
      showFlashError(
        I18n.t('%{name} is currently locked and unavailable to view.', {
          name: getName(item),
        }),
      )()
    }
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
    const searchParams = new URLSearchParams(location.search)
    searchParams.delete('preview')
    const newPath = `${windowPathname()}${searchParams.toString() ? '?' : ''}${searchParams.toString()}`
    window.history.pushState(null, '', newPath)
  }

  const isFile = 'display_name' in item
  const name = getName(item)
  const iconUrl = isFile ? item.thumbnail_url : undefined
  const icon = getIcon(item, isFile, iconUrl)
  const pxSize = isStacked ? '18px' : '36px'

  const renderIconComponent = () => {
    if (iconUrl) {
      return <Img src={iconUrl} width={pxSize} height={pxSize} alt="" data-testid="name-icon" />
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
        <span style={{wordBreak: 'break-all'}}>{name}</span>
      </View>
    ) : (
      <div style={{whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden'}}>
        <Text>{name}</Text>
      </div>
    )
  }

  const renderFilePreviewModal = () => {
    if (!isFile) return null

    const fileCollection = collection?.filter((item): item is File => 'display_name' in item)
    if (!fileCollection?.length) return null

    return (
      <FilePreviewModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        item={item as File}
        collection={fileCollection}
      />
    )
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
