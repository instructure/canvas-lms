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

import PropTypes from 'prop-types'
import React, {useMemo, useState, useEffect, useContext} from 'react'
import {AddressBook, USER_TYPE, CONTEXT_TYPE} from '../../components/AddressBook/AddressBook'
import {
  ADDRESS_BOOK_RECIPIENTS,
  ADDRESS_BOOK_RECIPIENTS_WITH_COMMON_COURSES,
} from '../../../graphql/Queries'
import {useQuery} from 'react-apollo'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conversations_2')

export const AddressBookContainer = props => {
  const {setOnSuccess} = useContext(AlertManagerContext)

  const userID = ENV.current_user_id?.toString()
  const [filterHistory, setFilterHistory] = useState([
    {
      context: null,
    },
  ])
  const [inputValue, setInputValue] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [isLoadingMoreData, setIsLoadingMoreData] = useState(false)
  const [canSendAllMessage, setCanSendAllMessage] = useState(false)
  const [isMenuOpen, setIsMenuOpen] = useState(props.open)

  const isOnObserverSubmenu = () => {
    return (
      props.courseContextCode !== '' &&
      filterHistory.find(item => item?.context?.contextID?.match(/course_.+_observers/i)) !==
        undefined
    )
  }

  useEffect(() => {
    const interval = setInterval(() => {
      if (inputValue !== searchTerm) {
        setSearchTerm(inputValue)
      }
    }, 500)

    return () => clearInterval(interval)
  }, [inputValue, searchTerm, setSearchTerm])

  const skipAddressBookRecipientsQuery = () => {
    // if menu is closed, or if both your search term is empty
    // or your search has nosubmenu or context to use
    const latestFilterHistoryItem = filterHistory[filterHistory.length - 1]
    if (
      !isMenuOpen ||
      (!searchTerm &&
        !(
          latestFilterHistoryItem?.subMenuSelection ||
          latestFilterHistoryItem?.context?.contextID ||
          props.courseContextCode
        ))
    ) {
      return true
    }
    return false
  }
  const addressBookRecipientsQuery = useQuery(
    props.includeCommonCourses
      ? ADDRESS_BOOK_RECIPIENTS_WITH_COMMON_COURSES
      : ADDRESS_BOOK_RECIPIENTS,
    {
      skip: skipAddressBookRecipientsQuery(),
      variables: {
        context:
          filterHistory[filterHistory.length - 1]?.context?.contextID ||
          props.courseContextCode ||
          null,
        search: searchTerm,
        userID,
        courseContextCode: props.courseContextCode,
      },
      notifyOnNetworkStatusChange: true,
    }
  )
  const {loading, data} = addressBookRecipientsQuery

  useEffect(() => {
    if (loading) {
      const loadingMessage =
        searchTerm.length > 0
          ? I18n.t('Loading address book results for %{term}', {term: searchTerm})
          : I18n.t('Loading address book results')

      setOnSuccess(loadingMessage)
    } else if (data) {
      const searchResults = [
        ...(data?.legacyNode?.recipients?.usersConnection?.nodes ?? []),
        ...(data?.legacyNode?.recipients?.contextsConnection?.nodes ?? []),
      ]

      const loadedMessage = I18n.t(
        {
          zero: 'No Address book results found',
          one: '1 Address book result loaded',
          other: '%{count} Address book results loaded',
        },
        {count: searchResults.length}
      )
      setOnSuccess(loadedMessage)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [loading, data, searchTerm])

  useEffect(() => {
    if (
      props.activeCourseFilter?.contextID === null &&
      props.activeCourseFilter?.contextName === null
    ) {
      setInputValue('')
      setFilterHistory([
        {
          context: null,
        },
      ])
    }
  }, [props.activeCourseFilter])

  useEffect(() => {
    props.onInputValueChange(searchTerm)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm])

  const fetchMoreMenuData = () => {
    setIsLoadingMoreData(true)
    addressBookRecipientsQuery.fetchMore({
      variables: {
        context: filterHistory[filterHistory.length - 1]?.context?.contextID,
        search: searchTerm,
        userID,
        afterUser: data?.legacyNode?.recipients?.usersConnection?.pageInfo.endCursor,
        afterContext: data?.legacyNode?.recipients?.contextsConnection?.pageInfo.endCursor,
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        setIsLoadingMoreData(false)
        return {
          legacyNode: {
            id: previousResult.legacyNode.id,
            recipients: {
              sendMessagesAll: previousResult.legacyNode?.recipients?.sendMessagesAll,
              contextsConnection: {
                nodes: [
                  ...previousResult.legacyNode?.recipients?.contextsConnection?.nodes,
                  ...fetchMoreResult.legacyNode?.recipients?.contextsConnection?.nodes,
                ],
                pageInfo: fetchMoreResult.legacyNode?.recipients?.contextsConnection?.pageInfo,
                __typename: 'MessageableContextConnection',
              },
              usersConnection: {
                nodes: [
                  ...previousResult.legacyNode?.recipients?.usersConnection?.nodes,
                  ...fetchMoreResult.legacyNode?.recipients?.usersConnection?.nodes,
                ],
                pageInfo: fetchMoreResult.legacyNode?.recipients?.usersConnection?.pageInfo,
                __typename: 'MessageableUserConnection',
              },
              __typename: 'Recipients',
            },
            __typename: 'User',
          },
        }
      },
    })
  }

  const addFilterHistory = chosenFilter => {
    const newFilterHistory = filterHistory
    newFilterHistory.push(chosenFilter)
    setFilterHistory([...newFilterHistory])
  }

  const removeLastFilterHistory = () => {
    const newFilterHistory = filterHistory
    newFilterHistory.pop()
    setFilterHistory([...newFilterHistory])
  }

  const getCommonCoursesInformation = commonCourses => {
    const activeEnrollments = commonCourses?.nodes.filter(
      courseEnrollment => courseEnrollment.state === 'active'
    )
    return activeEnrollments.map(
      courseEnrollment =>
        (courseEnrollment = {
          courseID: courseEnrollment.course._id,
          courseRole: courseEnrollment.type,
        })
    )
  }

  useEffect(() => {
    if (props.activeCourseFilter && !filterHistory[filterHistory.length - 1]?.context) {
      addFilterHistory({
        context: {
          contextID: props.activeCourseFilter.contextID,
          contextName: props.activeCourseFilter.contextName,
        },
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.activeCourseFilter])

  const menuData = useMemo(() => {
    // If loading is true and there is no data, return an empty array.
    if (loading && !data) {
      return []
    }

    // Extract contextData: { id, name, and context_type}
    let contextData = (data?.legacyNode?.recipients?.contextsConnection?.nodes || []).map(c => {
      return {
        id: c.id,
        name: c.name,
        userCount: c.userCount,
        itemType: CONTEXT_TYPE,
      }
    })

    // Extract userData: {_id, id, name, commonCoursesInfo, observerEnrollments, and itemType}
    let userData = (data?.legacyNode?.recipients?.usersConnection?.nodes || []).map(u => {
      return {
        _id: u._id,
        id: u.id,
        name: u.shortName,
        commonCoursesInfo: props.includeCommonCourses
          ? getCommonCoursesInformation(u.commonCoursesConnection)
          : [],
        observerEnrollments: u?.observerEnrollmentsConnection?.nodes || [],
        itemType: USER_TYPE,
      }
    })

    // Ensure contextData and userData are not null.
    contextData = contextData || []
    userData = userData || []

    // Set isLast property to the last items in contextData and userData if they are not loading.
    // this is used to know which menu item will trigger a fetchMore call.
    if (userData.length > 0 && !loading) {
      userData[userData.length - 1].isLast = true
    }
    if (contextData.length > 0 && !loading) {
      contextData[contextData.length - 1].isLast = true
    }

    // Set the state for canSendAllMessage based on the data object.
    setCanSendAllMessage(!!data?.legacyNode?.recipients?.sendMessagesAll)

    // Remove duplicates from contextData and userData arrays based on their id property.
    contextData = [...new Map(contextData.map(item => [item.id, item])).values()]
    userData = [...new Map(userData.map(item => [item.id, item])).values()]

    // Check if there is a subMenuSelection in filterHistory and searchTerm is an empty string.
    if (filterHistory[filterHistory.length - 1]?.subMenuSelection && searchTerm === '') {
      const selection = filterHistory[filterHistory.length - 1]?.subMenuSelection
      // Filter the menuData based on the subMenuSelection value.
      const filteredMenuData = selection.includes('Course')
        ? {contextData, userData: []}
        : {userData, contextData: []}
      return filteredMenuData
    }
    // If the filter is on the initialCourseMenu, count up the context totals
    // Otherwise use the totalRecipientCount for the selected context
    const totalRecipientCount =
      filterHistory[filterHistory.length - 1]?.context?.totalRecipientCount ||
      contextData.reduce((total, item) => total + (item?.userCount || 0), 0)

    // If there is no subMenuSelection, return the full menuData with both contextData, userData, and recipient count data.
    return {contextData, userData, totalRecipientCount}
  }, [loading, data, filterHistory, searchTerm, props.includeCommonCourses])
  const handleSelect = (item, isContext, isBackButton, isSubmenu) => {
    if (isContext) {
      addFilterHistory({
        context: {contextID: item.id, contextName: item.name, totalRecipientCount: item.userCount},
      })
    } else if (isSubmenu) {
      addFilterHistory({
        context: null,
        subMenuSelection: item.id,
      })
    } else if (isBackButton) {
      if (inputValue) {
        setInputValue('')
      } else {
        removeLastFilterHistory()
      }
    }
  }

  return (
    <AddressBook
      menuData={menuData}
      hasMoreMenuData={
        data?.legacyNode?.recipients?.usersConnection?.pageInfo?.hasNextPage ||
        data?.legacyNode?.recipients?.contextsConnection?.pageInfo?.hasNextPage
      }
      fetchMoreMenuData={fetchMoreMenuData}
      isLoadingMoreMenuData={isLoadingMoreData}
      isLoading={loading}
      isSubMenu={filterHistory.length > 1 || inputValue !== ''}
      onSelect={handleSelect}
      onTextChange={setInputValue}
      inputValue={inputValue}
      onUserFilterSelect={props.onUserFilterSelect}
      onSelectedIdsChange={props.onSelectedIdsChange}
      selectedRecipients={props.selectedRecipients}
      limitTagCount={props.limitTagCount}
      width={props.width}
      isMenuOpen={isMenuOpen}
      setIsMenuOpen={setIsMenuOpen}
      hasSelectAllFilterOption={props.hasSelectAllFilterOption && canSendAllMessage}
      currentFilter={filterHistory[filterHistory.length - 1]}
      activeCourseFilter={props.activeCourseFilter}
      addressBookMessages={props.addressBookMessages}
      isOnObserverSubmenu={isOnObserverSubmenu()}
      placeholder={props.placeholder}
      addressBookLabel={props.addressBookLabel}
    />
  )
}

AddressBookContainer.propTypes = {
  /**
   * Callback which provides an array of selected items
   */
  onSelectedIdsChange: PropTypes.func,
  onInputValueChange: PropTypes.func,
  /**
   * An array of selected recepient objects
   */
  selectedRecipients: PropTypes.array,
  /**
   * Number that limits selected item count
   */
  limitTagCount: PropTypes.number,
  /**
   * Width of AddressBook component
   */
  width: PropTypes.string,
  /**
   * Bool to control open/closed state of menu for testing
   */
  open: PropTypes.bool,
  /**
   * use State function to set user filter for conversations
   */
  onUserFilterSelect: PropTypes.func,
  /**
   * object that contains the current course filter information for the compose modal
   */
  activeCourseFilter: PropTypes.object,
  /**
   * bool which determines if "select all" in a context menu appears
   */
  hasSelectAllFilterOption: PropTypes.bool,
  includeCommonCourses: PropTypes.bool,
  addressBookMessages: PropTypes.array,
  courseContextCode: PropTypes.string,
  /**
   * placeholder text for AddressBook search text input
   */
  placeholder: PropTypes.string,
  addressBookLabel: PropTypes.string,
}

AddressBookContainer.defaultProps = {
  onSelectedIdsChange: () => {},
  onInputValueChange: () => {},
  hasSelectAllFilterOption: false,
  courseContextCode: '',
  includeCommonCourses: false,
  open: false,
}

export default AddressBookContainer
