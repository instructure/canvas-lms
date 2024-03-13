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

import React, {useEffect, useState} from 'react'
import {EnrollmentTreeGroup} from './EnrollmentTreeGroup'
import {Spinner} from '@instructure/ui-spinner'
import type {Course, Enrollment, NodeStructure, Role, RoleChoice, Section} from './types'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import cloneDeep from 'lodash/cloneDeep'

const I18n = useI18nScope('temporary_enrollment')

export interface Props {
  enrollmentsByCourse: Course[]
  roles: Role[]
  selectedRole: RoleChoice
  createEnroll?: Function
  tempEnrollmentsPairing?: Enrollment[] | null
}

export function EnrollmentTree(props: Props) {
  const [tree, setTree] = useState([] as NodeStructure[])
  const [loading, setLoading] = useState(true)

  const sortByBase = (a: NodeStructure, b: NodeStructure) => {
    const aId = a.id.slice(1)
    const bId = b.id.slice(1)

    const aBase = props.roles[props.roles.findIndex((r: Role) => r.id === aId)].base_role_name
    const bBase = props.roles[props.roles.findIndex((r: Role) => r.id === bId)].base_role_name

    switch (aBase) {
      case 'TeacherEnrollment':
        return -1
      case 'TaEnrollment':
        if (bBase === 'TeacherEnrollment') {
          return 1
        } else {
          return -1
        }
      case 'DesignerEnrollment':
        if (bBase === 'StudentEnrollment') {
          return -1
        } else {
          return 1
        }
      case 'StudentEnrollment':
        return 1
      default:
        return 0
    }
  }

  useEffect(() => {
    if (props.createEnroll) {
      props.createEnroll(tree)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.createEnroll])

  useEffect(() => {
    if (loading) return
    // update `isMismatch` of a course based on the `isCheck` status of its sections
    const updateCourseMismatch = (course: NodeStructure) => {
      course.isMismatch = course.children.some(section => section.isCheck)
    }
    // use a deep copy of `tree` to avoid direct state mutation and ensure proper React state updates
    const treeCopy = cloneDeep(tree)
    treeCopy.forEach((role: NodeStructure) => {
      if (role.label.toLowerCase() === props.selectedRole.name.toLowerCase()) {
        role.isToggle = true
        role.children.forEach((course: NodeStructure) => {
          course.isMismatch = false
          course.children.forEach(section => (section.isMismatch = false))
        })
      } else {
        role.children.forEach((course: NodeStructure) => {
          course.children.forEach(section => (section.isMismatch = section.isCheck))
          updateCourseMismatch(course)
        })
      }
    })
    setTree(treeCopy)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.selectedRole.name, loading])

  // build the object tree
  useEffect(() => {
    let courseEnrollmentMap: Map<string | number, Enrollment> | undefined
    if (props.tempEnrollmentsPairing) {
      courseEnrollmentMap = new Map(
        props.tempEnrollmentsPairing.map(enrollment => [enrollment.course_id, enrollment])
      )
    }
    // populate a data structure with the information needed for each row
    // ids are shared between role/course/section, so we need a prefix to distinguish type
    props.enrollmentsByCourse.forEach((course: Course) => {
      course.enrollments.forEach((enrollment: Enrollment) => {
        const roleData = props.roles.find((role: Role) => role.id === enrollment.role_id)
        if (!roleData) {
          return
        }
        const courseCheckedByDefault =
          course.workflow_state === 'available' &&
          enrollment.enrollment_state === 'active' &&
          roleData.base_role_name === 'TeacherEnrollment'
        // unique id for each role
        const roleId = 'r' + enrollment.role_id
        let roleCheck: boolean
        if (courseEnrollmentMap) {
          roleCheck = course.id === courseEnrollmentMap.get(course.id)?.course_id
        } else {
          roleCheck = false
        }
        let roleNode: NodeStructure = {
          id: roleId,
          label: roleData?.label,
          // eslint-disable-next-line no-array-constructor
          children: new Array<NodeStructure>(),
          isToggle: false,
          isMixed: false,
          isCheck: roleCheck,
        }
        roleNode = findOrAppendNewNode(roleNode, tree)
        const courseId = course.id
        const cId = 'c' + courseId
        const childArray: NodeStructure[] = []
        let courseNode: NodeStructure = {
          isMismatch: false,
          id: cId,
          label: course.name,
          parent: roleNode,
          isCheck: props.tempEnrollmentsPairing ? roleCheck : courseCheckedByDefault,
          children: childArray,
          isToggle: false,
          workflowState: course.workflow_state,
          isMixed: false,
        }
        courseNode = findOrAppendNewNode(courseNode, roleNode.children)
        course.sections.forEach((section: Section) => {
          // skip if section role doesn't match role base
          if (section.enrollment_role !== roleData.base_role_name) {
            return
          }
          let sectionCheck: boolean
          if (courseEnrollmentMap) {
            const courseEnrollments = courseEnrollmentMap.get(course.id)
            sectionCheck = section.id === courseEnrollments?.course_section_id
          } else {
            sectionCheck = courseNode.isCheck
          }
          const sectionNode = {
            isMismatch: false,
            id: `s${section.id}`,
            label: section.name,
            parent: courseNode,
            isCheck: sectionCheck,
            children: [],
            enrollId: section.id,
            isMixed: false,
          }
          findOrAppendNewNode(sectionNode, courseNode.children)
        })
        if (courseEnrollmentMap || courseCheckedByDefault) {
          updateParentBasedOnChildren(courseNode)
          updateParentBasedOnChildren(roleNode)
        }
      })
    })
    tree.sort(sortByBase)
    setTree([...tree])
    setLoading(false)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.tempEnrollmentsPairing, props.enrollmentsByCourse])

  const findOrAppendNewNode = (currentNode: NodeStructure, parentNode: NodeStructure[]) => {
    const matchingNode = parentNode.find((node: NodeStructure) => node.id === currentNode.id)
    if (!matchingNode) {
      parentNode.push(currentNode)
    }
    return matchingNode || currentNode
  }

  const locateNode = (node: NodeStructure) => {
    let currNode = node
    const nodePath: string[] = [currNode.id]
    while (currNode.parent) {
      nodePath.push(currNode.parent.id)
      currNode = currNode.parent
    }
    const rId = nodePath[nodePath.length - 1]

    let nextIndex = tree.findIndex(n => n.id === nodePath[nodePath.length - 1])
    let nextNode = tree[nextIndex]
    for (let i = nodePath.length - 2; i >= 0; i--) {
      nextIndex = nextNode.children.findIndex(n => n.id === nodePath[i])
      nextNode = nextNode.children[nextIndex]
    }
    currNode = nextNode
    return {currNode, rId}
  }

  const handleUpdateTreeCheck = (node: NodeStructure, newState: boolean) => {
    // change all children to match status of parent
    const {currNode, rId} = locateNode(node)
    const isRole = rId.slice(1) === props.selectedRole.id || props.selectedRole.id === ''
    if (currNode.children) {
      for (const c of currNode.children) {
        c.isMismatch = isRole ? false : newState
        c.isCheck = newState
        if (c.children) {
          for (const s of c.children) {
            s.isMismatch = isRole ? false : newState
            s.isCheck = newState
          }
        }
      }
    }
    currNode.isCheck = newState
    currNode.isMixed = false
    currNode.isMismatch = newState
    if (isRole) {
      currNode.isMismatch = false
    }
    // set parents to mixed based on sibling state
    setParents(currNode, newState, isRole)
    setTree([...tree])
  }

  const setParents = (currNode: NodeStructure, newState: boolean, isRole: boolean) => {
    let sibMixed = false
    if (currNode.parent) {
      const parent = currNode.parent
      for (const siblings of parent.children) {
        if (siblings.isCheck !== newState) {
          sibMixed = true
        }
      }
      parent.isCheck = sibMixed ? false : newState
      parent.isMixed = sibMixed
      parent.isMismatch = sibMixed || newState
      // again for role parents
      if (isRole) {
        parent.isMismatch = false
      }
      if (parent.parent) {
        const roleParent = parent.parent
        let auntMixed = false
        for (const siblings of roleParent.children) {
          if (siblings.isCheck !== newState || siblings.isMixed) {
            auntMixed = true
          }
        }
        roleParent.isCheck = auntMixed ? false : newState
        roleParent.isMixed = auntMixed
      }
    } else {
      currNode.isMixed = false
    }
  }

  const updateParentBasedOnChildren = (parent: NodeStructure) => {
    let allChecked = parent.children.length > 0
    let anyChecked = false
    let anyMixed = false
    for (const child of parent.children) {
      if (child.isCheck) {
        anyChecked = true
      } else {
        allChecked = false
      }
      if (child.isMixed) {
        anyMixed = true
      }
    }
    parent.isCheck = allChecked && !anyMixed
    parent.isMixed = (!allChecked && anyChecked) || anyMixed
  }

  const handleUpdateTreeToggle = (node: NodeStructure, newState: boolean) => {
    const {currNode} = locateNode(node)
    currNode.isToggle = newState
    setTree([...tree])
  }

  const renderTree = () => {
    const roleElements = []
    for (const role in tree) {
      roleElements.push(
        <Flex.Item key={tree[role].id} shouldGrow={true} overflowY="visible">
          <EnrollmentTreeGroup
            id={tree[role].id}
            label={tree[role].label}
            indent="0"
            updateCheck={handleUpdateTreeCheck}
            updateToggle={handleUpdateTreeToggle}
            isCheck={tree[role].isCheck}
            isToggle={tree[role].isToggle}
            isMixed={tree[role].isMixed}
          >
            {[...tree[role].children]}
          </EnrollmentTreeGroup>
        </Flex.Item>
      )
    }
    return (
      <Flex gap="medium" direction="column">
        {roleElements}
      </Flex>
    )
  }

  if (loading) {
    return (
      <Flex justifyItems="center" alignItems="center">
        <Spinner renderTitle={I18n.t('Loading enrollments')} />
      </Flex>
    )
  } else {
    return renderTree()
  }
}
