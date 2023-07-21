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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconEndSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('OutcomeManagement')

const OutcomeSearchBar = ({
  placeholder,
  searchString,
  label,
  enabled,
  onChangeHandler,
  onClearHandler,
}) => {
  const [isFocused, setIsFocused] = useState(false)

  const focusHandler = () => {
    setIsFocused(!isFocused)
  }

  return (
    <View as="div" position="relative">
      <TextInput
        type="search"
        size="medium"
        placeholder={placeholder}
        value={searchString}
        renderLabel={label || <ScreenReaderContent>{I18n.t('Search field')}</ScreenReaderContent>}
        shouldNotWrap={true}
        onChange={onChangeHandler}
        onFocus={focusHandler}
        onBlur={focusHandler}
        interaction={enabled || isFocused ? 'enabled' : 'disabled'}
        renderAfterInput={
          searchString ? (
            <IconButton
              size="small"
              screenReaderLabel={I18n.t('Clear search field')}
              withBackground={false}
              withBorder={false}
              onClick={onClearHandler}
            >
              <IconEndSolid size="x-small" data-testid="clear-search-icon" />
            </IconButton>
          ) : (
            <IconSearchLine size="x-small" data-testid="search-icon" />
          )
        }
      />
    </View>
  )
}

OutcomeSearchBar.defaultProps = {
  enabled: true,
  placeholder: '',
}

OutcomeSearchBar.propTypes = {
  enabled: PropTypes.bool,
  label: PropTypes.string,
  placeholder: PropTypes.string,
  searchString: PropTypes.string.isRequired,
  onChangeHandler: PropTypes.func.isRequired,
  onClearHandler: PropTypes.func.isRequired,
}

export default OutcomeSearchBar
