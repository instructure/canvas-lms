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

import React, {useEffect, useRef, useState} from 'react'
import I18n from 'i18n!k5_manage_course_tray'

import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconOffLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

export default function ManageCourseTray({navLinks, onClose, open}) {
  const globalNavRef = useRef()
  const globalNavObserverRef = useRef()
  const [offset, setOffset] = useState(0)

  useEffect(() => {
    globalNavRef.current = document.getElementById('header')
    setOffset(globalNavRef.current?.getBoundingClientRect()?.width || 0)
    globalNavObserverRef.current = new ResizeObserver(entries => {
      entries.forEach(entry => setOffset(entry.contentRect.width))
    })
    globalNavObserverRef.current.observe(globalNavRef.current)
    return () => globalNavObserverRef.current?.unobserve(globalNavRef.current)
  }, [])

  return (
    <Tray
      label={I18n.t('Course Navigation Tray')}
      onDismiss={onClose}
      open={open}
      placement="start"
      size="regular"
      theme={{
        regularWidth: '26em',
        zIndex: 99
      }}
    >
      <div style={{marginLeft: offset}}>
        <View as="section" padding="small medium">
          <Flex direction="row" justifyItems="end" margin="medium small">
            <Flex.Item margin="0 0 0 small">
              <CloseButton onClick={onClose}>{I18n.t('Close')}</CloseButton>
            </Flex.Item>
          </Flex>
          {navLinks.map(link => (
            <View as="div" margin="small" key={`course-nav-${link.id}`}>
              <Flex direction="row">
                <Flex.Item grow shrink>
                  <Link
                    href={link.html_url}
                    theme={{
                      hoverTextDecorationWithinText: 'underline',
                      textDecorationWithinText: 'none'
                    }}
                  >
                    <Text size="medium">{link.label}</Text>
                  </Link>
                </Flex.Item>
                {link.visibility === 'admins' && link.id !== 'settings' && (
                  <Flex.Item>
                    <Tooltip
                      renderTip={I18n.t('Disabled. Not visible to students')}
                      on={['hover', 'focus']}
                      offsetY={6}
                    >
                      <IconOffLine
                        size="small"
                        theme={{sizeSmall: '1.5rem'}}
                        data-testid="k5-course-nav-hidden-icon"
                      />
                    </Tooltip>
                  </Flex.Item>
                )}
              </Flex>
            </View>
          ))}
        </View>
      </div>
    </Tray>
  )
}
