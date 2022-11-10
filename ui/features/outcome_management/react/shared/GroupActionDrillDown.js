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

import React, {useState, useEffect, useRef} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {isRTL} from '@canvas/i18n/rtlHelper'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = useI18nScope('FindOutcomesModal')

const BACK_OPTION = 'back'
const VIEW_OPTION = 'view'
const LOADING_OPTION = 'loading'

const GroupActionDrillDown = ({
  onCollectionClick,
  collections,
  rootId,
  loadedGroups,
  setShowOutcomesView,
  isLoadingGroupDetail,
  outcomesCount,
  showActionLinkForRoot,
  selectedGroupId: incomingGroupId,
  showOptions,
}) => {
  const {rootIds} = useCanvasContext()
  const [selectedGroupId, setSelectedGroupId] = useState(incomingGroupId || rootId)
  const inputRef = useRef(null)
  const [highlightedOptionId, setHighlightedOptionId] = useState('')
  const [highlightAction, setHighlightAction] = useState(false)
  const [isShowingOptions, setIsShowingOptions] = useState(showOptions)
  const [isLoadingGroup, setIsLoadingGroup] = useState(false)
  const hasSelectedGroup = selectedGroupId !== rootId
  const isActionLinkHighlighted = highlightAction || VIEW_OPTION === highlightedOptionId
  const margin = isRTL() ? {marginRight: '-.75em'} : {marginLeft: '-.75em'}
  const disableActionLink = rootIds.includes(selectedGroupId)

  useEffect(() => {
    setIsLoadingGroup(hasSelectedGroup && !loadedGroups.includes(selectedGroupId))
  }, [hasSelectedGroup, loadedGroups, selectedGroupId])

  useEffect(() => {
    if (!disableActionLink && selectedGroupId === rootId) {
      onCollectionClick({id: rootId})
    }
  }, [disableActionLink, selectedGroupId, rootId, onCollectionClick])

  useEffect(() => {
    if (showOptions) {
      inputRef.current.focus()
    }
  }, [showOptions])

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
      if (!rootIds.includes(parentGroupId)) {
        onCollectionClick({id: parentGroupId})
      }
      showFlashAlert({
        message: I18n.t(`Group "%{groupName}" entered.`, {
          groupName: collections[parentGroupId].name,
        }),
        type: 'info',
        srOnly: true,
      })
    } else if (id !== LOADING_OPTION) {
      setSelectedGroupId(id)
      onCollectionClick({id})
      setHighlightAction(true)
      setShowOutcomesView(false)
    }
  }

  const subgroups = isLoadingGroup ? (
    <Select.Option id={LOADING_OPTION} key={LOADING_OPTION}>
      <Flex justifyItems="center">
        <Spinner renderTitle={I18n.t('Loading learning outcome groups')} />
      </Flex>
    </Select.Option>
  ) : (
    collections[selectedGroupId].collections.map(subgroupId => (
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
  )

  const selectedGroup = isLoadingGroupDetail ? (
    <Select.Option id={VIEW_OPTION} key={VIEW_OPTION} isDisabled={true} isHighlighted={false}>
      {collections[selectedGroupId].name}
    </Select.Option>
  ) : (
    <Select.Group key="selected-group" renderLabel={collections[selectedGroupId].name}>
      {!disableActionLink ? (
        <Select.Option
          id={VIEW_OPTION}
          key={VIEW_OPTION}
          isDisabled={disableActionLink}
          isHighlighted={disableActionLink ? false : isActionLinkHighlighted}
        >
          <div
            style={{
              ...margin,
              color: isActionLinkHighlighted ? '' : '#0374B5',
            }}
          >
            {I18n.t(
              {
                one: 'View 1 Outcome',
                other: 'View %{count} Outcomes',
              },
              {
                count: outcomesCount,
              }
            )}
          </div>
        </Select.Option>
      ) : null}
    </Select.Group>
  )

  const getOptions = () => {
    let options = []
    if (hasSelectedGroup) {
      options = [
        <Select.Option
          id={BACK_OPTION}
          key={BACK_OPTION}
          isHighlighted={BACK_OPTION === highlightedOptionId}
          renderBeforeLabel={IconArrowOpenStartLine}
        >
          {I18n.t('Back')}
        </Select.Option>,
      ]
    }
    if (hasSelectedGroup || showActionLinkForRoot) {
      options.push(selectedGroup)
    }
    options.push(subgroups)
    return options
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
      inputRef={e => (inputRef.current = e)}
    >
      {getOptions()}
    </Select>
  )
}

GroupActionDrillDown.propTypes = {
  onCollectionClick: PropTypes.func.isRequired,
  rootId: PropTypes.string.isRequired,
  collections: PropTypes.object.isRequired,
  loadedGroups: PropTypes.arrayOf(PropTypes.string).isRequired,
  setShowOutcomesView: PropTypes.func.isRequired,
  isLoadingGroupDetail: PropTypes.bool.isRequired,
  outcomesCount: PropTypes.number,
  showActionLinkForRoot: PropTypes.bool,
  selectedGroupId: PropTypes.string,
  showOptions: PropTypes.bool,
}

GroupActionDrillDown.defaultProps = {
  outcomesCount: 0,
  showActionLinkForRoot: false,
  selectedGroupId: '',
  showOptions: false,
}

export default GroupActionDrillDown
