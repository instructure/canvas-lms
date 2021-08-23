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

import React, {forwardRef, useEffect, useLayoutEffect, useRef, useState} from 'react'
import {connect, Provider} from 'react-redux'
import I18n from 'i18n!k5_course'
import PropTypes from 'prop-types'

import {startLoadingAllOpportunities, store} from '@instructure/canvas-planner'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconEditSolid,
  IconHomeLine,
  IconModuleLine,
  IconStarLightLine,
  IconStudentViewLine
} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {AccessibleContent} from '@instructure/ui-a11y-content'

import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import K5Tabs from '@canvas/k5/react/K5Tabs'
import SchedulePage from '@canvas/k5/react/SchedulePage'
import usePlanner from '@canvas/k5/react/hooks/usePlanner'
import useTabState from '@canvas/k5/react/hooks/useTabState'
import {mapStateToProps} from '@canvas/k5/redux/redux-helpers'
import {parseAnnouncementDetails, DEFAULT_COURSE_COLOR, TAB_IDS} from '@canvas/k5/react/utils'
import {theme} from '@canvas/k5/react/k5-theme'
import EmptyCourse from './EmptyCourse'
import OverviewPage from './OverviewPage'
import {GradesPage} from './GradesPage'
import {outcomeProficiencyShape} from '@canvas/grade-summary/react/IndividualStudentMastery/shapes'
import K5Announcement from '@canvas/k5/react/K5Announcement'
import ResourcesPage from '@canvas/k5/react/ResourcesPage'
import EmptyModules from './EmptyModules'
import EmptyHome from './EmptyHome'
import ObserverOptions, {
  ObserverListShape,
  shouldShowObserverOptions
} from '@canvas/k5/react/ObserverOptions'

const HERO_ASPECT_RATIO = 5
const HERO_STICKY_HEIGHT_PX = 100
const MOBILE_NAV_BREAKPOINT_PX = 768

const COURSE_TABS = [
  {
    id: TAB_IDS.HOME,
    icon: IconHomeLine,
    label: I18n.t('Home')
  },
  {
    id: TAB_IDS.SCHEDULE,
    icon: IconCalendarMonthLine,
    label: I18n.t('Schedule')
  },
  {
    id: TAB_IDS.MODULES,
    icon: IconModuleLine,
    label: I18n.t('Modules')
  },
  {
    id: TAB_IDS.GRADES,
    icon: IconStarLightLine,
    label: I18n.t('Grades')
  },
  {
    id: TAB_IDS.RESOURCES,
    icon: IconBankLine,
    label: I18n.t('Resources')
  }
]

// Translates server-side tab IDs to their associated frontend IDs
const translateTabId = id => {
  if (id === '19') return TAB_IDS.SCHEDULE
  if (id === '10') return TAB_IDS.MODULES
  if (id === '5') return TAB_IDS.GRADES
  if (String(id).startsWith('context_external_tool_')) return TAB_IDS.RESOURCES
  return TAB_IDS.HOME
}

const toRenderTabs = (tabs, hasSyllabusBody) => {
  const activeTabs = tabs.reduce((acc, {id, hidden}) => {
    if (hidden) return acc
    const renderId = translateTabId(id)
    const renderTab = COURSE_TABS.find(tab => tab.id === renderId)
    if (renderTab && !acc.some(tab => tab.id === renderId)) {
      acc.push(renderTab)
    }
    return acc
  }, [])
  if (hasSyllabusBody && !activeTabs.some(tab => tab.id === TAB_IDS.RESOURCES)) {
    activeTabs.push(COURSE_TABS.find(tab => tab.id === TAB_IDS.RESOURCES))
  }
  return activeTabs
}

const getWindowSize = () => ({
  width: window.innerWidth,
  height: window.innerHeight
})

export const CourseHeaderHero = forwardRef(({backgroundColor, height, name, image}, ref) => (
  <div
    id="k5-course-header-hero"
    style={{
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'flex-end',
      backgroundColor: !image && backgroundColor,
      backgroundImage: image && `url(${image})`,
      backgroundSize: 'cover',
      backgroundPosition: 'center center',
      backgroundRepeat: 'no-repeat',
      borderRadius: '8px',
      height: `${height}px`,
      width: '100%',
      marginBottom: '1rem'
    }}
    aria-hidden="true"
    data-testid="k5-course-header-hero"
    ref={ref}
  >
    <div
      style={{
        background: 'linear-gradient(90deg, rgba(0, 0, 0, 0.7), transparent)',
        borderBottomLeftRadius: '8px',
        borderBottomRightRadius: '8px',
        padding: '1rem'
      }}
    >
      <Heading as="h1" color="primary-inverse">
        <TruncateText>{name}</TruncateText>
      </Heading>
    </div>
  </div>
))

