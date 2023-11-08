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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

import {store} from '@canvas/planner'
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
  IconXLine,
} from '@instructure/ui-icons'
import {InstUISettingsProvider} from '@instructure/emotion'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {TruncateText} from '@instructure/ui-truncate-text'

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
  TAB_IDS,
  MOBILE_NAV_BREAKPOINT_PX,
} from '@canvas/k5/react/utils'
import {getK5ThemeOverrides} from '@canvas/k5/react/k5-theme'
import EmptyCourse from './EmptyCourse'
import OverviewPage from './OverviewPage'
import {GradesPage} from './GradesPage'
import {outcomeProficiencyShape} from '@canvas/grade-summary/react/IndividualStudentMastery/shapes'
import K5Announcement from '@canvas/k5/react/K5Announcement'
import ResourcesPage from '@canvas/k5/react/ResourcesPage'
import EmptyModules from './EmptyModules'
import EmptyHome from './EmptyHome'
import ObserverOptions, {
  ObservedUsersListShape,
  shouldShowObserverOptions,
} from '@canvas/observer-picker'
import GroupsPage from '@canvas/k5/react/GroupsPage'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'

const I18n = useI18nScope('k5_course')

const HERO_ASPECT_RATIO = 5
const HERO_STICKY_HEIGHT_PX = 64
const STICKY_HERO_CUTOFF_BUFFER_PX = 80

const COURSE_TABS = [
  {
    id: TAB_IDS.HOME,
    icon: IconHomeLine,
    label: I18n.t('Home'),
  },
  {
    id: TAB_IDS.SCHEDULE,
    icon: IconCalendarMonthLine,
    label: I18n.t('Schedule'),
  },
  {
    id: TAB_IDS.MODULES,
    icon: IconModuleLine,
    label: I18n.t('Modules'),
  },
  {
    id: TAB_IDS.GRADES,
    icon: IconStarLightLine,
    label: I18n.t('Grades'),
  },
  {
    id: TAB_IDS.RESOURCES,
    icon: IconBankLine,
    label: I18n.t('Resources'),
  },
  {
    id: TAB_IDS.GROUPS,
    icon: IconGroupLine,
    label: I18n.t('Groups'),
  },
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
  height: window.innerHeight,
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
  dropLink: PropTypes.string.isRequired,
}

