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
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import theme from '@instructure/canvas-theme'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

import {useScope as useI18nScope} from '@canvas/i18n'

import api from '../apis/ContextModuleApi'

const I18n = useI18nScope('assignments_2_file_upload')

function buildFooterStyle() {
  const footerStyle = {
    backgroundColor: theme.variables.colors.white,
    borderColor: theme.variables.colors.borderMedium,
  }

  if (document.querySelector('.with-embedded-chat')) {
    footerStyle.bottom = '20px'
  }

  return footerStyle
}

const NextItem = ({compact, tooltipText, url}) => (
  <Tooltip renderTip={tooltipText}>
    <Button data-testid="next-assignment-btn" margin="0 0 0 x-small" color="secondary" href={url}>
      <ScreenReaderContent>{I18n.t('Next Module')}</ScreenReaderContent>
      {!compact && <PresentationContent>{I18n.t('Next')}</PresentationContent>}
      <IconArrowOpenEndSolid />
    </Button>
  </Tooltip>
)

const PreviousItem = ({compact, tooltipText, url}) => (
  <Tooltip renderTip={tooltipText}>
    <Button data-testid="previous-assignment-btn" margin="0 small 0 0" color="secondary" href={url}>
      <ScreenReaderContent>{I18n.t('Previous Module')}</ScreenReaderContent>
      <IconArrowOpenStartSolid />
      {!compact && <PresentationContent>{I18n.t('Previous')}</PresentationContent>}
    </Button>
  </Tooltip>
)

const DefaultFooterLayout = ({buttons, previousItem, nextItem}) => (
  <Flex alignItems="center" height="100%" margin="x-small" justifyItems="space-between">
    {previousItem && (
      <Flex.Item shouldShrink={true}>
        <PreviousItem {...previousItem} />
      </Flex.Item>
    )}

    <Flex.Item shouldGrow={true} margin="0 small">
      <Flex justifyItems="end">
        {buttons.map(button => (
          <Flex.Item key={button.key} margin="auto 0 auto x-small">
            {button.element}
          </Flex.Item>
        ))}
      </Flex>
    </Flex.Item>

    {nextItem && (
      <Flex.Item shouldShrink={true}>
        <NextItem {...nextItem} />
      </Flex.Item>
    )}
  </Flex>
)

const VerticalFooterLayout = ({buttons, previousItem, nextItem}) => (
  <View as="div" width="100%">
    <Flex alignItems="center" width="100%" justifyItems="space-between">
      <Flex.Item margin="x-small">
        {previousItem && <PreviousItem compact={true} {...previousItem} />}
      </Flex.Item>
      <Flex.Item shouldGrow={true} shouldShrink={true}>
        <Flex alignItems="center" direction="column">
          {buttons.map(button => (
            <Flex.Item
              key={button.key}
              margin="xx-small auto"
              overflowX="visible"
              overflowY="visible"
            >
              {button.element}
            </Flex.Item>
          ))}
        </Flex>
      </Flex.Item>
      <Flex.Item margin="x-small">
        {nextItem && <NextItem compact={true} {...nextItem} />}
      </Flex.Item>
    </Flex>
  </View>
)

const StudentFooter = ({assignmentID, buttons, breakpoints, courseID}) => {
  const alertContext = useContext(AlertManagerContext)
  const [previousItem, setPreviousItem] = useState(null)
  const [nextItem, setNextItem] = useState(null)

  const convertModuleData = data => {
    if (data?.url != null) {
      return {
        url: data.url,
        tooltipText: data.tooltipText.string,
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

  const Layout = breakpoints.desktopOnly ? DefaultFooterLayout : VerticalFooterLayout

  return (
    <div
      as="footer"
      data-testid="student-footer"
      id="assignments-student-footer"
      style={buildFooterStyle()}
    >
      <Layout buttons={buttons} nextItem={nextItem} previousItem={previousItem} />
    </div>
  )
}

const buttonPropType = PropTypes.shape({
  element: PropTypes.element,
  key: PropTypes.string,
})

StudentFooter.propTypes = {
  assignmentID: PropTypes.string,
  breakpoints: breakpointsShape,
  buttons: PropTypes.arrayOf(buttonPropType),
  courseID: PropTypes.string,
}

StudentFooter.defaultProps = {
  buttons: [],
}

export default WithBreakpoints(StudentFooter)
