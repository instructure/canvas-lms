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

import React, {useId, ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import ConnectorIcon from './ConnectorIcon'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Text as InstText} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {positions} from '@canvas/positions'

// Assuming this type is defined in the move-item-tray package
type SiblingType = Array<ItemType> | Error | null

export interface ItemType {
  id: string
  title: string
  groupId?: string
}

const I18n = createI18nScope('selectPosition')

interface RenderSelectProps {
  label: string | ReactNode
  onChange: (event: React.ChangeEvent<HTMLSelectElement>) => void
  options?: ReactNode[]
  className?: string
  selectOneDefault?: boolean
  testId?: string | null
}

export function RenderSelect({
  label,
  onChange,
  options = [],
  className = '',
  selectOneDefault = false,
  testId = null,
}: RenderSelectProps) {
  const id = useId()

  return (
    <View margin="medium 0" display="block" className={className}>
      <FormField id={id} label={label}>
        <select
          id={id}
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

interface SelectedPositionType {
  type: string
}

interface SelectPositionProps {
  items: ItemType[]
  siblings?: SiblingType
  selectedPosition?: SelectedPositionType
  selectPosition?: (event: React.ChangeEvent<HTMLSelectElement>) => void
  selectSibling?: (event: React.ChangeEvent<HTMLSelectElement>) => void
}

export default function SelectPosition({
  items,
  siblings,
  selectedPosition = {type: 'absolute'},
  selectPosition = () => {},
  selectSibling = () => {},
}: SelectPositionProps) {
  const positionSelected = !!(selectedPosition && selectedPosition.type === 'relative')

  function renderMessage(string: string, color: 'primary' | 'danger'): ReactNode {
    return (
      <View
        as="div"
        borderWidth="small"
        borderColor="secondary"
        borderRadius="small"
        padding="x-small"
      >
        <InstText color={color}>{string}</InstText>
      </View>
    )
  }

  function renderSelectSibling(): ReactNode {
    if (siblings instanceof Error) {
      return renderMessage(I18n.t('Failed loading items'), 'danger')
    }
    if (Array.isArray(siblings)) {
      const filteredItems = siblings.filter(item => item.id !== items?.[0]?.id)

      if (filteredItems.length === 0) {
        return renderMessage(I18n.t('No items found'), 'primary')
      }

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

    return (
      <Flex gap="x-small" margin="0 x-small 0 0">
        <Spinner size="x-small" renderTitle={I18n.t('Loading items')} />
        <PresentationContent>{I18n.t('Loading...')}</PresentationContent>
      </Flex>
    )
  }

  function renderPlaceTitle(): ReactNode {
    const title =
      items.length === 1 ? I18n.t('Place "%{title}"', {title: items[0].title}) : I18n.t('Place')
    return <Heading level="h4">{title}</Heading>
  }

  return (
    <div>
      <RenderSelect
        label={renderPlaceTitle()}
        className="move-select__position"
        onChange={selectPosition}
        options={Object.keys(positions).map(pos => (
          <option key={pos} value={pos}>
            {(positions as any)[pos].label}
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
          {renderSelectSibling()}
        </div>
      ) : null}
    </div>
  )
}
