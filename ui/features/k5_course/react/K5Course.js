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

import {store} from '@instructure/canvas-planner'
import {
  IconAddLine,
  IconBankLine,
  IconCalendarMonthLine,
  IconEditSolid,
  IconGroupLine,
  IconHomeLine,
  IconModuleLine,
  IconStarLightLine,
  IconStudentViewLine,
  IconXLine
} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'

import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import K5Tabs, {scrollElementIntoViewIfCoveredByHeader} from '@canvas/k5/react/K5Tabs'
import SchedulePage from '@canvas/k5/react/SchedulePage'
import usePlanner from '@canvas/k5/react/hooks/usePlanner'
import useTabState from '@canvas/k5/react/hooks/useTabState'
import {mapStateToProps} from '@canvas/k5/redux/redux-helpers'
import {
  parseAnnouncementDetails,
  dropCourse,
  DEFAULT_COURSE_COLOR,
  TAB_IDS
} from '@canvas/k5/react/utils'
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
import GroupsPage from '@canvas/k5/react/GroupsPage'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {savedObservedId} from '@canvas/k5/ObserverGetObservee'

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
  },
  {
    id: TAB_IDS.GROUPS,
    icon: IconGroupLine,
    label: I18n.t('Groups')
  }
]

// Translates server-side tab IDs to their associated frontend IDs
const translateTabId = id => {
  if (id === '19') return TAB_IDS.SCHEDULE
  if (id === '10') return TAB_IDS.MODULES
  if (id === '7') return TAB_IDS.GROUPS
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

const ConfirmDropModal = ({isModalOpen, closeModal, courseName, dropLink}) => {
  const [isPosting, setPosting] = useState(false)
  const handleConfirm = () => {
    setPosting(true)
    dropCourse(dropLink)
      .then(() => {
        closeModal()
        window.location.reload()
      })
      .catch(err => showFlashError(I18n.t('Unable to drop the subject'))(err))
      .finally(() => setPosting(false))
  }

  return (
    <Modal
      label={I18n.t('Drop %{courseName}', {courseName})}
      open={isModalOpen}
      size="small"
      onDismiss={closeModal}
    >
      <Modal.Body>
        {isPosting ? (
          <View as="div" textAlign="center" margin="medium 0">
            <Spinner renderTitle={I18n.t('Dropping subject')} />
          </View>
        ) : (
          <>
            <Heading as="h3" margin="0 0 small">
              {I18n.t('Confirm Unenrollment')}
            </Heading>
            <Text>
              {I18n.t(
                'Are you sure you want to unenroll in this subject?  You will no longer be able to see the subject roster or communicate directly with the teachers, and you will no longer see subject events in your stream and as notifications.'
              )}
            </Text>
          </>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          color="secondary"
          onClick={closeModal}
          interaction={!isPosting ? 'enabled' : 'disabled'}
        >
          {I18n.t('Cancel')}
        </Button>
        &nbsp;
        <Button
          color="primary"
          onClick={handleConfirm}
          interaction={!isPosting ? 'enabled' : 'disabled'}
        >
          {I18n.t('Drop this Subject')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

ConfirmDropModal.propTypes = {
  isModalOpen: PropTypes.bool.isRequired,
  closeModal: PropTypes.func.isRequired,
  courseName: PropTypes.string.isRequired,
  dropLink: PropTypes.string.isRequired
}

export const CourseHeaderHero = forwardRef(
  ({backgroundColor, height, name, image, selfEnrollment, showingMobileNav, observerMode}, ref) => {
    const [isModalOpen, setModalOpen] = useState(false)
    return (
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
        data-testid="k5-course-header-hero"
        ref={ref}
      >
        {(!showingMobileNav || selfEnrollment?.option) && (
          <div
            style={{
              background: 'linear-gradient(90deg, rgba(0, 0, 0, 0.7), transparent)',
              borderBottomLeftRadius: '8px',
              borderBottomRightRadius: '8px'
            }}
          >
            <Flex alignItems="center" margin="small medium">
              {!showingMobileNav && (
                <Flex.Item shouldGrow shouldShrink margin="0 small 0 0">
                  <Heading as="h1" aria-hidden={observerMode} color="primary-inverse">
                    {name}
                  </Heading>
                </Flex.Item>
              )}
              <Flex.Item>
                {selfEnrollment?.option === 'enroll' && (
                  <Button color="primary" renderIcon={IconAddLine} href={selfEnrollment.url}>
                    {I18n.t('Join this Subject')}
                  </Button>
                )}
                {selfEnrollment?.option === 'unenroll' && (
                  <>
                    <Button renderIcon={IconXLine} onClick={() => setModalOpen(true)}>
                      {I18n.t('Drop this Subject')}
                    </Button>
                    <ConfirmDropModal
                      isModalOpen={isModalOpen}
                      closeModal={() => setModalOpen(false)}
                      courseName={name}
                      dropLink={selfEnrollment.url}
                    />
                  </>
                )}
              </Flex.Item>
            </Flex>
          </div>
        )}
      </div>
    )
  }
)

CourseHeaderHero.propTypes = {
  backgroundColor: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  height: PropTypes.number.isRequired,
  image: PropTypes.string,
  selfEnrollment: PropTypes.object,
  showingMobileNav: PropTypes.bool.isRequired,
  observerMode: PropTypes.bool.isRequired
}

export function CourseHeaderOptions({
  settingsPath,
  showStudentView,
  studentViewPath,
  canReadAsAdmin,
  courseContext,
  observerList,
  currentUser,
  handleChangeObservedUser,
  showingMobileNav,
  showObserverOptions
}) {
  const buttonProps = {
    id: 'manage-subject-btn',
    'data-testid': 'manage-button',
    href: settingsPath,
    renderIcon: <IconEditSolid />
  }
  const altText = I18n.t('Manage Subject: %{courseContext}', {courseContext})

  const collapseManageButton = showingMobileNav && showObserverOptions
  const sideItemsWidth = '200px'

  const manageButton = (
    <Flex.Item size={collapseManageButton ? undefined : sideItemsWidth} key="course-header-manage">
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
    <Flex.Item shouldGrow textAlign="center" key="course-header-observer-options">
      <View as="div" display="inline-block" width={showingMobileNav ? '100%' : '16em'}>
        <ScreenReaderContent>
          <Heading as="h1">{courseContext}</Heading>
        </ScreenReaderContent>
        <ObserverOptions
          observerList={observerList}
          currentUser={currentUser}
          handleChangeObservedUser={handleChangeObservedUser}
          canAddObservee={false}
        />
      </View>
    </Flex.Item>
  )

  const studentViewButton = (
    <Flex.Item textAlign="end" size={sideItemsWidth} key="course-header-student-view">
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
  observerList: ObserverListShape.isRequired,
  handleChangeObservedUser: PropTypes.func.isRequired,
  currentUser: PropTypes.object.isRequired,
  showingMobileNav: PropTypes.bool.isRequired,
  showObserverOptions: PropTypes.bool.isRequired
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
  name,
  timeZone,
  canManage = false,
  canManageGroups,
  canReadAsAdmin,
  canReadAnnouncements,
  plannerEnabled = false,
  hideFinalGrades,
  currentUser,
  userIsStudent,
  showStudentView,
  studentViewPath,
  showLearningMasteryGradebook,
  outcomeProficiency,
  tabs,
  settingsPath,
  groupsPath,
  latestAnnouncement,
  pagesPath,
  hasWikiPages,
  hasSyllabusBody,
  parentSupportEnabled,
  observerList,
  selfEnrollment,
  tabContentOnly,
  currentUserRoles
}) {
  const initialObservedId = observerList.find(o => o.id === savedObservedId(currentUser.id))
    ? savedObservedId(currentUser.id)
    : undefined

  const renderTabs = toRenderTabs(tabs, hasSyllabusBody)
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab, renderTabs)
  const [tabsRef, setTabsRef] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    singleCourse: true,
    observedUserId: initialObservedId,
    isObserver: currentUserRoles.includes('observer')
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
  const [observedUserId, setObservedUserId] = useState(initialObservedId)
  const showObserverOptions =
    parentSupportEnabled && shouldShowObserverOptions(observerList, currentUser)
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
    const showingMobileNav = windowSize.width < MOBILE_NAV_BREAKPOINT_PX
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
          showingMobileNav={showingMobileNav}
          showObserverOptions={showObserverOptions}
        />
        <CourseHeaderHero
          name={name}
          image={bannerImageUrl || cardImageUrl}
          backgroundColor={color || DEFAULT_COURSE_COLOR}
          height={shouldShrink ? HERO_STICKY_HEIGHT_PX : headerHeight}
          selfEnrollment={selfEnrollment}
          showingMobileNav={showingMobileNav}
          ref={headerRef}
          observerMode={showObserverOptions}
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
    canManage,
    canReadAnnouncements
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
      <View
        as="section"
        data-testid="main-content"
        elementRef={e => (contentRef.current = e)}
        onFocus={scrollElementIntoViewIfCoveredByHeader(tabsRef)}
      >
        {!tabContentOnly && courseTabs}
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
          singleCourse
          observedUserId={observedUserId}
          contextCodes={[`course_${id}`]}
        />
        {currentTab === TAB_IDS.GRADES && (
          <GradesPage
            courseId={id}
            courseName={name}
            hideFinalGrades={hideFinalGrades}
            currentUser={currentUser}
            userIsStudent={userIsStudent}
            userIsCourseAdmin={canReadAsAdmin}
            showLearningMasteryGradebook={showLearningMasteryGradebook}
            outcomeProficiency={outcomeProficiency}
            observedUserId={showObserverOptions ? observedUserId : null}
          />
        )}
        <ResourcesPage
          cards={[{id, originalName: name, shortName: name, isHomeroom: false, canManage}]}
          cardsSettled
          visible={currentTab === TAB_IDS.RESOURCES}
          showStaff={false}
          isSingleCourse
        />
        {currentTab === TAB_IDS.MODULES && !modulesExist && !canManage && <EmptyModules />}
        {currentTab === TAB_IDS.GROUPS && (
          <GroupsPage
            courseId={id}
            groupsPath={groupsPath}
            showTeacherPage={canReadAsAdmin}
            canManageGroups={canManageGroups}
          />
        )}
      </View>
    </K5DashboardContext.Provider>
  )
}

K5Course.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  assignmentsMissing: PropTypes.object.isRequired,
  assignmentsCompletedForToday: PropTypes.object.isRequired,
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  timeZone: PropTypes.string.isRequired,
  bannerImageUrl: PropTypes.string,
  cardImageUrl: PropTypes.string,
  canManage: PropTypes.bool,
  canManageGroups: PropTypes.bool,
  canReadAsAdmin: PropTypes.bool.isRequired,
  canReadAnnouncements: PropTypes.bool.isRequired,
  color: PropTypes.string,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  courseOverview: PropTypes.string,
  hideFinalGrades: PropTypes.bool.isRequired,
  currentUser: PropTypes.object.isRequired,
  userIsStudent: PropTypes.bool.isRequired,
  showStudentView: PropTypes.bool.isRequired,
  studentViewPath: PropTypes.string.isRequired,
  showLearningMasteryGradebook: PropTypes.bool.isRequired,
  outcomeProficiency: outcomeProficiencyShape,
  tabs: PropTypes.arrayOf(PropTypes.object).isRequired,
  groupsPath: PropTypes.string.isRequired,
  settingsPath: PropTypes.string.isRequired,
  latestAnnouncement: PropTypes.object,
  pagesPath: PropTypes.string.isRequired,
  hasWikiPages: PropTypes.bool.isRequired,
  hasSyllabusBody: PropTypes.bool.isRequired,
  parentSupportEnabled: PropTypes.bool.isRequired,
  observerList: ObserverListShape.isRequired,
  selfEnrollment: PropTypes.object,
  tabContentOnly: PropTypes.bool,
  currentUserRoles: PropTypes.array.isRequired
}

const WrappedK5Course = connect(mapStateToProps)(K5Course)

export default props => (
  <ApplyTheme theme={theme}>
    <Provider store={store}>
      <WrappedK5Course {...props} />
    </Provider>
  </ApplyTheme>
)