CourseHeaderHero.propTypes = {
  backgroundColor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  height: PropTypes.number.isRequired,
  image: PropTypes.string
}

export function CourseHeaderOptions({
  settingsPath,
  showStudentView,
  studentViewPath,
  canReadAsAdmin,
  courseContext,
  parentSupportEnabled,
  observerList,
  currentUser,
  handleChangeObservedUser,
  showingMobileNav
}) {
  const buttonProps = {
    id: 'manage-subject-btn',
    'data-testid': 'manage-button',
    href: settingsPath,
    renderIcon: <IconEditSolid />
  }
  const altText = I18n.t('Manage Subject: %{courseContext}', {courseContext})
  const showObserverOptions =
    parentSupportEnabled && shouldShowObserverOptions(observerList, currentUser)
  const collapseManageButton = showingMobileNav && showObserverOptions
  const sideItemsWidth = '200px'

  const manageButton = (
    <Flex.Item size={collapseManageButton ? undefined : sideItemsWidth}>
      {collapseManageButton ? (
        <IconButton {...buttonProps} screenReaderLabel={altText} margin="0 small 0 0" />
      ) : (
        <Button {...buttonProps}>
          <AccessibleContent alt={altText}>{I18n.t('Manage Subject')}</AccessibleContent>
        </Button>
      )}
    </Flex.Item>
  )

  const observerOptions = (
    <Flex.Item shouldGrow textAlign="center">
      <View as="div" display="inline-block" width={showingMobileNav ? '100%' : '16em'}>
        <ObserverOptions
          observerList={observerList}
          currentUser={currentUser}
          handleChangeObservedUser={handleChangeObservedUser}
        />
      </View>
    </Flex.Item>
  )

  const studentViewButton = (
    <Flex.Item textAlign="end" size={sideItemsWidth}>
      <Button
        id="student-view-btn"
        href={studentViewPath}
        data-method="post"
        renderIcon={<IconStudentViewLine />}
      >
        {I18n.t('Student View')}
      </Button>
    </Flex.Item>
  )

  const headerItems = []
  if (canReadAsAdmin) {
    headerItems.push(manageButton)
  }
  if (showObserverOptions) {
    headerItems.push(observerOptions)
  }
  if (showStudentView && !showingMobileNav) {
    headerItems.push(studentViewButton)
  }

  return headerItems.length > 0 ? (
    <View
      id="k5-course-header-options"
      as="section"
      borderWidth="0 0 small 0"
      padding="0 0 medium 0"
      margin="0 0 medium 0"
    >
      <Flex alignItems="center" justifyItems="space-between">
        {headerItems}
      </Flex>
    </View>
  ) : null
}

CourseHeaderOptions.propTypes = {
  settingsPath: PropTypes.string.isRequired,
  showStudentView: PropTypes.bool.isRequired,
  studentViewPath: PropTypes.string.isRequired,
  canReadAsAdmin: PropTypes.bool.isRequired,
  courseContext: PropTypes.string.isRequired,
  parentSupportEnabled: PropTypes.bool.isRequired,
  observerList: ObserverListShape.isRequired,
  handleChangeObservedUser: PropTypes.func.isRequired,
  currentUser: PropTypes.object.isRequired,
  showingMobileNav: PropTypes.bool.isRequired
}

