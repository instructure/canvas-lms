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

import {Button} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import StudentViewContext from './Context'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {bool, func, oneOfType, string} from 'prop-types'

const I18n = useI18nScope('assignments_2_attempt_tab')

const foregroundColor = selected => (selected ? 'primary-inverse' : 'brand')

const ButtonContainer = ({children, selected}) => (
  <View
    as="div"
    className="submission-type-icon-contents"
    background={selected ? 'brand' : 'primary'}
    borderColor="brand"
    borderWidth="small"
    borderRadius="medium"
    height="80px"
    minWidth="90px"
  >
    {children}
  </View>
)
export default function SubmissionTypeButton({displayName, icon, selected, onSelected}) {
  const screenReaderText = selected
    ? I18n.t('Submission type %{displayName}, currently selected', {displayName})
    : I18n.t('Select submission type %{displayName}', {displayName})

  let iconElement
  if (typeof icon === 'string') {
    iconElement = <Img alt="" src={icon} height="32px" width="32px" />
  } else {
    const Icon = icon
    iconElement = <Icon size="small" color={foregroundColor(selected)} />
  }
  return (
    <StudentViewContext.Consumer>
      {context => (
        <ButtonContainer selected={selected}>
          <Button
            display="block"
            interaction={selected || !context.allowChangesToSubmission ? 'readonly' : 'enabled'}
            onClick={onSelected}
            themeOverride={{borderWidth: '0'}}
            withBackground={false}
          >
            {iconElement}
            <View as="div" margin="small 0 0">
              <ScreenReaderContent>{screenReaderText}</ScreenReaderContent>
              <Text color={foregroundColor(selected)} weight="normal" size="medium">
                <PresentationContent>{displayName}</PresentationContent>
              </Text>
            </View>
          </Button>
        </ButtonContainer>
      )}
    </StudentViewContext.Consumer>
  )
}

SubmissionTypeButton.propTypes = {
  displayName: string.isRequired,
  icon: oneOfType([func, string]).isRequired,
  onSelected: func,
  selected: bool,
}

SubmissionTypeButton.defaultProps = {
  onSelected: () => {},
  selected: false,
}

const MoreOptionsButton = ({selected}) => (
  <ButtonContainer selected={selected}>
    <Button as="span" display="block" themeOverride={{borderWidth: '0'}} withBackground={false}>
      <IconMoreLine size="small" color={foregroundColor(selected)} />

      <View as="div" margin="small 0 0">
        <ScreenReaderContent>{I18n.t('More submission options')}</ScreenReaderContent>
        <Text color={foregroundColor(selected)} weight="normal" size="medium">
          <PresentationContent>{I18n.t('More')}</PresentationContent>
        </Text>
      </View>
    </Button>
  </ButtonContainer>
)

export {MoreOptionsButton}
