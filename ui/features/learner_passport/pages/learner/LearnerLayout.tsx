/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {Outlet, useMatch, useNavigate} from 'react-router-dom'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Flex} from '@instructure/ui-flex'
import {Portal} from '@instructure/ui-portal'
import {View} from '@instructure/ui-view'

const passportSvg = `<svg class="ic-icon-svg menu-item__icon svg-icon-passport" width="38" height="38" viewBox="0 0 38 38" enable-background="new 0 0 38 38" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
<rect width="38" height="38" fill="none"/>
<path d="M17.3958 2.78363C18.2146 1.73879 19.7854 1.73879 20.6042 2.78363L22.0428 4.61941C22.5809 5.30615 23.49 5.57547 24.3107 5.29133L26.5045 4.53177C27.7532 4.09946 29.0746 4.95634 29.2036 6.28198L29.4302 8.61113C29.5149 9.48243 30.1354 10.2049 30.978 10.4136L33.2306 10.9714C34.5127 11.2889 35.1652 12.7306 34.5634 13.9161L33.5061 15.9992C33.1105 16.7784 33.2454 17.7246 33.8424 18.3599L35.4385 20.0579C36.347 21.0244 36.1234 22.5932 34.982 23.2623L32.9764 24.4378C32.2261 24.8776 31.8325 25.7472 31.9945 26.6073L32.4274 28.9065C32.6738 30.2151 31.6451 31.4129 30.3264 31.3531L28.0093 31.248C27.1425 31.2086 26.3455 31.7255 26.0209 32.5374L25.1531 34.7078C24.6592 35.943 23.1521 36.3896 22.0747 35.6198L20.1818 34.2674C19.4737 33.7614 18.5263 33.7614 17.8182 34.2674L15.9253 35.6198C14.8479 36.3896 13.3408 35.943 12.8469 34.7078L11.9791 32.5374C11.6545 31.7255 10.8575 31.2086 9.99071 31.248L7.67364 31.3531C6.35487 31.4129 5.32625 30.2151 5.57263 28.9065L6.00551 26.6073C6.16745 25.7472 5.77387 24.8776 5.02362 24.4378L3.01805 23.2623C1.87657 22.5932 1.65303 21.0244 2.56145 20.0579L4.15756 18.3599C4.75463 17.7246 4.88947 16.7784 4.49394 15.9992L3.43661 13.9161C2.83483 12.7306 3.48735 11.2889 4.7694 10.9714L7.02197 10.4136C7.86462 10.2049 8.48505 9.48243 8.56983 8.61113L8.79644 6.28198C8.92542 4.95634 10.2468 4.09946 11.4955 4.53177L13.6893 5.29133C14.51 5.57548 15.4191 5.30614 15.9572 4.61941L17.3958 2.78363Z" />
<circle cx="19" cy="19" r="11" fill="#F5F5F5"/>
<ellipse cx="18.9985" cy="16.1679" rx="3.77778" ry="3.77778" />
<path d="M16.9202 18.8136C17.0315 18.3685 17.4315 18.0562 17.8904 18.0562H20.1066C20.5655 18.0562 20.9654 18.3684 21.0767 18.8136L22.4656 24.3692C22.6234 25.0003 22.1461 25.6117 21.4955 25.6117H16.5015C15.8509 25.6117 15.3736 25.0003 15.5313 24.3692L16.9202 18.8136Z" />
</svg>`

const activeStyle = {
  borderBottom: '2px solid var(--ic-brand-primary)',
  display: 'inline-block',
  marginInlineEnd: '2.5rem',
  fontWeight: 'bold',
  cursor: 'pointer',
}
const inactiveStyle = {
  borderBottom: '2px solid transparent',
  display: 'inline-block',
  marginInlineEnd: '2.5rem',
  cursor: 'pointer',
}

export const Component = () => {
  const navigate = useNavigate()
  const pathMatch = useMatch('/users/:userId/passport/learner/:tabPath/*')
  const selectedTab = pathMatch?.params.tabPath || 'achievements'

  useEffect(() => {
    // canvas limits the width of the content area. For learner passport, let's not.
    document.body.classList.add('learner-passport')
    if (!document.getElementById('learner_passport_style')) {
      const s = document.createElement('style')
      s.id = 'learner_passport_style'
      s.textContent = `
        body:not(.full-width):not(.outcomes):not(.body--login-confirmation).learner-passport .ic-Layout-wrapper {
          max-width: 100%;
        }
      `
      document.head.appendChild(s)
    }
  }, [])

  const handleTabChange = (tabname: string) => {
    if (tabname === 'portfolios') {
      navigate('portfolios/dashboard')
    } else if (tabname === 'projects') {
      navigate('projects/dashboard')
    } else {
      navigate(tabname)
    }
  }

  const handleTabClick = (event: React.MouseEvent) => {
    // @ts-expect-error
    handleTabChange(event.target.getAttribute('data-tabid'))
  }

  const handleTabKey = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter') {
      // @ts-expect-error
      handleTabChange(event.target.getAttribute('data-tabid'))
    }
  }

  const mountPoint: HTMLElement | null = document.querySelector('#content')
  if (!mountPoint) {
    return null
  }

  return (
    <Portal open={true} mountNode={mountPoint}>
      <div style={{margin: '-36px -48px -48px -48px'}}>
        <View as="div" background="secondary" padding="small medium" borderWidth="0 0 small 0">
          <Flex>
            <div style={{color: 'var(--ic-brand-primary)'}}>
              <SVGIcon src={passportSvg} inline={true} size="small" title="Learner Passport" />
            </div>
            <Flex.Item shouldGrow={true} margin="0 medium 0 0">
              <div style={{display: 'inline-block', marginInlineStart: '1.5rem'}} role="tablist">
                <div
                  role="tab"
                  data-tabid="achievements"
                  style={selectedTab === 'achievements' ? activeStyle : inactiveStyle}
                  tabIndex={0}
                  onClick={handleTabClick}
                  onKeyDown={handleTabKey}
                >
                  Achievements
                </div>
                <div
                  role="tab"
                  data-tabid="portfolios"
                  style={selectedTab === 'portfolios' ? activeStyle : inactiveStyle}
                  tabIndex={0}
                  onClick={handleTabClick}
                  onKeyDown={handleTabKey}
                >
                  Portfolios
                </div>
                <div
                  role="tab"
                  data-tabid="projects"
                  style={selectedTab === 'projects' ? activeStyle : inactiveStyle}
                  tabIndex={0}
                  onClick={handleTabClick}
                  onKeyDown={handleTabKey}
                >
                  Projects
                </div>
              </div>
            </Flex.Item>
            <Flex.Item>{window.ENV.current_user.display_name}</Flex.Item>
          </Flex>
        </View>
        <View id="learner_passport_container" as="div" margin="large x-large 0">
          <Outlet />
        </View>
      </div>
    </Portal>
  )
}
