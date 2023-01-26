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
import {func, arrayOf, oneOfType, number, shape, string} from 'prop-types'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import formatMessage from '../../../../../format-message'
import LtiTool from './LtiTool'
import {instuiPopupMountNode} from '../../../../../util/fullscreenHelpers'

// TODO: we really need a way for the client to pass this to the RCE
const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

const getFilterResults = (term, thingsToFilter) => {
  if (term.length <= 0) {
    return thingsToFilter
  }
  const query = term ? new RegExp(term, 'i') : null
  return thingsToFilter.filter(item => query && query.test(item.title))
}

export function LtiToolsModal(props) {
  const [filterTerm, setFilterTerm] = useState('')
  const [filteredResults, setFilteredResults] = useState(props.ltiButtons)
  const handleFilterChange = e => {
    setFilterTerm(e.target.value)
    setFilteredResults(getFilterResults(e.target.value, props.ltiButtons))
  }
  const filterEmpty = filteredResults.length <= 0

  return (
    <Modal
      data-mce-component={true}
      liveRegion={getLiveRegion}
      size="medium"
      theme={{mediumMaxWidth: '42rem'}}
      label={formatMessage('Apps')}
      mountNode={instuiPopupMountNode}
      onDismiss={props.onDismiss}
      open={true}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header theme={{padding: '0.5rem'}}>
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

  function renderTools(ltiButtons) {
    return (
      <List isUnstyled={true}>
        {ltiButtons
          .sort((a, b) => a.title.localeCompare(b.title))
          .map(b => {
            return (
              <List.Item key={b.id}>
                <View as="div" padding="medium medium small none">
                  <LtiTool
                    title={b.title}
                    image={b.image}
                    onAction={() => {
                      b.onAction()
                      props.onDismiss()
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

LtiToolsModal.propTypes = {
  ltiButtons: arrayOf(
    shape({
      description: string.isRequired,
      id: oneOfType([string, number]).isRequired,
      image: string.isRequired,
      onAction: func.isRequired,
      title: string.isRequired,
    })
  ),
  onDismiss: func.isRequired,
}
