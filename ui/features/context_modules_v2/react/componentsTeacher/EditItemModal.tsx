/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import IndentSelector from './AddItemModalComponents/IndentSelector'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {submiEditItem, prepareItemData} from '../handlers/editItemHandlers'
import {queryClient} from '@canvas/query'
import {ModuleItemMasterCourseRestrictionType} from '../utils/types'
import {MODULE_ITEMS} from '../utils/constants'

const I18n = createI18nScope('context_modules_v2')

export interface EditItemModalProps {
  isOpen: boolean
  onRequestClose: () => void
  itemName: string
  itemURL?: string
  itemNewTab?: boolean
  itemIndent: number
  courseId: string
  moduleId: string
  itemId: string
  itemType?: string
  masterCourseRestrictions?: ModuleItemMasterCourseRestrictionType | null
}

const EditItemModal = (props: EditItemModalProps) => {
  const {
    isOpen,
    onRequestClose,
    itemName,
    itemURL,
    itemNewTab,
    itemIndent,
    itemId,
    courseId,
    moduleId,
    itemType,
    masterCourseRestrictions,
  } = props

  const [title, setTitle] = useState(itemName)
  const [url, setUrl] = useState(itemURL)
  const [newTab, setNewTab] = useState(itemNewTab || false)
  const [indent, setIndent] = useState(itemIndent)
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const [nameError, setNameError] = useState<string | null>(null)

  useEffect(() => {
    setTitle(itemName)
    setUrl(itemURL)
    setNewTab(itemNewTab || false)
    setIndent(itemIndent)
  }, [itemIndent, itemName, itemNewTab, itemURL])

  const showExternalUrlFields =
    itemType &&
    [
      'external',
      'externalurl',
      'externaltool',
      'contextexternaltool',
      'moduleexternaltool',
    ].includes(itemType)

  const handleSubmit = () => {
    if (title.trim() === '') {
      setNameError(I18n.t('Name is required'))
      return
    }

    setIsLoading(true)

    const itemData = prepareItemData({
      title,
      indentation: indent,
      url,
      newTab,
    })

    submiEditItem(courseId, itemId, itemData)
      .then(response => {
        if (response) {
          queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId], exact: false})
          queryClient.invalidateQueries({queryKey: ['MODULE_ITEMS_ALL', moduleId], exact: false})
        }
      })
      .catch(_error => {
        console.error('Error editing item:')
      })
      .finally(() => {
        onRequestClose()
        setNameError(null)
        setIsLoading(false)
      })
  }

  const footer = (
    <>
      <Button
        onClick={() => {
          onRequestClose()
          setNameError(null)
          setTitle(itemName)
        }}
        margin="0 x-small 0 0"
      >
        {I18n.t('Cancel')}{' '}
      </Button>
      <Button color="primary" type="submit" disabled={isLoading}>
        {I18n.t('Update')}
      </Button>
    </>
  )

  return (
    <CanvasModal
      as="form"
      open={isOpen}
      size="small"
      padding="xxx-small"
      closeButtonSize="medium"
      label={I18n.t('Edit Item Details')}
      footer={footer}
      onDismiss={() => {
        onRequestClose()
        setNameError(null)
        setTitle(itemName)
      }}
      themeOverride={{
        smallMaxWidth: '20rem',
      }}
      onSubmit={(e: React.FormEvent) => {
        e.preventDefault()
        handleSubmit()
      }}
      data-testid="edit-item-modal"
    >
      <View as="div" padding="small small small medium">
        <Grid>
          <Grid.Row>
            <Grid.Col width={3} vAlign="middle">
              <Text>{I18n.t('Title')}:</Text>
            </Grid.Col>
            <Grid.Col>
              <TextInput
                id="title"
                name="title"
                renderLabel={<ScreenReaderContent>{I18n.t('Title')}</ScreenReaderContent>}
                value={title}
                onChange={e => {
                  const title = e.target.value
                  if (nameError && title.trim()) {
                    setNameError(null)
                  }
                  setTitle(title)
                }}
                required
                display="inline-block"
                width="12.5rem"
                data-testid="edit-modal-title"
                interaction={
                  masterCourseRestrictions?.all || masterCourseRestrictions?.content
                    ? 'disabled'
                    : 'enabled'
                }
                messages={nameError ? [{text: I18n.t('Name is required'), type: 'newError'}] : []}
              />
            </Grid.Col>
          </Grid.Row>
          {showExternalUrlFields && (
            <Grid.Row>
              <Grid.Col width={3} vAlign="middle">
                <Text>{I18n.t('URL')}:</Text>
              </Grid.Col>
              <Grid.Col>
                <TextInput
                  id="url"
                  name="url"
                  renderLabel={<ScreenReaderContent>{I18n.t('URL')}</ScreenReaderContent>}
                  value={url}
                  onChange={e => setUrl(e.target.value)}
                  display="inline-block"
                  width="12.5rem"
                  data-testid="edit-modal-url"
                />
              </Grid.Col>
            </Grid.Row>
          )}
          <Grid.Row>
            <Grid.Col width={3} vAlign="middle">
              <Text>{I18n.t('Indent')}:</Text>
            </Grid.Col>
            <Grid.Col>
              <IndentSelector
                value={indent}
                onChange={setIndent}
                label={<ScreenReaderContent>{I18n.t('Indent')}</ScreenReaderContent>}
              />
            </Grid.Col>
          </Grid.Row>
          {showExternalUrlFields && (
            <Grid.Row>
              <Grid.Col vAlign="middle">
                <Checkbox
                  label={I18n.t('Load in a new tab')}
                  checked={newTab}
                  onChange={e => {
                    setNewTab(e.target.checked)
                  }}
                  data-testid="edit-modal-new-tab"
                />
              </Grid.Col>
            </Grid.Row>
          )}
        </Grid>
      </View>
    </CanvasModal>
  )
}

export default EditItemModal
