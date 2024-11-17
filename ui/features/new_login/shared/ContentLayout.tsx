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

import React, {Suspense} from 'react'
import classNames from 'classnames'
import {Background, Loading} from '.'
import {Responsive} from '@instructure/ui-responsive'
import {View} from '@instructure/ui-view'
import {canvas} from '@instructure/ui-theme-tokens'
import {useScope as useI18nScope} from '@canvas/i18n'

// @ts-expect-error
import styles from './ContentLayout.module.css'

const I18n = useI18nScope('new_login')

const breakpoints = {
  tablet: {minWidth: canvas.breakpoints.tablet}, // 768px
  desktop: {minWidth: canvas.breakpoints.desktop}, // 1024px
}

interface Props {
  children: React.ReactNode
}

const ContentLayout = ({children}: Props) => {
  // <Responsive> renders as a <div> with display="block", so we set its height to 100% to fill the
  // available space within its parent, which is a flex item
  const setResponsiveRef = (el: HTMLDivElement | null) => {
    if (el) el.style.height = '100%'
  }

  return (
    <Responsive match="media" query={breakpoints} elementRef={setResponsiveRef}>
      {(_props, matches) => {
        const isDesktop = matches?.includes('desktop')
        const isTablet = matches?.includes('tablet')
        const isTabletOnly = isTablet && !isDesktop

        return (
          <View
            as="div"
            height="100%"
            position="relative"
            className={classNames({
              [styles['contentLayout--desktop']]: isDesktop,
              [styles['contentLayout--tablet']]: isTabletOnly,
            })}
          >
            <View
              as="div"
              className={classNames(styles.contentLayout__content, {
                [styles['contentLayout__content--desktop']]: isDesktop,
                [styles['contentLayout__content--tablet']]: isTabletOnly,
              })}
              background="primary"
              position="relative"
              stacking="above"
            >
              <Suspense fallback={<Loading title={I18n.t('Loading page …')} />}>
                {children}
              </Suspense>
            </View>

            <Background
              className={classNames(styles.contentLayout__background, {
                [styles['contentLayout__background--desktop']]: isDesktop,
              })}
            />
          </View>
        )
      }}
    </Responsive>
  )
}

export default ContentLayout
