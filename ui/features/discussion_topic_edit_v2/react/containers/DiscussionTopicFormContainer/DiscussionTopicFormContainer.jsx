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

import React, {useCallback, useContext, useEffect, useMemo, useState} from 'react'

import {useMutation, useQuery} from '@apollo/client'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import TopNavPortalWithDefaults from '@canvas/top-navigation/react/TopNavPortalWithDefaults'
import {assignLocation} from '@canvas/util/globalUtils'
import WithBreakpoints from '@canvas/with-breakpoints'
import {usePathTransform, whenPendoReady} from '@canvas/pendo'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconCompleteSolid, IconUnpublishedLine} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {flushSync} from 'react-dom'
import {CREATE_DISCUSSION_TOPIC, UPDATE_DISCUSSION_TOPIC} from '../../../graphql/Mutations'
import {DISCUSSION_TOPIC_QUERY} from '../../../graphql/Queries'
import DiscussionTopicForm from '../../components/DiscussionTopicForm/DiscussionTopicForm'
import {SavingDiscussionTopicOverlay} from '../../components/SavingDiscussionTopicOverlay/SavingDiscussionTopicOverlay'
import {setUsageRights} from '../../util/setUsageRights'
import {getContextQuery} from '../../util/utils'

const I18n = createI18nScope('discussion_create')
const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

