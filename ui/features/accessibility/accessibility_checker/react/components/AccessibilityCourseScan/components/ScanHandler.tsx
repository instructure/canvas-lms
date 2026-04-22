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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Responsive} from '@instructure/ui-responsive'
import {useScope as createI18nScope} from '@canvas/i18n'
import {responsiveQuerySizes} from '@canvas/breakpoints'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {IconExternalLinkLine, IconQuestionLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('accessibility_scan')

const WhatWeLookForPopover = () => {
  const [isShowingContent, setIsShowingContent] = useState(false)

  return (
    <Popover
      placement="bottom"
      isShowingContent={isShowingContent}
      shouldContainFocus
      shouldCloseOnDocumentClick={true}
      onHideContent={() => setIsShowingContent(false)}
      on="click"
      screenReaderLabel={I18n.t('What we look for')}
      renderTrigger={() => (
        <IconButton
          onClick={() => setIsShowingContent(!isShowingContent)}
          screenReaderLabel={I18n.t('What we look for')}
          renderIcon={() => <IconQuestionLine size="x-small" />}
          withBackground={false}
          withBorder={false}
          size="small"
          shape="circle"
        />
      )}
    >
      <Flex direction="column" padding="medium" width="22rem" gap="mediumSmall">
        <Flex.Item>
          <Flex justifyItems="space-between" alignItems="center">
            <Flex.Item>
              <Heading level="h3" margin="none">
                {I18n.t('What we look for')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                margin="x-small"
                screenReaderLabel={I18n.t('Close')}
                onClick={() => setIsShowingContent(false)}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Text>
            {I18n.t(
              'The Course Accessibility Checker scans Pages, Assignments, Discussions, Announcements, and Syllabi for common accessibility errors typically occurring in content created with he Rich Text Editor or other text editors.',
            )}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text>
            {I18n.t(
              'We look for errors in image alt text, table and list formatting, headings, text contrast (in content created with the RCE) and duplicate links.',
            )}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text>
            {I18n.t(
              'We don’t check new quizzes, videos, and uploaded files like PDFs, or linked external content like Google docs. We don’t look for errors with interactivity and complex layouts created outside of the RCE.',
            )}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Link
            href="https://community.instructure.com/en/kb/articles/664351-how-do-i-use-the-accessibility-checker-in-canvas"
            target="_blank"
            rel="noopener noreferrer"
            iconPlacement="end"
            renderIcon={<IconExternalLinkLine size="x-small" />}
          >
            {I18n.t('Read the documentation')}
            <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
          </Link>
        </Flex.Item>
      </Flex>
    </Popover>
  )
}

interface CourseScanWrapperProps {
  children: React.ReactNode
  buttonLabel?: string
  lastChecked?: string | null
  scanButtonDisabled?: boolean
  handleCourseScan?: () => void
  buttonRef?: React.RefObject<HTMLElement | null>
}

export const ScanHandler: React.FC<CourseScanWrapperProps> = ({
  children,
  scanButtonDisabled,
  handleCourseScan,
  buttonLabel,
  lastChecked,
  buttonRef,
}) => {
  const formatScanDate = useDateTimeFormat('date.formats.full')
  const formattedDate = lastChecked ? formatScanDate(lastChecked) : undefined

  return (
    <View as="div">
      <Responsive
        query={responsiveQuerySizes({mobile: true, desktop: true})}
        props={{
          mobile: {
            direction: 'column',
            buttonDisplay: 'block',
            buttonWidth: '100%',
            flexItemWidth: '100%',
          },
          desktop: {
            direction: 'row',
            buttonDisplay: 'inline-block',
            buttonWidth: 'auto',
            flexItemWidth: 'auto',
          },
        }}
        render={props => {
          if (!props) return null
          return (
            <Flex direction={props.direction} gap="medium">
              <Flex.Item padding="x-small 0" shouldShrink shouldGrow>
                <Heading level="h1" margin="0 0 x-small">
                  {I18n.t('Course Accessibility Checker')}
                </Heading>
                {formattedDate && (
                  <Flex alignItems="center" gap="x-small">
                    <Flex.Item>
                      <Text size="small" color="secondary">
                        {I18n.t('Last checked %{date}', {date: formattedDate})} |{' '}
                        {I18n.t('What we look for?')} <WhatWeLookForPopover />
                      </Text>
                    </Flex.Item>
                  </Flex>
                )}
              </Flex.Item>
              {buttonLabel && (
                <Flex.Item align="start" overflowX="visible" width={props.flexItemWidth}>
                  <Button
                    color="primary"
                    margin="small 0"
                    disabled={scanButtonDisabled}
                    onClick={handleCourseScan}
                    display={props.buttonDisplay}
                    width={props.buttonWidth}
                    elementRef={el => {
                      if (buttonRef) {
                        ;(buttonRef as React.MutableRefObject<HTMLElement | null>).current =
                          el as HTMLElement | null
                      }
                    }}
                  >
                    {buttonLabel}
                  </Button>
                </Flex.Item>
              )}
            </Flex>
          )
        }}
      />
      {children}
    </View>
  )
}