export const CourseHeaderHero = forwardRef(
  (
    {
      backgroundColor,
      height,
      name,
      image,
      selfEnrollment,
      showingMobileNav,
      observerMode,
      shouldShrink,
    },
    ref
  ) => {
    const [isModalOpen, setModalOpen] = useState(false)
    const possiblyTruncatedName = shouldShrink ? <TruncateText>{name}</TruncateText> : name
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
          marginBottom: '1rem',
          overflowY: 'hidden',
        }}
        data-testid="k5-course-header-hero"
        ref={ref}
      >
        {(!showingMobileNav || selfEnrollment?.option) && (
          <div
            style={{
              background: 'linear-gradient(90deg, rgba(0, 0, 0, 0.7), transparent)',
              height: shouldShrink ? `${HERO_STICKY_HEIGHT_PX}px` : undefined,
              maxHeight: shouldShrink ? undefined : `${height}px`,
            }}
          >
            <Flex alignItems="center" padding="small medium" height="100%">
              {!showingMobileNav && (
                <Flex.Item shouldGrow={true} shouldShrink={true} margin="0 small 0 0">
                  <Heading as="h1" aria-hidden={observerMode} color="primary-inverse">
                    {possiblyTruncatedName}
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
  observerMode: PropTypes.bool.isRequired,
  shouldShrink: PropTypes.bool.isRequired,
}

export const CourseHeaderOptions = forwardRef(
  (
    {
      settingsPath,
      showStudentView,
      studentViewPath,
      canReadAsAdmin,
      courseContext,
      observedUsersList,
      currentUser,
      handleChangeObservedUser,
      showingMobileNav,
      showObserverOptions,
      isMasterCourse,
      windowWidth,
    },
    ref
  ) => {
    const ManageButton = () => {
      const buttonProps = {
        id: 'manage-subject-btn',
        'data-testid': 'manage-button',
        href: settingsPath,
        renderIcon: <IconEditSolid />,
      }
      const altText = I18n.t('Manage Subject: %{courseContext}', {courseContext})
      if (showingMobileNav && showObserverOptions) {
        return <IconButton {...buttonProps} screenReaderLabel={altText} margin="0 small 0 0" />
      } else {
        return (
          <Button {...buttonProps}>
            <AccessibleContent alt={altText}>{I18n.t('Manage Subject')}</AccessibleContent>
          </Button>
        )
      }
    }

    const StudentViewButton = () => (
      <Button
        id="student-view-btn"
        href={studentViewPath}
        data-method="post"
        renderIcon={<IconStudentViewLine />}
        margin="0 0 0 x-small"
      >
        {I18n.t('Student View')}
      </Button>
    )

    const isFullWidthBody = document.body.classList?.contains('full-width')
    let rightOptionsMargin = '0'
    if (isMasterCourse) {
      if (isFullWidthBody || windowWidth < 1480) {
        rightOptionsMargin = 'x-large'
      } else if (windowWidth < 1500) {
        rightOptionsMargin = 'small'
      }
    }

    const showManageButton = canReadAsAdmin
    const showStudentViewButton = showStudentView && !showingMobileNav
    return showManageButton || showObserverOptions || showStudentViewButton ? (
      <div ref={ref}>
        <View
          id="k5-course-header-options"
          as="section"
          borderWidth="0 0 small 0"
          padding="0 0 medium 0"
          margin="0 0 medium 0"
        >
          <Flex alignItems="center" justifyItems="space-between">
            <Flex.Item>{showManageButton && <ManageButton />}</Flex.Item>
            <Flex.Item textAlign="end" shouldGrow={true} margin={`0 ${rightOptionsMargin} 0 0`}>
              {showObserverOptions && (
                <View as="div" display="inline-block" width={showingMobileNav ? '100%' : '16em'}>
                  <ScreenReaderContent>
                    <Heading as="h1">{courseContext}</Heading>
                  </ScreenReaderContent>
                  <ObserverOptions
                    observedUsersList={observedUsersList}
                    currentUser={currentUser}
                    handleChangeObservedUser={handleChangeObservedUser}
                    canAddObservee={false}
                  />
                </View>
              )}
              {showStudentViewButton && <StudentViewButton />}
            </Flex.Item>
          </Flex>
        </View>
      </div>
    ) : null
  }
)

CourseHeaderOptions.propTypes = {
  settingsPath: PropTypes.string.isRequired,
  showStudentView: PropTypes.bool.isRequired,
  studentViewPath: PropTypes.string.isRequired,
  canReadAsAdmin: PropTypes.bool.isRequired,
  courseContext: PropTypes.string.isRequired,
  observedUsersList: ObservedUsersListShape.isRequired,
  handleChangeObservedUser: PropTypes.func.isRequired,
  currentUser: PropTypes.object.isRequired,
  showingMobileNav: PropTypes.bool.isRequired,
  showObserverOptions: PropTypes.bool.isRequired,
  isMasterCourse: PropTypes.bool.isRequired,
  windowWidth: PropTypes.number.isRequired,
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
  observedUsersList,
  selfEnrollment,
  tabContentOnly,
  isMasterCourse,
  showImmersiveReader,
  gradingScheme,
  restrictQuantitativeData,
}) {
  const initialObservedId = observedUsersList.find(o => o.id === savedObservedId(currentUser.id))
    ? savedObservedId(currentUser.id)
    : null

  const renderTabs = toRenderTabs(tabs, hasSyllabusBody)
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab, renderTabs)
  const [tabsRef, setTabsRef] = useState(null)
  const [observedUserId, setObservedUserId] = useState(initialObservedId)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    singleCourse: true,
    observedUserId,
    isObserver:
      observedUsersList.length > 1 ||
      (observedUsersList.length === 1 && observedUsersList[0].id !== currentUser.id),
  })

  /* Rails renders the modules partial into #k5-modules-container. After the first render, we hide that div and
     move it into the main <View> of K5Course so the sticky tabs stick. Then show/hide it (if there's at least one
     module) based off currentTab */
  const modulesRef = useRef(null)
  const contentRef = useRef(null)
  const headerRef = useRef(null)
  const headerOptionsRef = useRef(null)
  const tabsPaddingRef = useRef(null)
  const [modulesExist, setModulesExist] = useState(true)
  const [windowSize, setWindowSize] = useState(() => getWindowSize())
  const showObserverOptions = shouldShowObserverOptions(observedUsersList, currentUser)
  const showingMobileNav = windowSize.width < MOBILE_NAV_BREAKPOINT_PX
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
    // Height of the header options (manage, student view) - may be 0 for some users
    const headerOptionsHeight =
      headerOptionsRef.current?.getBoundingClientRect().bottom + window.scrollY || 0
    // If we don't have a ref to the header's width yet, use viewport width as a best guess
    const headerHeight = (headerRef.current?.offsetWidth || windowSize.width) / HERO_ASPECT_RATIO
    if (tabsRef && !tabsPaddingRef.current) {
      tabsPaddingRef.current =
        tabsRef.getBoundingClientRect().bottom - headerHeight - headerOptionsHeight
    }
    // This is the vertical px by which the header will shrink when sticky
    const headerShrinkDiff = headerRef.current
      ? headerHeight - HERO_STICKY_HEIGHT_PX + headerOptionsHeight
      : 0
    // This is the vertical px by which the content overflows the viewport
    const contentScrollOverflow = document.body.scrollHeight - windowSize.height
    // If the window height is smaller than the height of the header, flickering and weird
    // sticky behavior occurs. This is a hack to force the header to shrink when we get
    // somewhat close to that size
    const isWindowTooSmall = tabsPaddingRef.current
      ? windowSize.height <
        tabsPaddingRef.current + headerHeight + headerOptionsHeight + STICKY_HERO_CUTOFF_BUFFER_PX
      : false
    // Make sure that there is more vertical scroll overflow height than the header will
    // lose when transitioning to a sticky state. Otherwise the header will flicker rapidly
    // between sticky and non-sticky states.
    const shouldShrink =
      (sticky && activeTab.current === currentTab && contentScrollOverflow > headerShrinkDiff) ||
      isWindowTooSmall
    return (
      <View id="k5-course-header" as="div" padding={sticky && shouldShrink ? 'medium 0 0 0' : '0'}>
        <CourseHeaderHero
          name={name}
          image={bannerImageUrl || cardImageUrl}
          backgroundColor={color || DEFAULT_COURSE_COLOR}
          height={shouldShrink ? HERO_STICKY_HEIGHT_PX : headerHeight}
          selfEnrollment={selfEnrollment}
          showingMobileNav={showingMobileNav}
          ref={headerRef}
          observerMode={showObserverOptions}
          shouldShrink={shouldShrink}
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
    canReadAnnouncements,
  })

  return (
    <K5DashboardContext.Provider
      value={{
        assignmentsDueToday,
        assignmentsMissing,
        assignmentsCompletedForToday,
        isStudent: plannerEnabled,
      }}
    >
      <View
        as="section"
        data-testid="main-content"
        elementRef={e => (contentRef.current = e)}
        onFocus={scrollElementIntoViewIfCoveredByHeader(tabsRef)}
      >
        <CourseHeaderOptions
          canReadAsAdmin={canReadAsAdmin}
          settingsPath={settingsPath}
          showStudentView={showStudentView}
          studentViewPath={`${studentViewPath + window.location.hash}`}
          courseContext={name}
          observedUsersList={observedUsersList}
          currentUser={currentUser}
          handleChangeObservedUser={setObservedUserId}
          showingMobileNav={showingMobileNav}
          showObserverOptions={showObserverOptions}
          ref={headerOptionsRef}
          isMasterCourse={isMasterCourse}
          windowWidth={windowSize?.width}
        />
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
          (courseOverview.body || courseOverview.body?.length === 0 ? (
            <OverviewPage
              content={courseOverview.body}
              url={`/courses/${id}/pages/${courseOverview.url}/edit`}
              canEdit={courseOverview.canEdit}
              showImmersiveReader={showImmersiveReader}
            />
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
          userHasEnrollments={true}
          visible={currentTab === TAB_IDS.SCHEDULE}
          singleCourse={true}
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
            gradingScheme={gradingScheme}
            restrictQuantitativeData={restrictQuantitativeData}
          />
        )}
        <ResourcesPage
          cards={[{id, originalName: name, shortName: name, isHomeroom: false, canManage}]}
          cardsSettled={true}
          visible={currentTab === TAB_IDS.RESOURCES}
          showStaff={false}
          isSingleCourse={true}
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
  courseOverview: PropTypes.shape({
    body: PropTypes.string,
    url: PropTypes.string,
    canEdit: PropTypes.bool,
  }).isRequired,
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
  observedUsersList: ObservedUsersListShape.isRequired,
  selfEnrollment: PropTypes.object,
  tabContentOnly: PropTypes.bool,
  isMasterCourse: PropTypes.bool.isRequired,
  showImmersiveReader: PropTypes.bool.isRequired,
  gradingScheme: PropTypes.array,
  restrictQuantitativeData: PropTypes.bool,
}

const WrappedK5Course = connect(mapStateToProps)(K5Course)

const k5Theme = getK5ThemeOverrides()

export default props => (
  <InstUISettingsProvider theme={{componentOverrides: k5Theme}}>
    <Provider store={store}>
      <WrappedK5Course {...props} />
    </Provider>
  </InstUISettingsProvider>
)
