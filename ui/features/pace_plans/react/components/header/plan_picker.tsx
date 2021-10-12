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

import React, {useState} from 'react'
import keycode from 'keycode'
import {connect} from 'react-redux'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plans_plan_picker'

import {ApplyTheme} from '@instructure/ui-themeable'
import {IconArrowOpenDownSolid, IconArrowOpenUpSolid} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {TextInput} from '@instructure/ui-text-input'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import {StoreState, Enrollment, Section, PlanContextTypes} from '../../types'
import {Course} from '../../shared/types'
import {getSortedEnrollments} from '../../reducers/enrollments'
import {getSortedSections} from '../../reducers/sections'
import {getCourse} from '../../reducers/course'
import {actions} from '../../actions/ui'
import {getSelectedContextId, getSelectedContextType} from '../../reducers/ui'

const PICKER_WIDTH = '20rem'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item} = Menu as any

interface StoreProps {
  readonly course: Course
  readonly enrollments: Enrollment[]
  readonly sections: Section[]
  readonly selectedContextId: string
  readonly selectedContextType: PlanContextTypes
}

interface DispatchProps {
  readonly setSelectedPlanContext: typeof actions.setSelectedPlanContext
}

type ComponentProps = StoreProps & DispatchProps

type ContextArgs = [PlanContextTypes, string]

const createContextKey = (contextType: PlanContextTypes, contextId: string): string =>
  `${contextType}:${contextId}`

const parseContextKey = (key: string): ContextArgs => key.split(':') as ContextArgs

export const PlanPicker: React.FC<ComponentProps> = ({
  course,
  enrollments,
  sections,
  selectedContextType,
  selectedContextId,
  setSelectedPlanContext
}) => {
  const [open, setOpen] = useState(false)

  let selectedContextName = I18n.t('Course Pace Plan')
  if (selectedContextType === 'Section') {
    selectedContextName = sections.find(({id}) => id === selectedContextId)?.name
  }
  if (selectedContextType === 'Enrollment') {
    selectedContextName = enrollments.find(({id}) => id === selectedContextId)?.full_name
  }
  const selectedContextKey = createContextKey(selectedContextType, selectedContextId)

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const {space, enter} = keycode.codes

    if ([space, enter].includes(e.keyCode)) {
      e.preventDefault()
      e.stopPropagation()
      setOpen(wasOpen => !wasOpen)
    }
  }

  const handleSelect = (_, value: string) => setSelectedPlanContext(...parseContextKey(value))

  const renderOption = (contextKey: string, label: string, key?: string) => (
    <Item value={contextKey} defaultSelected={contextKey === selectedContextKey} key={key}>
      <View as="div" width={PICKER_WIDTH}>
        <TruncateText>{label}</TruncateText>
      </View>
    </Item>
  )

  const trigger = (
    <TextInput
      renderLabel={I18n.t('Pace Plans')}
      renderAfterInput={
        open ? <IconArrowOpenUpSolid inline={false} /> : <IconArrowOpenDownSolid inline={false} />
      }
      value={selectedContextName}
      interaction="readonly"
      role="button"
      onKeyDown={handleKeyDown}
      width={PICKER_WIDTH}
    />
  )

  return (
    <ApplyTheme
      theme={{
        [(Menu as any).theme]: {
          maxWidth: PICKER_WIDTH
        }
      }}
    >
      <Menu
        id="pace-plan-menu"
        placement="bottom"
        withArrow={false}
        trigger={trigger}
        show={open}
        onToggle={setOpen}
        onSelect={handleSelect}
      >
        {renderOption(createContextKey('Course', course.id), I18n.t('Course Pace Plan'))}
        {/* Commenting out since we're not implementing sections yet */}
        {/* <Menu id="pace-plan-menu" label={I18n.t('Sections')}> */}
        {/*  {sections.map(s => */}
        {/*    renderOption(createContextKey('Section', s.id), s.name, `section-${s.id}`) */}
        {/*  )} */}
        {/* </Menu> */}
        <Menu id="pace-plan-menu" label={I18n.t('Students')}>
          {enrollments.map(e =>
            renderOption(createContextKey('Enrollment', e.id), e.full_name, `student-${e.id}`)
          )}
        </Menu>
      </Menu>
    </ApplyTheme>
  )
}

const mapStateToProps = (state: StoreState) => ({
  course: getCourse(state),
  enrollments: getSortedEnrollments(state),
  sections: getSortedSections(state),
  selectedContextId: getSelectedContextId(state),
  selectedContextType: getSelectedContextType(state)
})

export default connect(mapStateToProps, {
  setSelectedPlanContext: actions.setSelectedPlanContext
})(PlanPicker)
