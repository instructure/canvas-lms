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

import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import mimeClass from '@canvas/mime/mimeClass'
import PropTypes from 'prop-types'
import React from 'react'

import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('assignments_2')

const getIcon = file => {
  if (mimeClass(file.type) === 'image') {
    const fileURL = window.URL.createObjectURL(file)
    return (
      <img
        alt={I18n.t('%{filename} preview', {filename: file.name})}
        height="15"
        src={fileURL}
        width="15"
      />
    )
  }
  return getIconByType(mimeClass(file.type))
}

const FileList = props => {
  const {canRemove, files, removeFileHandler} = props
  const refsMap = {}

  return (
    <List isUnstyled={true} delimiter="solid">
      <List.Item>
        <Text size="x-small" weight="bold">
          {I18n.t('Attached')}
        </Text>
      </List.Item>
      {files.map(file => (
        <List.Item key={file.id}>
          <Flex>
            <Flex.Item size="40px" padding="x-small small">
              {getIcon(file)}
            </Flex.Item>
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Text size="x-small">{file.name}</Text>
            </Flex.Item>
            {file.embedded_iframe_url && (
              <Flex.Item>
                <Link href={file.embedded_iframe_url} target="_blank">
                  <span aria-hidden={true} title={I18n.t('Preview')}>
                    {I18n.t('Preview')}
                  </span>
                  <ScreenReaderContent>
                    {I18n.t('Preview %{filename}', {filename: file.name})}
                  </ScreenReaderContent>
                </Link>
              </Flex.Item>
            )}
            {canRemove && (
              <Flex.Item padding="0 small 0 x-small">
                <IconButton
                  renderIcon={IconTrashLine}
                  id={file.id}
                  onClick={removeFileHandler(refsMap)}
                  ref={element => {
                    refsMap[file.id] = element
                  }}
                  size="small"
                  screenReaderLabel={I18n.t('Remove %{filename}', {filename: file.name})}
                  withBackground={false}
                  withBorder={false}
                />
              </Flex.Item>
            )}
          </Flex>
        </List.Item>
      ))}
    </List>
  )
}

FileList.propTypes = {
  canRemove: PropTypes.bool.isRequired,
  files: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      type: PropTypes.string.isRequired,
    })
  ).isRequired,
  removeFileHandler: PropTypes.func,
}

export default FileList
