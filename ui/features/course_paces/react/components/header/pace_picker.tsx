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
import {useScope as useI18nScope} from '@canvas/i18n'

import {ApplyTheme} from '@instructure/ui-themeable'
import {IconArrowOpenDownSolid, IconArrowOpenUpSolid} from '@instructure/ui-icons'
import {Heading} from '@instructure/ui-heading'
import {Menu} from '@instructure/ui-menu'
import {TextInput} from '@instructure/ui-text-input'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import UnpublishedWarningModal from './unpublished_warning_modal'

import {StoreState, Enrollment, Section, PaceContextTypes} from '../../types'
import {Course} from '../../shared/types'
import {getUnpublishedChangeCount} from '../../reducers/course_paces'
import {getSortedEnrollments} from '../../reducers/enrollments'
import {getSortedSections} from '../../reducers/sections'
import {getCourse} from '../../reducers/course'
import {actions} from '../../actions/ui'
import {getSelectedContextId, getSelectedContextType} from '../../reducers/ui'

const I18n = useI18nScope('course_paces_pace_picker')

const PICKER_WIDTH = '20rem'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item} = Menu as any

interface StoreProps {
  readonly course: Course
  readonly enrollments: Enrollment[]
  readonly sections: Section[]
  readonly selectedContextId: string
  readonly selectedContextType: PaceContextTypes
  readonly changeCount: number
}

interface DispatchProps {
  readonly setSelectedPaceContext: typeof actions.setSelectedPaceContext
}

type ComponentProps = StoreProps & DispatchProps

type ContextArgs = [PaceContextTypes, string]

const createContextKey = (contextType: PaceContextTypes, contextId: string): string =>
  `${contextType}:${contextId}`

const parseContextKey = (key: string): ContextArgs => key.split(':') as ContextArgs

export const PacePicker: React.FC<ComponentProps> = ({
  changeCount,
  course,
  enrollments,
  sections,
  selectedContextType,
  selectedContextId,
  setSelectedPaceContext
}) => {
  const [open, setOpen] = useState(false)
  const [pendingContext, setPendingContext] = useState('')
  const hasChanges = changeCount > 0

  let selectedContextName = I18n.t('Course Pace')
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

  const handleSelect = (_, value: string) => {
    if (hasChanges) {
      setPendingContext(value)
    } else {
      setSelectedPaceContext(...parseContextKey(value))
    }
  }

  const renderOption = (contextKey: string, label: string, key?: string) => (
    <Item value={contextKey} defaultSelected={contextKey === selectedContextKey} key={key}>
      <View as="div" width={PICKER_WIDTH}>
        <TruncateText>{label}</TruncateText>
      </View>
    </Item>
  )

  const trigger = (
    <TextInput
      renderLabel={I18n.t('Course Paces')}
      renderAfterInput={
        open ? <IconArrowOpenUpSolid inline={false} /> : <IconArrowOpenDownSolid inline={false} />
      }
      value={selectedContextName}
      data-testid="course-pace-picker"
      interaction="readonly"
      role="button"
      onKeyDown={handleKeyDown}
      width={PICKER_WIDTH}
    />
  )

  if (enrollments.length === 0) {
    return (
      <Heading level="h2" margin="0 x-large 0 0">
        {I18n.t('Course Pace')}
      </Heading>
    )
  }

  return (
    <ApplyTheme
      theme={{
        [(Menu as any).theme]: {
          maxWidth: PICKER_WIDTH
        }
      }}
    >
      <Menu
        id="course-pace-menu"
        placement="bottom"
        withArrow={false}
        trigger={trigger}
        show={open}
        onToggle={setOpen}
        onSelect={handleSelect}
      >
        {renderOption(createContextKey('Course', course.id), I18n.t('Course Pace'))}
        {/* Commenting out since we're not implementing sections yet */}
        {/* <Menu id="course-pace-menu" label={I18n.t('Sections')}> */}
        {/*  {sections.map(s => */}
        {/*    renderOption(createContextKey('Section', s.id), s.name, `section-${s.id}`) */}
        {/*  )} */}
        {/* </Menu> */}
        <Menu id="course-pace-student-menu" label={I18n.t('Students')}>
          {enrollments.map(e =>
            renderOption(createContextKey('Enrollment', e.id), e.full_name, `student-${e.id}`)
          )}
        </Menu>
      </Menu>
      <UnpublishedWarningModal
        open={!!pendingContext}
        onCancel={() => {
          setPendingContext('')
        }}
        onConfirm={() => {
          setSelectedPaceContext(...parseContextKey(pendingContext))
          setPendingContext('')
        }}
      />
    </ApplyTheme>
  )
}

const mapStateToProps = (state: StoreState) => ({
  course: getCourse(state),
  enrollments: getSortedEnrollments(state),
  sections: getSortedSections(state),
  selectedContextId: getSelectedContextId(state),
  selectedContextType: getSelectedContextType(state),
  changeCount: getUnpublishedChangeCount(state)
})

export default connect(mapStateToProps, {
  setSelectedPaceContext: actions.setSelectedPaceContext
})(PacePicker)