function DiscussionTopicFormContainer({apolloClient, breakpoints}) {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [usageRightData, setUsageRightData] = useState()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const contextType = ENV.context_is_not_group ? 'Course' : 'Group'
  const {contextQueryToUse, contextQueryVariables} = getContextQuery(contextType)

  const [latestDiscussionContextType, setLatestDiscussionContextType] = useState(null)
  const [latestDiscussionTopicId, setLatestDiscussionTopicId] = useState(null)

  const navigateToDiscussionTopicEvent = useCallback(() => {
    navigateToDiscussionTopic(latestDiscussionContextType, latestDiscussionTopicId)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [latestDiscussionContextType, latestDiscussionTopicId])

  useEffect(() => {
    window.addEventListener('navigateToDiscussionTopic', navigateToDiscussionTopicEvent)

    return () => {
      window.removeEventListener('navigateToDiscussionTopic', navigateToDiscussionTopicEvent)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [latestDiscussionContextType, latestDiscussionTopicId])

  const isAnnouncement = ENV?.DISCUSSION_TOPIC?.ATTRIBUTES?.is_announcement ?? false
  const shouldSaveMasteryPaths = ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && !isAnnouncement

  usePathTransform(whenPendoReady, 'discussion_topics', 'announcements', isAnnouncement)

  const {data: contextData, loading: courseIsLoading} = useQuery(contextQueryToUse, {
    variables: contextQueryVariables,
  })
  const currentContext = contextData?.legacyNode
  const currentDiscussionTopicId = ENV.DISCUSSION_TOPIC?.ATTRIBUTES?.id
  const isEditing = !!currentDiscussionTopicId
  const {data: topicData, loading: topicIsLoading} = useQuery(DISCUSSION_TOPIC_QUERY, {
    skip: !isEditing,
    variables: {
      discussionTopicId: currentDiscussionTopicId,
    },
  })
  const currentDiscussionTopic = topicData?.legacyNode
  const published = currentDiscussionTopic?.published ?? false

  // Use setUsageRights to save new usageRightsData
  const saveUsageRights = async (usageData, attachmentData) => {
    try {
      const basicFileSystemData = attachmentData ? [{id: attachmentData._id, type: 'File'}] : []
      const usageRights = {
        use_justification: usageData?.useJustification,
        legal_copyright: usageData?.legalCopyright || '',
        license: usageData?.license || '',
      }

      // Run API if a usageRight option is provided and there is a file/folder to update
      if (basicFileSystemData.length !== 0 && usageData?.useJustification) {
        await setUsageRights(basicFileSystemData, usageRights, ENV.context_id, contextType)
      }
    } catch (error) {
      setOnFailure(error)
    }
  }

  function navigateToDiscussionTopic(context_type, discussion_topic_id) {
    if (context_type === 'Course') {
      assignLocation(`/courses/${ENV.context_id}/discussion_topics/${discussion_topic_id}`)
    } else if (context_type === 'Group') {
      assignLocation(`/groups/${ENV.context_id}/discussion_topics/${discussion_topic_id}`)
    } else {
      setOnFailure(I18n.t('Invalid context type'))
    }
  }

  const handleFormSubmit = (formData, notifyUsers) => {
    const {usageRightsData, ...formDataWithoutUsageRights} = formData
    setUsageRightData(usageRightsData)
    if (isEditing) {
      updateDiscussionTopic({variables: {...formDataWithoutUsageRights, notifyUsers}})
    } else {
      createDiscussionTopic({variables: formDataWithoutUsageRights})
    }
  }

  const handleDiscussionTopicMutationCompletion = async (discussionTopic, delayRedirection = 0) => {
    const {_id: discussionTopicId, contextType: discussionContextType, attachment} = discussionTopic

    if (discussionTopicId && discussionContextType) {
      let shouldNavigateToDiscussionTopic = true

      try {
        if (ENV?.USAGE_RIGHTS_REQUIRED) {
          await saveUsageRights(usageRightData, attachment)
        }

        if (shouldSaveMasteryPaths && discussionTopic.assignment) {
          const {assignment} = discussionTopic

          const assignmentInfo = {
            id: assignment._id,
            grading_standard_id: assignment?.gradingStandard?.id,
            grading_type: assignment.gradingType,
            points_possible: assignment.pointsPossible,
            submission_types: 'discussion_topic',
          }

          shouldNavigateToDiscussionTopic = false
          flushSync(() => {
            setLatestDiscussionContextType(discussionContextType)
            setLatestDiscussionTopicId(discussionTopicId)
          })

          window.dispatchEvent(
            new CustomEvent('triggerMasteryPathsUpdateAssignment', {detail: {assignmentInfo}}),
          )
          window.dispatchEvent(new CustomEvent('triggerMasteryPathsSave'))
        }
      } catch (error) {
        // Handle error on saving usage rights
        setOnFailure(error)
      } finally {
        // Always navigate to the discussion topic on a successful mutation
        // In some scenarios, like when saving mastery paths, we don't want to navigate unless it happens via event
        if (shouldNavigateToDiscussionTopic) {
          // Use setTimeout to allow the user or the SR to read the success message before redirecting
          setTimeout(
            () => navigateToDiscussionTopic(discussionContextType, discussionTopicId),
            delayRedirection,
          )
        }
      }
    } else {
      setIsSubmitting(false)
      setOnFailure(I18n.t('Error with discussion topic'))
    }
  }

  const renderPublishStatusPill = () => {
    const pillProps = {
      color: published ? 'success' : undefined,
      renderIcon: published ? <IconCompleteSolid /> : <IconUnpublishedLine />,
    }

    return (
      <Pill data-testid="publish-status-pill" margin="small 0 0 0" variant="primary" {...pillProps}>
        {published ? I18n.t('Published') : I18n.t('Unpublished')}
      </Pill>
    )
  }

  const renderHeading = () => {
    const headerText = isAnnouncement ? I18n.t('Create Announcement') : I18n.t('Create Discussion')
    const titleContent = currentDiscussionTopic?.title ?? headerText
    const headerMargin = breakpoints.desktop ? '0 0 large 0' : '0 0 medium 0'
    return instUINavEnabled() ? (
      <Flex margin={headerMargin} direction="column" as="div">
        <Flex.Item margin="0" overflow="hidden">
          <Heading
            as="h1"
            level={breakpoints.ICEDesktop ? 'h1' : 'h2'}
            themeOverride={{h2FontWeight: 700}}
          >
            {titleContent}
          </Heading>
        </Flex.Item>
        {!isAnnouncement && (
          <Flex.Item margin="0" shouldShrink={true} overflowX="visible" overflowY="visible">
            {renderPublishStatusPill()}
          </Flex.Item>
        )}
      </Flex>
    ) : (
      <ScreenReaderContent>
        <h1>{titleContent}</h1>
      </ScreenReaderContent>
    )
  }

  const [createDiscussionTopic] = useMutation(CREATE_DISCUSSION_TOPIC, {
    onCompleted: completionData => {
      const newDiscussionTopic = completionData?.createDiscussionTopic?.discussionTopic
      const errors = completionData?.createDiscussionTopic?.errors

      if (errors) {
        setIsSubmitting(false)
        setOnFailure(errors.map(error => error.message).join(', '))
        return
      }

      handleDiscussionTopicMutationCompletion(newDiscussionTopic).catch(() => {
        setOnFailure(I18n.t('Error updating file usage rights'))
      })
    },
    onError: err => {
      const errMsg = (err?.graphQLErrors || []).map(error => error?.message).join(', ')
      setIsSubmitting(false)
      setOnFailure(errMsg || I18n.t('Error creating discussion topic'))
    },
  })

  const [updateDiscussionTopic] = useMutation(UPDATE_DISCUSSION_TOPIC, {
    onCompleted: completionData => {
      const {discussionTopic: updatedDiscussionTopic, errors} =
        completionData?.updateDiscussionTopic || {}

      if (!updatedDiscussionTopic && errors.length) {
        setIsSubmitting(false)

        // the current validation_error doesn't allow multiple error messages
        const message = errors[0]?.message

        setOnFailure(message || I18n.t('Error updating discussion topic'))
        return
      }

      // 2 seconds delay for the success message to be read by screen readers
      handleDiscussionTopicMutationCompletion(updatedDiscussionTopic, 1600)
        .then(() => setOnSuccess(I18n.t('Changes saved successfully'), true))
        .catch(() => {
          setOnFailure(I18n.t('Error updating file usage rights'))
        })
    },
    onError: () => {
      setIsSubmitting(false)
      setOnFailure(I18n.t('Error updating discussion topic'))
    },
  })

  if (courseIsLoading || topicIsLoading) {
    return <LoadingIndicator />
  }

  const renderForm = () => {
    return (
      <DiscussionTopicForm
        isGroupContext={contextType === 'Group'}
        isEditing={isEditing}
        currentDiscussionTopic={currentDiscussionTopic}
        isStudent={ENV.current_user_is_student}
        assignmentGroups={currentContext?.assignmentGroups}
        sections={ENV.SECTION_LIST}
        groupCategories={currentContext?.groupSets || []}
        studentEnrollments={currentContext?.usersConnection?.nodes}
        apolloClient={apolloClient}
        onSubmit={handleFormSubmit}
        isSubmitting={isSubmitting}
        setIsSubmitting={setIsSubmitting}
        breakpoints={breakpoints}
      />
    )
  }

  const handleBreadCrumbSetter = ({getCrumbs, setCrumbs}) => {
    const discussionOrAnnouncement = isAnnouncement
      ? I18n.t('Announcements')
      : I18n.t('Discussions')
    const brUrlPart = isAnnouncement ? 'announcements' : 'discussion_topics'
    const crumbs = getCrumbs()
    const baseUrl = `${crumbs[0].url}/${brUrlPart}`

    crumbs.push({name: discussionOrAnnouncement, url: baseUrl})

    if (isEditing && currentDiscussionTopic) {
      crumbs.push({
        name: currentDiscussionTopic.title,
        url: `${baseUrl}/${currentDiscussionTopicId}`,
      })
    }

    crumbs.push({name: isEditing ? I18n.t('Edit') : I18n.t('Create new'), url: ''})
    setCrumbs(crumbs)
  }

  return (
    <>
      <TopNavPortalWithDefaults getBreadCrumbSetter={handleBreadCrumbSetter} />
      <Flex direction="column">
        <Flex.Item>{renderHeading()}</Flex.Item>
        {renderForm()}
        <SavingDiscussionTopicOverlay open={isSubmitting} />
      </Flex>
    </>
  )
}

export default WithBreakpoints(DiscussionTopicFormContainer)
