/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!OutcomeManagement'
import OutcomeGroupHeader from './OutcomeGroupHeader'
import ManageOutcomeItem from './ManageOutcomeItem'
import OutcomeSearchBar from './OutcomeSearchBar'
import {addZeroWidthSpace} from '../../shared/helpers/addZeroWidthSpace'

const ManageOutcomesView = ({
  outcomeGroup,
  selectedOutcomes,
  searchString,
  onSelectOutcomesHandler,
  onOutcomeGroupMenuHandler,
  onOutcomeMenuHandler,
  onSearchChangeHandler,
  onSearchClearHandler
}) => {
  // Code below works only with mocked data; it needs to be modified
  // to work with data coming from GraphQL by modifying how data is reduced to outcomes
  const {title: groupTitle, description: groupDescription, children} = outcomeGroup
  const outcomeList = children?.map(({id, title, description}, index) => (
    <ManageOutcomeItem
      key={id}
      id={id}
      title={title}
      description={description}
      isFirst={index === 0}
      isChecked={!!selectedOutcomes[id]}
      onMenuHandler={onOutcomeMenuHandler}
      onCheckboxHandler={onSelectOutcomesHandler}
    />
  ))
  const numOutcomes = children?.length || 0

  return (
    <View as="div" padding="0 small" minWidth="300px" data-testid="outcome-group-container">
      <OutcomeGroupHeader
        title={groupTitle}
        description={groupDescription}
        minWidth="calc(50% + 4.125rem)"
        onMenuHandler={onOutcomeGroupMenuHandler}
      />
      <View as="div" padding="medium 0 xx-small" margin="x-small 0 0">
        <OutcomeSearchBar
          enabled={numOutcomes > 0}
          placeholder={I18n.t('Search within %{groupTitle}', {groupTitle})}
          searchString={searchString}
          onChangeHandler={onSearchChangeHandler}
          onClearHandler={onSearchClearHandler}
        />
      </View>
      <View as="div" padding="small 0">
        <Heading level="h4">
          <div style={{overflowWrap: 'break-word'}}>
            {I18n.t(
              {
                one: '1 "%{groupTitle}" Outcome',
                other: '%{count} "%{groupTitle}" Outcomes'
              },
              {
                count: numOutcomes,
                groupTitle: addZeroWidthSpace(groupTitle)
              }
            )}
          </div>
        </Heading>
      </View>
      {outcomeList && (
        <View as="div" data-testid="outcome-items-list">
          {outcomeList}
        </View>
      )}
    </View>
  )
}

ManageOutcomesView.propTypes = {
  outcomeGroup: PropTypes.shape({
    id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    description: PropTypes.string,
    children: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        title: PropTypes.string.isRequired,
        description: PropTypes.string
      })
    )
  }).isRequired,
  selectedOutcomes: PropTypes.object.isRequired,
  searchString: PropTypes.string.isRequired,
  onSelectOutcomesHandler: PropTypes.func.isRequired,
  onOutcomeGroupMenuHandler: PropTypes.func.isRequired,
  onOutcomeMenuHandler: PropTypes.func.isRequired,
  onSearchChangeHandler: PropTypes.func.isRequired,
  onSearchClearHandler: PropTypes.func.isRequired
}

export default ManageOutcomesView
