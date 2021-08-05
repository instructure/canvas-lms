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

import React, {useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!FindOutcomesModal'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {isRTL} from '@canvas/i18n/rtlHelper'
import {ACCOUNT_FOLDER_ID} from '@canvas/outcomes/react/treeBrowser'

const BACK_OPTION = 'back'
const VIEW_OPTION = 'view'
const LOADING_OPTION = 'loading'

const GroupActionDrillDown = ({
  onCollectionClick,
  collections,
  rootId,
  loadedGroups,
  setShowOutcomesView
}) => {
  const [selectedGroupId, setSelectedGroupId] = useState(rootId)
  const [highlightedOptionId, setHighlightedOptionId] = useState('')
  const [highlightAction, setHighlightAction] = useState(false)
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const hasOpenedGroup = selectedGroupId !== rootId
  const isActionLinkHighlighted = highlightAction || VIEW_OPTION === highlightedOptionId
  const margin = isRTL() ? {marginRight: '-.75em'} : {marginLeft: '-.75em'}

  useEffect(() => {
    setIsLoading(hasOpenedGroup && !loadedGroups.includes(selectedGroupId))
  }, [hasOpenedGroup, loadedGroups, selectedGroupId])

  useEffect(() => {
    return () => {
      setShowOutcomesView(false)
    }
  }, [setShowOutcomesView])

  const handleHighlightOption = (_event, {id}) => {
    setHighlightAction(false)
    setHighlightedOptionId(id)
  }

  const handleSelect = (_event, {id}) => {
    if (id === VIEW_OPTION) {
      setShowOutcomesView(true)
      setIsShowingOptions(false)
    } else if (id === BACK_OPTION) {
      const parentGroupId = collections[selectedGroupId].parentGroupId
      setShowOutcomesView(false)
      setSelectedGroupId(parentGroupId)
      if (parentGroupId !== rootId) {
        onCollectionClick({id: parentGroupId})
      }
      showFlashAlert({
        message: I18n.t(`Group "%{groupName}" entered.`, {
          groupName: collections[parentGroupId].name
        }),
        type: 'info',
        srOnly: true
      })
    } else if (id !== LOADING_OPTION) {
      setSelectedGroupId(id)
      onCollectionClick({id})
      setHighlightAction(true)
      setShowOutcomesView(false)
    }
  }

  const renderSubgroups = () => {
    if (isLoading) {
      return (
        <Select.Option id={LOADING_OPTION}>
          <Flex justifyItems="center">
            <Spinner renderTitle={I18n.t('Loading learning outcome groups')} />
          </Flex>
        </Select.Option>
      )
    }

    return collections[selectedGroupId].collections.map(subgroupId => (
      <Select.Option
        key={subgroupId}
        id={subgroupId}
        value={subgroupId}
        isHighlighted={subgroupId === highlightedOptionId}
        renderAfterLabel={IconArrowOpenEndLine}
      >
        {collections[subgroupId].name}
      </Select.Option>
    ))
  }

  return (
    <Select
      isShowingOptions={isShowingOptions}
      assistiveText={I18n.t('Use arrow keys to navigate options')}
      placeholder={I18n.t('Select an outcome group')}
      inputValue={
        isShowingOptions
          ? ''
          : selectedGroupId !== rootId
          ? collections[selectedGroupId].name
          : I18n.t('Select an outcome group')
      }
      renderLabel={I18n.t('Groups')}
      onRequestShowOptions={() => setIsShowingOptions(true)}
      onRequestHideOptions={() => setIsShowingOptions(false)}
      onRequestHighlightOption={handleHighlightOption}
      onRequestSelectOption={handleSelect}
    >
      {hasOpenedGroup && (
        <Select.Option
          id={BACK_OPTION}
          isHighlighted={BACK_OPTION === highlightedOptionId}
          renderBeforeLabel={IconArrowOpenStartLine}
        >
          {I18n.t('Back')}
        </Select.Option>
      )}
      {hasOpenedGroup && (
        <Select.Group renderLabel={collections[selectedGroupId].name}>
          <Select.Option
            id={VIEW_OPTION}
            isDisabled={selectedGroupId === ACCOUNT_FOLDER_ID}
            isHighlighted={selectedGroupId !== ACCOUNT_FOLDER_ID ? isActionLinkHighlighted : false}
          >
            {selectedGroupId !== ACCOUNT_FOLDER_ID && (
              <div
                style={{
                  ...margin,
                  color: isActionLinkHighlighted ? '' : '#008EE2'
                }}
              >
                {I18n.t(
                  {
                    one: 'View 1 Outcome',
                    other: 'View %{count} Outcomes'
                  },
                  {
                    count: collections[selectedGroupId].outcomesCount
                  }
                )}
              </div>
            )}
          </Select.Option>
        </Select.Group>
      )}
      {renderSubgroups()}
    </Select>
  )
}

GroupActionDrillDown.propTypes = {
  onCollectionClick: PropTypes.func.isRequired,
  rootId: PropTypes.string.isRequired,
  collections: PropTypes.object.isRequired,
  loadedGroups: PropTypes.arrayOf(PropTypes.string).isRequired,
  setShowOutcomesView: PropTypes.func.isRequired
}

export default GroupActionDrillDown
