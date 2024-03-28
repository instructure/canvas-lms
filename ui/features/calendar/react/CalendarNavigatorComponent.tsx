/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconArrowEndLine, IconArrowStartLine} from '@instructure/ui-icons'

const I18n = useI18nScope('calendar.header')

const LegacyBackboneDateComponent = ({size}: {size: string}) => {
  return (
    <>
      <h2 className="navigation_title" tabIndex="-1">
        {/* eslint-disable-next-line jsx-a11y/control-has-associated-label */}
        <span role="button" className="navigation_title_text blue" tabIndex="0" />
      </h2>
      <span className="date_field_wrapper">
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className="screenreader-only" id="calendar_navigation_date_accessible_label">
          {I18n.t('Enter the date you would like to navigate to.')}
          {I18n.t('#helpers.accessible_date_only_format', 'YYYY-MM-DD')}
        </label>
        <input
          type="text"
          name="start date"
          style={{width: size === 'large' ? '100px' : 'auto'}}
          className="date_field"
          aria-labelledby="calendar_navigation_date_accessible_label"
          data-tooltip="top"
          title={I18n.t('#helpers.accessible_date_only_format', 'YYYY-MM-DD')}
        />
      </span>
    </>
  )
}

const ContentLargeSize = (props: CalendarNavigatorComponentProps) => {
  return (
    <Flex gap="small" withVisualDebug={false} direction="row">
      <Flex.Item overflowY="visible">
        <Button onClick={props.bridge.navigateToday}>Today</Button>
      </Flex.Item>

      <span className="navigation_buttons" style={{margin: 0}}>
        <Flex.Item overflowY="visible">
          <IconButton
            onClick={props.bridge.navigatePrev}
            screenReaderLabel={I18n.t('Previous')}
            margin="0 xx-small 0 0"
          >
            <IconArrowStartLine />
          </IconButton>
          <IconButton onClick={props.bridge.navigateNext} screenReaderLabel={I18n.t('Next')}>
            <IconArrowEndLine />
          </IconButton>
        </Flex.Item>
      </span>

      <Flex.Item overflowY="visible">
        <LegacyBackboneDateComponent size="large" />
      </Flex.Item>
    </Flex>
  )
}

const ContentSmallSize = (props: CalendarNavigatorComponentProps) => {
  return (
    <Flex gap="small" withVisualDebug={false} direction="column" alignItems="stretch">
      <Flex.Item overflowY="visible">
        <Button onClick={props.bridge.navigateToday} display="block">
          Today
        </Button>
      </Flex.Item>

      <Flex gap="small" withVisualDebug={false} direction="row" alignItems="stretch">
        <span className="navigation_buttons" style={{margin: 0}}>
          <Flex.Item overflowY="visible">
            <IconButton onClick={props.bridge.navigatePrev} screenReaderLabel={I18n.t('Previous')}>
              <IconArrowStartLine />
            </IconButton>
          </Flex.Item>
        </span>

        <Flex.Item overflowY="visible" shouldGrow={true} alignItems="center" textAlign="center">
          <LegacyBackboneDateComponent size="small" />
        </Flex.Item>

        <span className="navigation_buttons" style={{margin: 0}}>
          <Flex.Item overflowY="visible">
            <IconButton onClick={props.bridge.navigateNext} screenReaderLabel={I18n.t('Next')}>
              <IconArrowEndLine />
            </IconButton>
          </Flex.Item>
        </span>
      </Flex>
    </Flex>
  )
}

type CalendarNavigatorComponentProps = {
  bridge: {
    navigatePrev: () => void
    navigateToday: () => void
    navigateNext: () => void
    onLoadReady: () => void
  }
  // eslint-disable-next-line react/no-unused-prop-types
  size?: string
}

const CalendarNavigatorComponent = (props: CalendarNavigatorComponentProps) => {
  const [size, setSize] = useState(props.size || 'large')

  const handleResize = (e: CustomEvent) => {
    setSize(e.detail.size)
  }

  useEffect(() => {
    // eslint-disable-next-line no-undef
    document.addEventListener('calendar:header:resized', handleResize as EventListener)
    return () =>
      // eslint-disable-next-line no-undef
      document.removeEventListener('calendar:header:resized', handleResize as EventListener)
  }, [])

  useEffect(() => {
    props.bridge.onLoadReady()
  })

  return <>{size === 'large' ? <ContentLargeSize {...props} /> : <ContentSmallSize {...props} />}</>
}

export default CalendarNavigatorComponent
