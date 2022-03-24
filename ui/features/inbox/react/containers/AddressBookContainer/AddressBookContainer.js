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
import React, {useMemo, useState} from 'react'
import {AddressBook, USER_TYPE, CONTEXT_TYPE} from '../../components/AddressBook/AddressBook'
import {ADDRESS_BOOK_RECIPIENTS} from '../../../graphql/Queries'
import {useQuery} from 'react-apollo'

export const AddressBookContainer = props => {
  const userID = ENV.current_user_id?.toString()
  const [filterHistory, setFilterHistory] = useState([
    {
      context: null
    }
  ])
  const [inputValue, setInputValue] = useState('')
  const [isLoadingMoreData, setIsLoadingMoreData] = useState(false)

  const addressBookRecipientsQuery = useQuery(ADDRESS_BOOK_RECIPIENTS, {
    variables: {
      context: filterHistory[filterHistory.length - 1]?.context?.contextID,
      search: inputValue,
      userID
    },
    notifyOnNetworkStatusChange: true
  })
  const {loading, data} = addressBookRecipientsQuery

  const fetchMoreMenuData = () => {
    setIsLoadingMoreData(true)
    addressBookRecipientsQuery.fetchMore({
      variables: {
        context: filterHistory[filterHistory.length - 1]?.context?.contextID,
        search: inputValue,
        userID,
        afterUser: data?.legacyNode?.recipients?.usersConnection?.pageInfo.endCursor
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        setIsLoadingMoreData(false)
        return {
          legacyNode: {
            ...previousResult.legacyNode,
            recipients: {
              contextsConnection: fetchMoreResult.legacyNode?.recipients?.contextsConnection,
              usersConnection: {
                nodes: [
                  ...previousResult.legacyNode?.recipients?.usersConnection?.nodes,
                  ...fetchMoreResult.legacyNode?.recipients?.usersConnection?.nodes
                ],
                pageInfo: fetchMoreResult.legacyNode?.recipients?.usersConnection?.pageInfo,
                __typename: 'MessageableUserConnection'
              },
              __typename: 'Recipients'
            }
          }
        }
      }
    })
  }

  const addFilterHistory = chosenFilter => {
    const newFilterHistor = filterHistory
    newFilterHistor.push(chosenFilter)
    setFilterHistory([...newFilterHistor])
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
          courseRole: courseEnrollment.type
        })
    )
  }

  if (props.activeCourseFilter && !filterHistory[filterHistory.length - 1]?.context) {
    addFilterHistory({
      context: {
        contextID: props.activeCourseFilter.contextID,
        contextName: props.activeCourseFilter.contextName
      }
    })
  }

  const menuData = useMemo(() => {
    if (loading && !data) {
      return []
    }

    let contextData = []
    let userData = []

    contextData = data?.legacyNode?.recipients?.contextsConnection?.nodes.map(c => {
      return {
        id: c.id,
        name: c.name,
        itemType: CONTEXT_TYPE
      }
    })

    userData = data?.legacyNode?.recipients?.usersConnection?.nodes.map(u => {
      return {
        _id: u._id,
        id: u.id,
        name: u.name,
        commonCoursesInfo: getCommonCoursesInformation(u.commonCoursesConnection),
        itemType: USER_TYPE
      }
    })

    if (!contextData) {
      contextData = []
    }
    if (!userData) {
      userData = []
    }
    if (userData.length > 0 && !loading) {
      userData[userData.length - 1].isLast = true
    }
    if (filterHistory[filterHistory.length - 1]?.subMenuSelection && inputValue === '') {
      const selection = filterHistory[filterHistory.length - 1]?.subMenuSelection
      const filteredMenuData = selection.includes('Course')
        ? {contextData, userData: []}
        : {userData, contextData: []}
      return filteredMenuData
    }

    return {contextData, userData}
  }, [loading, data, filterHistory, inputValue])

  const handleSelect = (item, isContext, isBackButton, isSubmenu) => {
    if (isContext) {
      addFilterHistory({
        context: {contextID: item.id, contextName: item.name}
      })
    } else if (isSubmenu) {
      addFilterHistory({
        context: null,
        subMenuSelection: item.id
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
      hasMoreMenuData={data?.legacyNode?.recipients?.usersConnection?.pageInfo?.hasNextPage}
      fetchMoreMenuData={fetchMoreMenuData}
      isLoadingMoreMenuData={isLoadingMoreData}
      isLoading={loading}
      isSubMenu={filterHistory.length > 1 || inputValue !== ''}
      onSelect={handleSelect}
      onTextChange={setInputValue}
      inputValue={inputValue}
      onUserFilterSelect={props.onUserFilterSelect}
      onSelectedIdsChange={props.onSelectedIdsChange}
      limitTagCount={props.limitTagCount}
      width={props.width}
      open={props.open}
    />
  )
}

AddressBookContainer.propTypes = {
  /**
   * Callback which provides an array of selected items
   */
  onSelectedIdsChange: PropTypes.func,
  /**
   * Number that liits selected item count
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
   * use State function to set current context for addressbook
   */
  activeCourseFilter: PropTypes.object
}

AddressBookContainer.defaultProps = {
  onSelectedIdsChange: () => {}
}

export default AddressBookContainer
