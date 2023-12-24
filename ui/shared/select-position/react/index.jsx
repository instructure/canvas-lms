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

import React from 'react'
import {string, func, bool, arrayOf, node, shape} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import ConnectorIcon from './ConnectorIcon'
import {Text} from '@instructure/ui-text'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {positions} from '@canvas/positions'

export const itemShape = shape({
  id: string.isRequired,
  title: string.isRequired,
  groupId: string,
})

const I18n = useI18nScope('selectPosition')

RenderSelect.propTypes = {
  label: string.isRequired,
  onChange: func.isRequired,
  options: arrayOf(node),
  className: string,
  selectOneDefault: bool,
  testId: string,
}

RenderSelect.defaultProps = {
  options: [],
  className: '',
  selectOneDefault: false,
  testId: null,
}

export function RenderSelect({label, onChange, options, className, selectOneDefault, testId}) {
  return (
    <View margin="medium 0" display="block" className={className}>
      <FormField id="move-select-form" label={<ScreenReaderContent>{label}</ScreenReaderContent>}>
        <select
          data-testid={testId}
          onChange={onChange}
          className="move-select-form"
          style={{
            margin: '0',
            width: '100%',
          }}
        >
          {selectOneDefault && <option>{I18n.t('Select one')}</option>}
          {options}
        </select>
      </FormField>
    </View>
  )
}

SelectPosition.propTypes = {
  items: arrayOf(itemShape).isRequired,
  siblings: arrayOf(itemShape).isRequired,
  selectedPosition: shape({type: string}),
  selectPosition: func,
  selectSibling: func,
}

SelectPosition.defaultProps = {
  selectedPosition: {type: 'absolute'},
  selectPosition: () => {},
  selectSibling: () => {},
}

export default function SelectPosition({
  items,
  siblings,
  selectedPosition,
  selectPosition,
  selectSibling,
}) {
  const positionSelected = !!(selectedPosition && selectedPosition.type === 'relative')

  function renderSelectSibling() {
    const filteredItems = siblings.filter(item => item.id !== items[0]?.id)
    return (
      <RenderSelect
        label={I18n.t('Item Select')}
        className="move-select__sibling"
        onChange={selectSibling}
        options={filteredItems.map((item, index) => (
          <option key={item.id} value={index}>
            {item.title}
          </option>
        ))}
        selectOneDefault={false}
        testId="select-sibling"
      />
    )
  }

  function renderPlaceTitle() {
    const title =
      items.length === 1 ? I18n.t('Place "%{title}"', {title: items[0].title}) : I18n.t('Place')
    return <Text weight="bold">{title}</Text>
  }

  return (
    <div>
      {renderPlaceTitle()}
      <RenderSelect
        label={I18n.t('Position Select')}
        className="move-select__position"
        onChange={selectPosition}
        options={Object.keys(positions).map(pos => (
          <option key={pos} value={pos}>
            {positions[pos].label}
          </option>
        ))}
        selectOneDefault={false}
        testId="select-position"
      />
      {positionSelected ? (
        <div>
          <ConnectorIcon
            aria-hidden={true}
            style={{position: 'absolute', transform: 'translate(-15px, -35px)'}}
          />
          {renderSelectSibling(items)}
        </div>
      ) : null}
    </div>
  )
}
