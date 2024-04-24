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
import {Heading} from '@instructure/ui-heading'
import {IconAddLine} from '@instructure/ui-icons'

import {Responsive} from '@instructure/ui-responsive'
import {SimpleSelect} from '@instructure/ui-simple-select'

const I18n = useI18nScope('calendar.header')

const RenderAddEventButton = ({size}: {size: string}) => {
  if (size === 'large') {
    return (
      <IconButton
        id="create_new_event_link"
        screenReaderLabel={I18n.t('Create New Event')}
        data-tooltip="top"
      >
        <IconAddLine />
      </IconButton>
    )
  }

  return (
    <Button id="create_new_event_link" renderIcon={IconAddLine} display="block">
      {I18n.t('Add Event')}
    </Button>
  )
}

const RenderViewsSelector = ({
  size,
  onChangeSelectViewMode,
}: {
  size: string
  onChangeSelectViewMode: (view: string) => void
}) => {
  const [view, setView] = useState('month')

  const handleViewChange = (e: CustomEvent) => {
    setView(e.detail.viewName)
  }

  useEffect(() => {
    // eslint-disable-next-line no-undef
    document.addEventListener('calendar:header:select_view', handleViewChange as EventListener)
    return () =>
      // eslint-disable-next-line no-undef
      document.removeEventListener('calendar:header:select_view', handleViewChange as EventListener)
  }, [view])

  return (
    <>
      <span style={{display: size === 'large' ? 'block' : 'none'}}>
        <span className="calendar_view_buttons btn-group" role="tablist">
          <button
            type="button"
            id="week"
            className="btn calendar-button"
            role="tab"
            aria-selected="false"
            aria-controls="calendar-app"
            tabIndex="-1"
          >
            {I18n.t('Week')}
          </button>
          <button
            type="button"
            id="month"
            className="btn calendar-button"
            role="tab"
            aria-selected="false"
            aria-controls="calendar-app"
            tabIndex="-1"
          >
            {I18n.t('Month')}
          </button>
          <button
            type="button"
            id="agenda"
            className="btn"
            role="tab"
            aria-selected="false"
            aria-controls="calendar-app"
            tabIndex="-1"
          >
            {I18n.t('Agenda')}
          </button>
        </span>
      </span>

      <span style={{display: size === 'large' ? 'none' : 'block'}}>
        <SimpleSelect
          renderLabel=""
          onChange={(e, data) => onChangeSelectViewMode(data.value)}
          value={view}
        >
          <SimpleSelect.Option id="s_week" value="week">
            {I18n.t('Week')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="s_month" value="month">
            {I18n.t('Month')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="s_agenda" value="agenda">
            {I18n.t('Agenda')}
          </SimpleSelect.Option>
        </SimpleSelect>
      </span>
    </>
  )
}

const RenderContent = ({
  headerProps,
  size,
}: {
  headerProps: CalendarHeaderComponentProps
  size: string
}) => {
  useEffect(() => {
    headerProps.bridge.onLoadReady({size})
    document.dispatchEvent(new CustomEvent('calendar:header:resized', {detail: {size}}))
  }, [headerProps.bridge, size])

  return (
    <>
      <Flex
        margin="0 0 medium"
        as="div"
        direction="column"
        withVisualDebug={false}
        alignItems="stretch"
      >
        <Flex.Item shouldGrow={true} shouldShrink={false} margin="0">
          <Heading level="h1" margin="0 0 small 0">
            {I18n.t('Calendar')}
          </Heading>
        </Flex.Item>

        <Flex.Item overflowY="visible">
          <Flex
            gap="small"
            withVisualDebug={false}
            direction={size === 'large' ? 'row' : 'column'}
            justifyItems="space-between"
          >
            <Flex.Item overflowY="visible">
              <div
                className="calendar_navigator"
                style={{display: size === 'large' ? 'inline-block' : 'block'}}
              />
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <div className="recommend_agenda screenreader-only">
                <button id="use_agenda" className="accessibility-warning" type="button">
                  {I18n.t(
                    'Warning: For improved accessibility, please use the "Agenda view" Calendar.'
                  )}
                </button>
              </div>
              <Flex
                gap="small"
                withVisualDebug={false}
                direction={size === 'large' ? 'row' : 'column'}
                justifyItems="end"
              >
                <Flex.Item overflowY="visible">
                  <span id="refresh_calendar_link" title={I18n.t('Loading')} data-tooltip="top">
                    <span className="screenreader-only">{I18n.t('Loading')}</span>
                  </span>
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <RenderViewsSelector
                    size={size}
                    onChangeSelectViewMode={headerProps.bridge.onChangeSelectViewMode}
                  />
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <span className="add_event_button_responsive">
                    <RenderAddEventButton size={size} />
                  </span>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </>
  )
}

type CalendarHeaderComponentProps = {
  bridge: {
    onLoadReady: ({size}: {size: string}) => void
    onChangeSelectViewMode: (view: string) => void
  }
}

const CalendarHeaderComponent = (headerProps: CalendarHeaderComponentProps) => {
  return (
    <Responsive
      query={{
        small: {maxWidth: '607px'},
        large: {minWidth: '608px'},
      }}
      render={(_, matches) => <RenderContent headerProps={headerProps} size={matches[0]} />}
    />
  )
}

export default CalendarHeaderComponent
