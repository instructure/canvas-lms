// @ts-nocheck
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

import {InstUISettingsProvider} from '@instructure/emotion'
import {IconArrowOpenDownSolid, IconArrowOpenUpSolid} from '@instructure/ui-icons'
import {Avatar} from '@instructure/ui-avatar'
import {Heading} from '@instructure/ui-heading'
import {Menu} from '@instructure/ui-menu'
import {TextInput} from '@instructure/ui-text-input'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import UnpublishedWarningModal from './unpublished_warning_modal'

import {StoreState, Enrollment, Section, PaceContextTypes, ResponsiveSizes} from '../../types'
import {Course} from '../../shared/types'
import {getUnappliedChangesExist} from '../../reducers/course_paces'
import {getSortedEnrollments} from '../../reducers/enrollments'
import {getSortedSections} from '../../reducers/sections'
import {getCourse} from '../../reducers/course'
import {actions} from '../../actions/ui'
import {getSelectedContextId, getSelectedContextType, getResponsiveSize} from '../../reducers/ui'

const I18n = useI18nScope('course_paces_pace_picker')

const PICKER_WIDTH = '20rem'

const componentOverrides = {
  Menu: {
    maxWidth: PICKER_WIDTH,
  },
}

interface StoreProps {
  readonly course: Course
  readonly enrollments: Enrollment[]
  readonly sections: Section[]
  readonly selectedContextId: string
  readonly selectedContextType: PaceContextTypes
  readonly responsiveSize: ResponsiveSizes
  readonly unappliedChangesExist: boolean
}

interface DispatchProps {
  readonly setSelectedPaceContext: typeof actions.setSelectedPaceContext
}

type ComponentProps = StoreProps & DispatchProps

type ContextArgs = [PaceContextTypes, string]

const createContextKey = (contextType: PaceContextTypes, contextId: string): string =>
  `${contextType}:${contextId}`

const parseContextKey = (key: string): ContextArgs => key.split(':') as ContextArgs

export const PacePicker = ({
  course,
  enrollments,
  sections,
  selectedContextType,
  selectedContextId,
  setSelectedPaceContext,
  responsiveSize,
  unappliedChangesExist,
}: ComponentProps) => {
  const [open, setOpen] = useState(false)
  const [pendingContext, setPendingContext] = useState('')

  let selectedContextName = I18n.t('Course')
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

  const handleSelect = (_, value: string | string[]) => {
    const option = Array.isArray(value) ? value[0] : value
    if (unappliedChangesExist) {
      setPendingContext(option)
    } else {
      setSelectedPaceContext(...parseContextKey(option))
    }
  }

  const renderOption = (contextKey: string, label: string, key?: string): JSX.Element => (
    <Menu.Item value={contextKey} defaultSelected={contextKey === selectedContextKey} key={key}>
      <View as="div" width={PICKER_WIDTH}>
        <TruncateText>{label}</TruncateText>
      </View>
    </Menu.Item>
  )

  const renderStudentOption = (enrollment: Enrollment): JSX.Element => {
    const contextKey = createContextKey('Enrollment', enrollment.id)
    const key = `student-${enrollment.id}`
    return (
      <Menu.Item value={contextKey} defaultSelected={contextKey === selectedContextKey} key={key}>
        <View as="div" width={PICKER_WIDTH}>
          <Avatar name={enrollment.full_name} src={enrollment.avatar_url} size="xx-small" />
          <View as="div" display="inline-block" margin="0 0 0 small">
            <TruncateText>{enrollment.full_name}</TruncateText>
          </View>
        </View>
      </Menu.Item>
    )
  }

  const renderSubMenu = (options: JSX.Element[], elementId: string, label: string) => {
    const SubMenu = responsiveSize === 'small' ? Menu.Group : Menu
    return (
      <SubMenu id={elementId} label={label}>
        {options}
      </SubMenu>
    )
  }

  const trigger: JSX.Element = (
    <TextInput
      renderLabel={I18n.t('Course Pacing')}
      renderAfterInput={
        open ? <IconArrowOpenUpSolid inline={false} /> : <IconArrowOpenDownSolid inline={false} />
      }
      defaultValue={selectedContextName}
      data-testid="course-pace-picker"
      interaction="readonly"
      role="button"
      onKeyDown={handleKeyDown}
      width={PICKER_WIDTH}
    />
  )

  if (sections.length === 0 && enrollments.length === 0) {
    return (
      <Heading level="h2" margin="0 x-large 0 0">
        {I18n.t('Course Pacing')}
      </Heading>
    )
  }

  return (
    <InstUISettingsProvider theme={{componentOverrides}}>
      <Menu
        id="course-pace-menu"
        placement="bottom"
        withArrow={false}
        trigger={trigger}
        show={open}
        onToggle={setOpen}
        onSelect={handleSelect}
      >
        {renderOption(createContextKey('Course', course.id), I18n.t('Course'))}
        {sections.length > 0 &&
          renderSubMenu(
            sections.map(s =>
              renderOption(createContextKey('Section', s.id), s.name, `section-${s.id}`)
            ),
            'course-pace-section-menu',
            I18n.t('Sections')
          )}
        {enrollments.length > 0 &&
          renderSubMenu(
            enrollments.map(e => renderStudentOption(e)),
            'course-pace-student-menu',
            I18n.t('Students')
          )}
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
        contextType={selectedContextType}
      />
    </InstUISettingsProvider>
  )
}

const mapStateToProps = (state: StoreState) => ({
  course: getCourse(state),
  enrollments: getSortedEnrollments(state),
  sections: getSortedSections(state),
  selectedContextId: getSelectedContextId(state),
  selectedContextType: getSelectedContextType(state),
  responsiveSize: getResponsiveSize(state),
  unappliedChangesExist: getUnappliedChangesExist(state),
})

export default connect(mapStateToProps, {
  setSelectedPaceContext: actions.setSelectedPaceContext,
})(PacePicker)