export function K5Course({
  assignmentsDueToday,
  assignmentsMissing,
  assignmentsCompletedForToday,
  bannerImageUrl,
  cardImageUrl,
  color,
  courseOverview,
  defaultTab,
  id,
  loadAllOpportunities,
  name,
  timeZone,
  canManage = false,
  canReadAsAdmin,
  plannerEnabled = false,
  hideFinalGrades,
  currentUser,
  userIsStudent,
  userIsInstructor,
  showStudentView,
  studentViewPath,
  showLearningMasteryGradebook,
  outcomeProficiency,
  tabs,
  settingsPath,
  latestAnnouncement,
  pagesPath,
  hasWikiPages,
  hasSyllabusBody,
  parentSupportEnabled,
  observerList
}) {
  const renderTabs = toRenderTabs(tabs, hasSyllabusBody)
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab, renderTabs)
  const [tabsRef, setTabsRef] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    callback: () => loadAllOpportunities(),
    singleCourse: true
  })

  /* Rails renders the modules partial into #k5-modules-container. After the first render, we hide that div and
     move it into the main <View> of K5Course so the sticky tabs stick. Then show/hide it (if there's at least one
     module) based off currentTab */
  const modulesRef = useRef(null)
  const contentRef = useRef(null)
  const headerRef = useRef(null)
  const tabsPaddingRef = useRef(null)
  const [modulesExist, setModulesExist] = useState(true)
  const [windowSize, setWindowSize] = useState(() => getWindowSize())
  const [observedUserId, setObservedUserId] = useState(null)
  useEffect(() => {
    modulesRef.current = document.getElementById('k5-modules-container')
    contentRef.current.appendChild(modulesRef.current)
    setModulesExist(document.getElementById('context_modules').childElementCount > 0)
  }, [])

  useEffect(() => {
    if (modulesRef.current) {
      modulesRef.current.style.display =
        currentTab === TAB_IDS.MODULES && (modulesExist || canManage) ? 'block' : 'none'
    }
    // Rails only takes care of the url without the hash in the request.referer, so to keep the navigation after loading or leaving
    // the student view mode, we need to add the tab hash portion to the links href to the maintain the navigation after redirections
    const resetStudentBtn = document.querySelector('a.leave_student_view[data-method="delete"]')
    const leaveStudentModeBtn = document.querySelector('a.reset_test_student[data-method="delete"]')
    if (resetStudentBtn) {
      resetStudentBtn.href = addCurrentTabSegment(resetStudentBtn.href)
    }
    if (leaveStudentModeBtn) {
      leaveStudentModeBtn.href = addCurrentTabSegment(leaveStudentModeBtn.href)
    }
  }, [currentTab, modulesExist, canManage])

  useLayoutEffect(() => {
    function updateWindowSize() {
      setWindowSize(getWindowSize())
    }
    window.addEventListener('resize', updateWindowSize)
    return () => window.removeEventListener('resize', updateWindowSize)
  }, [])

  const addCurrentTabSegment = url => {
    const currentTabUrlSegment = window.location.hash
    const baseUrl = url.split('#')[0]
    return baseUrl + currentTabUrlSegment
  }

  const courseHeader = sticky => {
    // If we don't have a ref to the header's width yet, use viewport width as a best guess
    const headerHeight = (headerRef.current?.offsetWidth || windowSize.width) / HERO_ASPECT_RATIO
    if (tabsRef && !tabsPaddingRef.current) {
      tabsPaddingRef.current = tabsRef.getBoundingClientRect().bottom - headerHeight
    }
    // This is the vertical px by which the header will shrink when sticky
    const headerShrinkDiff = headerRef.current ? headerHeight - HERO_STICKY_HEIGHT_PX : 0
    // This is the vertical px by which the content overflows the viewport
    const contentScrollOverflow = document.body.scrollHeight - windowSize.height
    // If the window height is smaller than the height of the header, flickering and weird
    // sticky behavior occurs. This is a hack to force the header to shrink when we get close
    // to that size
    const isWindowTooSmall = tabsPaddingRef.current
      ? windowSize.height < tabsPaddingRef.current + headerHeight
      : false
    // Make sure that there is more vertical scroll overflow height than the header will
    // lose when transitioning to a sticky state. Otherwise the header will flicker rapidly
    // between sticky and non-sticky states.
    const shouldShrink =
      (sticky && activeTab.current === currentTab && contentScrollOverflow > headerShrinkDiff) ||
      isWindowTooSmall
    return (
      <View id="k5-course-header" as="div" padding={sticky && shouldShrink ? 'medium 0 0 0' : '0'}>
        <CourseHeaderOptions
          canReadAsAdmin={canReadAsAdmin}
          settingsPath={settingsPath}
          showStudentView={showStudentView}
          studentViewPath={`${studentViewPath + window.location.hash}`}
          courseContext={name}
          parentSupportEnabled={parentSupportEnabled}
          observerList={observerList}
          currentUser={currentUser}
          handleChangeObservedUser={setObservedUserId}
          showingMobileNav={windowSize.width < MOBILE_NAV_BREAKPOINT_PX}
        />
        <CourseHeaderHero
          name={name}
          image={bannerImageUrl || cardImageUrl}
          backgroundColor={color || DEFAULT_COURSE_COLOR}
          height={shouldShrink ? HERO_STICKY_HEIGHT_PX : headerHeight}
          ref={headerRef}
        />
      </View>
    )
  }

  // Only render the K5Tabs component if we actually have any visible tabs
  const courseTabs = renderTabs?.length ? (
    <K5Tabs
      currentTab={currentTab}
      onTabChange={handleTabChange}
      tabs={renderTabs}
      tabsRef={setTabsRef}
      courseContext={name}
    >
      {sticky => courseHeader(sticky)}
    </K5Tabs>
  ) : (
    courseHeader()
  )

  const announcementDetails = parseAnnouncementDetails(latestAnnouncement, {
    id,
    shortName: name,
    href: `/courses/${id}`,
    canManage
  })

  return (
    <K5DashboardContext.Provider
      value={{
        assignmentsDueToday,
        assignmentsMissing,
        assignmentsCompletedForToday,
        isStudent: plannerEnabled
      }}
    >
      <View as="section" data-testid="main-content" elementRef={e => (contentRef.current = e)}>
        {courseTabs}
        {!renderTabs?.length && <EmptyCourse name={name} id={id} canManage={canManage} />}
        {currentTab === renderTabs?.[0]?.id && (
          <K5Announcement
            showCourseDetails={false}
            {...announcementDetails}
            firstAnnouncement={announcementDetails.announcement}
          />
        )}
        {currentTab === TAB_IDS.HOME &&
          (courseOverview || courseOverview?.length === 0 ? (
            <OverviewPage content={courseOverview} />
          ) : (
            <EmptyHome
              pagesPath={pagesPath}
              hasWikiPages={hasWikiPages}
              courseName={name}
              canManage={canManage}
            />
          ))}
        <SchedulePage
          plannerEnabled={plannerEnabled}
          plannerInitialized={plannerInitialized}
          timeZone={timeZone}
          userHasEnrollments
          visible={currentTab === TAB_IDS.SCHEDULE}
        />
        {currentTab === TAB_IDS.GRADES && (
          <GradesPage
            courseId={id}
            courseName={name}
            hideFinalGrades={hideFinalGrades}
            currentUser={currentUser}
            userIsStudent={userIsStudent}
            userIsInstructor={userIsInstructor}
            showLearningMasteryGradebook={showLearningMasteryGradebook}
            outcomeProficiency={outcomeProficiency}
          />
        )}
        {currentTab === TAB_IDS.RESOURCES && (
          <ResourcesPage
            cards={[{id, originalName: name, shortName: name, isHomeroom: false, canManage}]}
            cardsSettled
            visible={currentTab === TAB_IDS.RESOURCES}
            showStaff={false}
            isSingleCourse
          />
        )}
        {currentTab === TAB_IDS.MODULES && !modulesExist && !canManage && <EmptyModules />}
      </View>
    </K5DashboardContext.Provider>
  )
}

