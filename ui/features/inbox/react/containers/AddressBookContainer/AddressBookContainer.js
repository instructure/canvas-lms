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
import {AddressBook} from '../../components/AddressBook/AddressBook'
import {ADDRESS_BOOK_RECIPIENTS} from '../../../graphql/Queries'
import {useQuery} from 'react-apollo'

export const AddressBookContainer = props => {
  const [filterHistory, setFilterHistory] = useState([
    {
      context: null
    }
  ])
  const [inputValue, setInputValue] = useState('')

  const {data, loading} = useQuery(ADDRESS_BOOK_RECIPIENTS, {
    variables: {
      ...filterHistory[filterHistory.length - 1],
      search: inputValue,
      userID: ENV.current_user_id?.toString()
    },
    notifyOnNetworkStatusChange: true
  })

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

  const menuData = useMemo(() => {
    if (loading) {
      return []
    }

    let contextData = []
    let userData = []

    contextData = data?.legacyNode?.recipients?.contextsConnection?.nodes.map(c => {
      return {
        id: c.id,
        name: c.name
      }
    })

    userData = data?.legacyNode?.recipients?.usersConnection?.nodes.map(u => {
      return {
        id: u.id,
        name: u.name
      }
    })

    if (!contextData) {
      contextData = []
    }
    if (!userData) {
      userData = []
    }

    return [...contextData, ...userData]
  }, [data, loading])

  const handleSelect = (item, isCourse, isBackButton) => {
    if (isCourse) {
      addFilterHistory({
        context: item
      })
    } else if (isBackButton) {
      removeLastFilterHistory()
    }
  }

  return (
    <AddressBook
      menuData={menuData}
      isLoading={loading}
      isSubMenu={filterHistory.length > 1}
      onSelect={handleSelect}
      onTextChange={setInputValue}
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
   * Bool to control open/closed statte of menu for testing
   */
  open: PropTypes.bool
}

AddressBookContainer.defaultProps = {
  onSelectedIdsChange: () => {}
}

export default AddressBookContainer
