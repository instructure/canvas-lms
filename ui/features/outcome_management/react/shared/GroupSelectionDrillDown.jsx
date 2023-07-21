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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {IconCheckSolid, IconArrowOpenStartSolid, IconArrowOpenEndSolid} from '@instructure/ui-icons'
import {Options} from '@instructure/ui-options'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('OutcomeManagement')

const BACK_INDEX = -2
const SELECTED_GROUP_INDEX = -1
const keyCodes = {
  ARROW_UP: 38,
  ARROW_DOWN: 40,
  ENTER: 13,
}

const buildTreeBrowserParentGroup = id => ({
  collections: [],
  id,
  isRootGroup: false,
  name: null,
})

const GroupSelectionDrillDown = ({
  collections,
  rootId,
  selectedGroupId,
  onCollectionClick,
  loadedGroups,
  movingGroupId,
}) => {
  const [highlighted, setHighlighted] = useState(SELECTED_GROUP_INDEX)
  // the selectedGroupId can't be in the collections, this will happen when moving a deep
  // outcome and hit BACK button. The parent group is loading
  const selected =
    collections[selectedGroupId || rootId] || buildTreeBrowserParentGroup(selectedGroupId)

  const isLoaded = loadedGroups.includes(selectedGroupId) || selectedGroupId === null

  useEffect(() => {
    setHighlighted(SELECTED_GROUP_INDEX)
  }, [selectedGroupId])

  const options = selected.collections.filter(id => id !== movingGroupId).map(id => collections[id])

  const handleBackAction = event => {
    // handle move deep outcome clicking in back button,
    // call handleClick with a mock of the parent group, since we dont have it in the
    // collections
    const group =
      collections[selected.parentGroupId] || buildTreeBrowserParentGroup(selected.parentGroupId)

    handleClick(event, group)
  }

  const handleKeyDown = event => {
    let index = highlighted

    if (event.keyCode === keyCodes.ARROW_DOWN && highlighted < options.length - 1) {
      // down arrow
      event.preventDefault()
      index = highlighted + 1
    } else if (event.keyCode === keyCodes.ARROW_UP && highlighted > BACK_INDEX) {
      // up arrow
      event.preventDefault()
      index = highlighted - 1
    } else if (event.keyCode === keyCodes.ENTER && highlighted !== SELECTED_GROUP_INDEX) {
      // enter
      if (highlighted === BACK_INDEX) {
        handleBackAction(event)
      } else {
        handleClick(event, options[index])
      }
    }
    setHighlighted(index)
  }

  const handleClick = (event, group) => {
    onCollectionClick(event, group)
  }

  return (
    <>
      <Options
        onKeyDown={handleKeyDown}
        tabIndex="0"
        data-testid="outcomes-management-target-group-selector"
      >
        {selected.parentGroupId && (
          <Options.Item
            key="Back"
            variant={highlighted === BACK_INDEX ? 'highlighted' : 'default'}
            renderBeforeLabel={<IconArrowOpenStartSolid />}
            onClick={handleBackAction}
          >
            {I18n.t('Back')}
          </Options.Item>
        )}

        {/* selected.name as null will be when loading a parent group (move deep outcome) */}
        {selected.name && (
          <Options.Item variant="selected" renderBeforeLabel={<IconCheckSolid />}>
            {selected.name}
          </Options.Item>
        )}
        {isLoaded &&
          options.map((option, index) => (
            <Options.Item
              key={option.id}
              variant={highlighted === index ? 'highlighted' : 'default'}
              onMouseOver={() => setHighlighted(index)}
              onMouseOut={() => setHighlighted(SELECTED_GROUP_INDEX)}
              onFocus={() => setHighlighted(index)}
              onClick={event => handleClick(event, option)}
              renderAfterLabel={<IconArrowOpenEndSolid />}
            >
              {option.name}
            </Options.Item>
          ))}
      </Options>
      {!isLoaded && (
        <View as="div" textAlign="center" padding="medium 0" margin="0 auto" data-testid="loading">
          <Spinner renderTitle={I18n.t('Loading')} size="medium" />
        </View>
      )}
    </>
  )
}

GroupSelectionDrillDown.propTypes = {
  collections: PropTypes.object.isRequired,
  rootId: PropTypes.string.isRequired,
  selectedGroupId: PropTypes.string,
  onCollectionClick: PropTypes.func.isRequired,
  loadedGroups: PropTypes.array.isRequired,
  movingGroupId: PropTypes.string,
}

export default GroupSelectionDrillDown
