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

import React, {useState} from 'react'
import {Select, type SelectProps} from '@instructure/ui-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useManageThreadedRepliesStore} from '../../hooks/useManageThreadedRepliesStore'

const I18n = createI18nScope('discussions_v2')

const OPTIONS = [
  {
    id: 'option1',
    value: 'not_set',
    label: '-',
    disabled: true,
  },
  {
    id: 'option2',
    value: 'threaded',
    label: I18n.t('Threaded'),
    disabled: false,
  },
  {
    id: 'option3',
    value: 'not_threaded',
    label: I18n.t('Not threaded'),
    disabled: false,
  },
]

interface DiscussionThreadedSelectProps {
  id: string
}

const DiscussionThreadedSelect: React.FC<DiscussionThreadedSelectProps> = ({id}) => {
  const [highlightedOption, setHighlightedOption] = useState<undefined | string>()
  const [isOpen, setIsOpen] = useState(false)

  const discussionState = useManageThreadedRepliesStore(state => state.discussionStates)[id]
  const isDirty = useManageThreadedRepliesStore(state => state.isDirty)
  const setDiscussionState = useManageThreadedRepliesStore(state => state.setDiscussionState)

  const handleSelectOption: SelectProps['onRequestSelectOption'] = (_e, {id: optionId}) => {
    if (!optionId) {
      return
    }

    const option = OPTIONS.find(option => option.id === optionId)

    if (!option || option.value === 'not_set') {
      return
    }

    setDiscussionState(id, option.value as 'threaded' | 'not_threaded')
    setIsOpen(false)
  }

  const handleHighlightOption: SelectProps['onRequestHighlightOption'] = (_e, {id}) => {
    setHighlightedOption(id)
  }

  return (
    <Select
      data-testid="discussion-threaded-select"
      renderLabel={
        <ScreenReaderContent>{I18n.t('Select discussion threaded option')}</ScreenReaderContent>
      }
      inputValue={
        OPTIONS.find(option => option.value === discussionState)?.label || OPTIONS[0].label
      }
      messages={isDirty && discussionState === 'not_set' ? [{type: 'error', text: ''}] : undefined}
      isShowingOptions={isOpen}
      onRequestShowOptions={() => setIsOpen(true)}
      onRequestHideOptions={() => setIsOpen(false)}
      onRequestSelectOption={handleSelectOption}
      onRequestHighlightOption={handleHighlightOption}
    >
      {OPTIONS.map(option => (
        <Select.Option
          data-testid={`discussion-threaded-select-option-${option.id}`}
          data-action-state={option.value}
          key={option.id}
          id={option.id}
          value={option.value}
          disabled={option.disabled}
          isSelected={discussionState === option.value}
          isHighlighted={highlightedOption === option.id}
        >
          {option.label}
        </Select.Option>
      ))}
    </Select>
  )
}

export default DiscussionThreadedSelect
