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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenStartSolid, IconArrowOpenEndSolid} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import theme from '@instructure/canvas-theme'
import {Tooltip} from '@instructure/ui-tooltip'

import I18n from 'i18n!assignments_2_file_upload'

import api from '../apis/ContextModuleApi'

function buildFooterStyle() {
  return {
    backgroundColor: theme.variables.colors.white,
    borderColor: theme.variables.colors.borderMedium
  }
}

const NextItem = ({tooltipText, url}) => (
  <Tooltip tip={tooltipText}>
    <Button data-testid="next-assignment-btn" margin="0 0 0 x-small" color="secondary" href={url}>
      {I18n.t('Next')} <IconArrowOpenEndSolid />
    </Button>
  </Tooltip>
)

const PreviousItem = ({tooltipText, url}) => (
  <Tooltip tip={tooltipText}>
    <Button data-testid="previous-assignment-btn" margin="0 small 0 0" color="secondary" href={url}>
      <IconArrowOpenStartSolid /> {I18n.t('Previous')}
    </Button>
  </Tooltip>
)

const StudentFooter = ({assignmentID, buttons, courseID}) => {
  const alertContext = useContext(AlertManagerContext)
  const [previousItem, setPreviousItem] = useState(null)
  const [nextItem, setNextItem] = useState(null)

  const convertModuleData = data => {
    if (data?.url != null) {
      return {
        url: data.url,
        tooltipText: data.tooltipText.string
      }
    }
  }

  useEffect(() => {
    if (courseID != null && assignmentID != null) {
      api
        .getContextModuleData(courseID, assignmentID)
        .then(({next, previous}) => {
          setPreviousItem(convertModuleData(previous))
          setNextItem(convertModuleData(next))
        })
        .catch(() => {
          alertContext?.setOnFailure(I18n.t('There was a problem loading module information.'))
        })
    }
  }, [alertContext, assignmentID, courseID])

  if (buttons.length === 0 && previousItem == null && nextItem == null) {
    return null
  }

  return (
    <div data-testid="student-footer" id="assignments-student-footer" style={buildFooterStyle()}>
      <Flex alignItems="center" height="100%" margin="0" justifyItems="space-between">
        {previousItem && (
          <Flex.Item shouldShrink>
            <PreviousItem {...previousItem} />
          </Flex.Item>
        )}

        <Flex.Item shouldGrow margin="0 small">
          <Flex justifyItems="end">
            {buttons.map(button => (
              <Flex.Item key={button.key} padding="auto small">
                {button.element}
              </Flex.Item>
            ))}
          </Flex>
        </Flex.Item>

        {nextItem && (
          <Flex.Item shouldShrink>
            <NextItem {...nextItem} />
          </Flex.Item>
        )}
      </Flex>
    </div>
  )
}

const buttonPropType = PropTypes.shape({
  element: PropTypes.element,
  key: PropTypes.string
})

StudentFooter.propTypes = {
  assignmentID: PropTypes.string,
  buttons: PropTypes.arrayOf(buttonPropType),
  courseID: PropTypes.string
}

StudentFooter.defaultProps = {
  buttons: []
}

export default StudentFooter
