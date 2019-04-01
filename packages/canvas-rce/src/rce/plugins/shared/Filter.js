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

import React, {useState} from 'react'
import {func} from 'prop-types'
import {Grid, GridRow, GridCol, View} from '@instructure/ui-layout'
import formatMessage from '../../../format-message'
import {Select} from '@instructure/ui-forms'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {
  IconLinkLine,
  IconFolderLine,
  IconImageLine,
  IconDocumentLine,
  IconAttachMediaLine
} from '@instructure/ui-icons'

export default function Filter(props) {
  const [contentType, setContentType] = useState('links')
  const [contentSubtype, setContentSubtype] = useState('')
  const [sortValue, setSortValue] = useState('date_added')

  return (
    <Grid>
      <GridRow hAlign="space-around">
        <GridCol>
          <View as="div" margin="0 small">
            <Select
              onChange={(e, selection) => {
                setContentType(selection.value)
                props.onChange({contentType: selection.value, contentSubtype, sortValue})
              }}
              value={contentType}
              label={<ScreenReaderContent>{formatMessage('Content Type')}</ScreenReaderContent>}
            >
              <option value="links" icon={IconLinkLine}>
                {formatMessage('Links')}
              </option>
              <option value="files" icon={IconFolderLine}>
                {formatMessage('Files')}
              </option>
            </Select>
          </View>
        </GridCol>
      </GridRow>
      {contentType === 'files' && (
        <GridRow>
          <GridCol>
            <View as="div" margin="0 small">
              <Select
                onChange={(e, selection) => {
                  setContentSubtype(selection.value)
                  props.onChange({contentSubtype: selection.value, contentType, sortValue})
                }}
                value={contentSubtype}
                label={
                  <ScreenReaderContent>{formatMessage('Content Subtype')}</ScreenReaderContent>
                }
              >
                <option value="images" icon={IconImageLine}>
                  {formatMessage('Images')}
                </option>
                <option value="documents" icon={IconDocumentLine}>
                  {formatMessage('Files')}
                </option>
                <option value="media" icon={IconAttachMediaLine}>
                  {formatMessage('Media')}
                </option>
                <option value="all">{formatMessage('All')}</option>
              </Select>
            </View>
          </GridCol>
          <GridCol>
            <View as="div" margin="0 small">
              <Select
                onChange={(e, selection) => {
                  setSortValue(selection.value)
                  props.onChange({sortValue: selection.value, contentType, contentSubtype})
                }}
                value={sortValue}
                label={<ScreenReaderContent>{formatMessage('Sort By')}</ScreenReaderContent>}
              >
                <option value="date_added">{formatMessage('Date Added')}</option>
                <option value="alphabetical">{formatMessage('Alphabetical')}</option>
                <option value="date_published">{formatMessage('Date Published')}</option>
              </Select>
            </View>
          </GridCol>
        </GridRow>
      )}
    </Grid>
  )
}

Filter.propTypes = {
  /**
   * This is called whenever any state is changed inside of the component
   */
  onChange: func.isRequired
}
