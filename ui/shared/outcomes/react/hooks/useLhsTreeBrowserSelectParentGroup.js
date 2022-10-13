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

import {useEffect, useRef} from 'react'

const useLhsTreeBrowserSelectParentGroup = ({
  selectedParentGroupId,
  selectedGroupId,
  collections,
  queryCollections,
}) => {
  const parentGroupButtonRef = useRef(null)
  const treeBrowserViewRef = useRef(null)
  // Store the current parent group button in a ref for selectParentGroupInLhs
  useEffect(() => {
    if (selectedParentGroupId && selectedGroupId) {
      const parentName = collections[selectedParentGroupId].name
      const groupName = collections[selectedGroupId].name

      const getButtonsWithText = (parent, text) =>
        Array.from(parent.querySelectorAll('button')).filter(btn => btn.textContent === text)

      // get the parent button which has the deleted group as child
      // this will avoid clicking in parent group that has the same name
      // the perfect scenario here would be store a ref with all the group buttons in the lhs
      // and use that ref, but we don't have that option, do we?
      parentGroupButtonRef.current =
        treeBrowserViewRef.current &&
        getButtonsWithText(treeBrowserViewRef.current, parentName).find(
          parentButton => getButtonsWithText(parentButton.parentNode, groupName).length > 0
        )
    }

    // Dont want to listen for the collections change, only when selected
    // group and parent changes
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedParentGroupId, selectedGroupId])

  const selectParentGroupInLhs = () => {
    if (selectedParentGroupId) {
      // if treebrowser is visible
      if (parentGroupButtonRef.current) {
        // double click on parent group to "select" it
        const button = parentGroupButtonRef.current

        button.click()
        // Timeout since without it the instui treebrowser won't open correctly
        setTimeout(() => {
          button.click()
        }, 100)
      } else {
        /* TODO: check if this will be enough for the mobile version in OUT-4183 to select the parent group after a group is deleted */
        queryCollections({id: selectedParentGroupId})
      }
    }
  }

  return {
    selectParentGroupInLhs,
    treeBrowserViewRef,
  }
}

export default useLhsTreeBrowserSelectParentGroup
