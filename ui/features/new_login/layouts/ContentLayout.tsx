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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-themes'
import {View} from '@instructure/ui-view'
import classNames from 'classnames'
import React, {Suspense} from 'react'
import {useNewLoginData} from '../context'
import {Background, Loading} from '../shared'

// @ts-expect-error
import styles from './ContentLayout.module.css'

const I18n = createI18nScope('new_login')

const breakpoints = {
  tablet: {minWidth: canvas.breakpoints.tablet}, // 768px
}

interface Props {
  children: React.ReactNode
}

const ContentLayout = ({children}: Props) => {
  const {isDataLoading} = useNewLoginData()

  // <Responsive> renders as a <div> with display="block", so we set its height to 100% to fill the
  // available space within its parent, which is a flex item
  const setResponsiveRef = (el: HTMLDivElement | null) => {
    if (el) el.style.height = '100%'
  }

  const renderLoading = () => {
    return <Loading title={I18n.t('Loading page …')} />
  }

  const renderContentLayout = (isTablet: boolean) => (
    <View
      as="div"
      height="100%"
      position="relative"
      className={classNames({
        [styles['contentLayout--tablet']]: isTablet,
      })}
    >
      <View
        as="div"
        className={classNames(styles.contentLayout__content, {
          [styles['contentLayout__content--tablet']]: isTablet,
        })}
        background="primary"
        borderRadius={isTablet ? 'small' : undefined}
        position="relative"
        shadow={isTablet ? 'resting' : undefined}
        stacking="above"
      >
        {isDataLoading ? (
          // show a loading spinner during data fetching
          renderLoading()
        ) : (
          // suspense fallback for lazy-loaded components
          <Suspense fallback={renderLoading()}>{children}</Suspense>
        )}
      </View>

      <Background className={classNames(styles.contentLayout__background)} />
    </View>
  )

  return (
    <Responsive match="media" query={breakpoints} elementRef={setResponsiveRef}>
      {(_props, matches) => {
        const isTablet = matches?.includes('tablet') || false
        return renderContentLayout(isTablet)
      }}
    </Responsive>
  )
}

export default ContentLayout