K5Course.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  assignmentsMissing: PropTypes.object.isRequired,
  assignmentsCompletedForToday: PropTypes.object.isRequired,
  id: PropTypes.string.isRequired,
  loadAllOpportunities: PropTypes.func.isRequired,
  name: PropTypes.string.isRequired,
  timeZone: PropTypes.string.isRequired,
  bannerImageUrl: PropTypes.string,
  cardImageUrl: PropTypes.string,
  canManage: PropTypes.bool,
  canReadAsAdmin: PropTypes.bool.isRequired,
  color: PropTypes.string,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  courseOverview: PropTypes.string,
  hideFinalGrades: PropTypes.bool.isRequired,
  currentUser: PropTypes.object.isRequired,
  userIsStudent: PropTypes.bool.isRequired,
  userIsInstructor: PropTypes.bool.isRequired,
  showStudentView: PropTypes.bool.isRequired,
  studentViewPath: PropTypes.string.isRequired,
  showLearningMasteryGradebook: PropTypes.bool.isRequired,
  outcomeProficiency: outcomeProficiencyShape,
  tabs: PropTypes.arrayOf(PropTypes.object).isRequired,
  settingsPath: PropTypes.string.isRequired,
  latestAnnouncement: PropTypes.object,
  pagesPath: PropTypes.string.isRequired,
  hasWikiPages: PropTypes.bool.isRequired,
  hasSyllabusBody: PropTypes.bool.isRequired,
  parentSupportEnabled: PropTypes.bool.isRequired,
  observerList: ObserverListShape.isRequired
}

const WrappedK5Course = connect(mapStateToProps, {
  loadAllOpportunities: startLoadingAllOpportunities
})(K5Course)

export default props => (
  <ApplyTheme theme={theme}>
    <Provider store={store}>
      <WrappedK5Course {...props} />
    </Provider>
  </ApplyTheme>
)
