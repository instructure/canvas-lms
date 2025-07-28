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
import {Img} from '@instructure/ui-img'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-themes'
import {TopNavBar} from '@instructure/ui-top-nav-bar'
import React from 'react'
import {useNewLoginData} from '../context'

import CanvasLmsLogoIcon from '../assets/images/canvas-small.svg'
import CanvasLmsLogo from '../assets/images/canvas.svg'

const I18n = createI18nScope('new_login')

const AppNavBar = () => {
  const {enableCourseCatalog} = useNewLoginData()

  return (
    <TopNavBar breakpoint={10} inverseColor={true}>
      {() => {
        return (
          <TopNavBar.Layout
            navLabel={I18n.t('Login page navigation')}
            smallViewportConfig={{
              dropdownMenuToggleButtonLabel: I18n.t('Menu'),
            }}
            renderBrand={
              <TopNavBar.Brand
                screenReaderLabel={I18n.t('Canvas LMS')}
                renderIcon={
                  <Responsive
                    match="media"
                    query={{
                      tablet: {minWidth: canvas.breakpoints.tablet},
                    }}
                  >
                    {(_props, matches) => {
                      if (matches?.includes('tablet')) {
                        return (
                          <Img
                            constrain="contain"
                            display="block"
                            height="2.375rem"
                            src={CanvasLmsLogo}
                            width="8rem"
                          />
                        )
                      } else {
                        return (
                          <Img
                            constrain="contain"
                            display="block"
                            height="2.375rem"
                            src={CanvasLmsLogoIcon}
                            width="2.375rem"
                          />
                        )
                      }
                    }}
                  </Responsive>
                }
              />
            }
            renderActionItems={
              enableCourseCatalog ? (
                <TopNavBar.ActionItems
                  listLabel={I18n.t('Page navigation')}
                  renderHiddenItemsMenuTriggerLabel={hiddenChildrenCount =>
                    I18n.t('%{hiddenChildrenCount} More', {hiddenChildrenCount})
                  }
                >
                  <TopNavBar.Item id="browseCourses" href="/search/all_courses">
                    {I18n.t('Browse Courses')}
                  </TopNavBar.Item>
                </TopNavBar.ActionItems>
              ) : undefined
            }
          />
        )
      }}
    </TopNavBar>
  )
}

export default AppNavBar
