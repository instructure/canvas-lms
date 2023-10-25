// @ts-nocheck
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

import React, {ChangeEvent, useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import formatMessage from '../../../../../format-message'
import ExternalToolSelectionItem from './ExternalToolSelectionItem'
import {instuiPopupMountNode} from '../../../../../util/fullscreenHelpers'
import {RceToolWrapper} from '../../RceToolWrapper'

// TODO: we really need a way for the client to pass this to the RCE
const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

/**
 * Returns a filtered list of items based on the term.
 *
 * This was copied from legacy code, and feels like it should be replaced by a string matching library.
 *
 * @param searchString search term
 * @param items objects to filter
 * @return matching items if a non-blank search term is provided, otherwise a copy of the original list
 */
export function filterItemsByTitleSubstring<T extends {title: string}>(
  searchString: string | undefined | null,
  items: T[]
): T[] {
  if (searchString == null || searchString.length === 0) {
    return items
  }
  const lowerTerm = searchString.toLocaleLowerCase()
  return items.filter(item => item.title.toLocaleLowerCase().includes(lowerTerm))
}

export interface ExternalToolSelectionDialogProps {
  ltiButtons: RceToolWrapper[]

  onDismiss: () => void
}

export function ExternalToolSelectionDialog(props: ExternalToolSelectionDialogProps): JSX.Element {
  const [filterTerm, setFilterTerm] = useState('')
  const [filteredResults, setFilteredResults] = useState(props.ltiButtons)
  const handleFilterChange = (e: ChangeEvent<HTMLInputElement>) => {
    setFilterTerm(e.target?.value)
    setFilteredResults(filterItemsByTitleSubstring(e.target.value, props.ltiButtons))
  }
  const filterEmpty = filteredResults.length <= 0

  return (
    <Modal
      data-mce-component={true}
      liveRegion={getLiveRegion}
      size="medium"
      themeOverride={{mediumMaxWidth: '42rem'}}
      label={formatMessage('Apps')}
      mountNode={instuiPopupMountNode}
      onDismiss={props.onDismiss}
      open={true}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header themeOverride={{padding: '0.5rem'}}>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={props.onDismiss}
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading margin="small">{formatMessage('All Apps')}</Heading>
        <View as="div" padding="x-small none x-small medium">
          <TextInput
            type="search"
            renderLabel={<ScreenReaderContent>{formatMessage('Search')}</ScreenReaderContent>}
            placeholder={formatMessage('Search')}
            renderAfterInput={<IconSearchLine inline={false} />}
            onChange={handleFilterChange}
          />
        </View>
      </Modal.Header>
      <Modal.Body overflow="fit">
        <Flex as="div" direction="column">
          <Flex.Item as="div" shouldShrink={true} shouldGrow={true}>
            <Alert liveRegion={getLiveRegion} variant="info" screenReaderOnly={!filterEmpty}>
              {filterEmpty && formatMessage('No results found for {filterTerm}', {filterTerm})}
              {!filterEmpty &&
                formatMessage(
                  `Found { count, plural,
              =0 {# results}
              one {# result}
              other {# results}
            }`,
                  {count: filteredResults.length}
                )}
            </Alert>

            {renderTools(filteredResults)}
          </Flex.Item>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={props.onDismiss} color="primary">
          {formatMessage('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )

  function renderTools(ltiButtons: RceToolWrapper[]) {
    return (
      <List isUnstyled={true}>
        {ltiButtons
          .sort((a, b) => a.title.localeCompare(b.title))
          .map(b => {
            return (
              <List.Item key={b.id}>
                <View as="div" padding="medium medium small none">
                  <ExternalToolSelectionItem
                    title={b.title}
                    image={b.image}
                    onAction={() => {
                      props.onDismiss()
                      b.openDialog()
                    }}
                    description={b.description}
                  />
                </View>
              </List.Item>
            )
          })}
      </List>
    )
  }
}
