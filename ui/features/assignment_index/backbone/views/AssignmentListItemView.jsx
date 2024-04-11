//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DateAvailableColumnView from '@canvas/assignments/backbone/views/DateAvailableColumnView'
import DateDueColumnView from '@canvas/assignments/backbone/views/DateDueColumnView'
import Backbone from '@canvas/backbone'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import {scoreToPercentage} from '@canvas/grading/GradeCalculationHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import LockIconView from '@canvas/lock-icon'
import * as MoveItem from '@canvas/move-item-tray'
import PublishIconView from '@canvas/publish-icon-view'
import '@canvas/rails-flash-notifications'
import round from '@canvas/round'
import SisButtonView from '@canvas/sis/backbone/views/SisButtonView'
import {StudentViewPeerReviews} from '@canvas/student_view_peer_reviews/react/StudentViewPeerReviews'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'
import preventDefault from '@canvas/util/preventDefault'
import {scoreToGrade} from '@instructure/grading-utils'
import $ from 'jquery'
import 'jqueryui/tooltip'
import React from 'react'
import ReactDOM from 'react-dom'
import template from '../../jst/AssignmentListItem.handlebars'
import scoreTemplate from '../../jst/_assignmentListItemScore.handlebars'
import AssignmentKeyBindingsMixin from '../mixins/AssignmentKeyBindingsMixin'
import CreateAssignmentView from './CreateAssignmentView'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'

const I18n = useI18nScope('AssignmentListItemView')

let AssignmentListItemView

export default AssignmentListItemView = (function () {
  AssignmentListItemView = class AssignmentListItemView extends Backbone.View {
    constructor(...args) {
      super(...args)
      this.onMove = this.onMove.bind(this)
      this.updatePublishState = this.updatePublishState.bind(this)
      this.toggleHidden = this.toggleHidden.bind(this)
      this.createModuleToolTip = this.createModuleToolTip.bind(this)
      this.addAssignmentToList = this.addAssignmentToList.bind(this)
      this.addMigratedQuizToList = this.addMigratedQuizToList.bind(this)
      this.onDuplicate = this.onDuplicate.bind(this)
      this.onDuplicateFailedRetry = this.onDuplicateFailedRetry.bind(this)
      this.onMigrateFailedRetry = this.onMigrateFailedRetry.bind(this)
      this.onDuplicateOrImportFailedCancel = this.onDuplicateOrImportFailedCancel.bind(this)
      this.renderItemAssignToTray = this.renderItemAssignToTray.bind(this)
      this.onAssign = this.onAssign.bind(this)
      this.onDelete = this.onDelete.bind(this)
      this.onSendAssignmentTo = this.onSendAssignmentTo.bind(this)
      this.onCopyAssignmentTo = this.onCopyAssignmentTo.bind(this)
      this.onUnlockAssignment = this.onUnlockAssignment.bind(this)
      this.onLockAssignment = this.onLockAssignment.bind(this)
      this.updateScore = this.updateScore.bind(this)
      this.goToNextItem = this.goToNextItem.bind(this)
      this.goToPrevItem = this.goToPrevItem.bind(this)
      this.editItem = this.editItem.bind(this)
      this.deleteItem = this.deleteItem.bind(this)
      this.addItem = this.addItem.bind(this)
      this.showAssignment = this.showAssignment.bind(this)
      this.assignmentGroupView = this.assignmentGroupView.bind(this)
      this.visibleAssignments = this.visibleAssignments.bind(this)
      this.nextVisibleGroup = this.nextVisibleGroup.bind(this)
      this.nextAssignmentInGroup = this.nextAssignmentInGroup.bind(this)
      this.previousAssignmentInGroup = this.previousAssignmentInGroup.bind(this)
      this.focusOnAssignment = this.focusOnAssignment.bind(this)
      this.focusOnGroup = this.focusOnGroup.bind(this)
      this.focusOnGroupByID = this.focusOnGroupByID.bind(this)
      this.focusOnFirstGroup = this.focusOnFirstGroup.bind(this)
      this.onAlignmentCloneFailedRetry = this.onAlignmentCloneFailedRetry.bind(this)
      this.updateAssignmentCollectionItem = this.updateAssignmentCollectionItem.bind(this)
    }

    static initClass() {
      this.mixin(AssignmentKeyBindingsMixin)
      this.optionProperty('userIsAdmin')

      this.prototype.tagName = 'li'
      this.prototype.template = template

      this.child('publishIconView', '[data-view=publish-icon]')
      this.child('lockIconView', '[data-view=lock-icon]')
      this.child('dateDueColumnView', '[data-view=date-due]')
      this.child('dateAvailableColumnView', '[data-view=date-available]')
      this.child('editAssignmentView', '[data-view=edit-assignment]')
      this.child('sisButtonView', '[data-view=sis-button]')

      this.prototype.els = {
        '.al-trigger': '$settingsButton',
        '.edit_assignment': '$editAssignmentButton',
        '.move_assignment': '$moveAssignmentButton',
      }

      this.prototype.events = {
        'click .delete_assignment': 'onDelete',
        'click .duplicate_assignment': 'onDuplicate',
        'click .assign-to-link': 'onAssign',
        'click .send_assignment_to': 'onSendAssignmentTo',
        'click .copy_assignment_to': 'onCopyAssignmentTo',
        'click .tooltip_link': preventDefault(function () {}),
        keydown: 'handleKeys',
        mousedown: 'stopMoveIfProtected',
        'click .icon-lock': 'onUnlockAssignment',
        'click .icon-unlock': 'onLockAssignment',
        'click .move_assignment': 'onMove',
        'click .duplicate-failed-retry': 'onDuplicateFailedRetry',
        'click .migrate-failed-retry': 'onMigrateFailedRetry',
        'click .duplicate-failed-cancel': 'onDuplicateOrImportFailedCancel',
        'click .import-failed-cancel': 'onDuplicateOrImportFailedCancel',
        'click .alignment-clone-failed-retry': 'onAlignmentCloneFailedRetry',
        'click .alignment-clone-failed-cancel': 'onDuplicateOrImportFailedCancel',
      }

      this.prototype.messages = shimGetterShorthand(
        {},
        {
          confirm() {
            return I18n.t('Are you sure you want to delete this assignment?')
          },
          ag_move_label() {
            return I18n.beforeLabel(I18n.t('Assignment Group'))
          },
        }
      )
    }

    className() {
      return `assignment${this.canMove() ? '' : ' sort-disabled'}`
    }

    initialize() {
      super.initialize(...arguments)
      this.initializeChildViews()
      // we need the following line in order to access this view later
      this.model.assignmentView = this

      this.model.on('change:hidden', () => {
        this.toggleHidden()
      })
      this.model.set('disabledForModeration', !this.canEdit())

      if (this.canManage()) {
        this.model.on('change:published', this.updatePublishState)

        // re-render for attributes we are showing
        const attrs = [
          'name',
          'points_possible',
          'due_at',
          'lock_at',
          'unlock_at',
          'modules',
          'published',
          'workflow_state',
          'assessment_requests',
        ]
        const observe = attrs.map(attr => `change:${attr}`).join(' ')
        this.model.on(observe, this.render)
      }
      this.model.on('change:submission', () => {
        this.updateScore()
      })

      return this.model.pollUntilFinishedLoading()
    }

    initializeChildViews() {
      this.publishIconView = false
      this.lockIconView = false
      this.sisButtonView = false
      this.editAssignmentView = false
      this.dateAvailableColumnView = false

      if (this.canManage()) {
        this.publishIconView = new PublishIconView({
          model: this.model,
          title: this.model.get('name'),
        })
        this.lockIconView = new LockIconView({
          model: this.model,
          unlockedText: I18n.t('%{name} is unlocked. Click to lock.', {
            name: this.model.get('name'),
          }),
          lockedText: I18n.t('%{name} is locked. Click to unlock', {name: this.model.get('name')}),
          course_id: this.model.get('course_id'),
          content_id: this.model.get('id'),
          content_type: 'assignment',
        })
        this.editAssignmentView = new CreateAssignmentView({model: this.model})
      }

      this.initializeSisButton()

      this.dateDueColumnView = new DateDueColumnView({model: this.model})
      return (this.dateAvailableColumnView = new DateAvailableColumnView({model: this.model}))
    }

    initializeSisButton() {
      if (
        this.canManage() &&
        this.isGraded() &&
        this.model.postToSISEnabled() &&
        this.model.published()
      ) {
        return (this.sisButtonView = new SisButtonView({
          model: this.model,
          sisName: this.model.postToSISName(),
          dueDateRequired: this.model.dueDateRequiredForAccount(),
          maxNameLengthRequired: this.model.maxNameLengthRequiredForAccount(),
        }))
      } else if (this.sisButtonView) {
        this.sisButtonView.remove()
      }
    }

    // Public: Called when move menu item is selected
    //
    // Returns nothing.
    onMove() {
      this.moveTrayProps = {
        title: I18n.t('Move Assignment'),
        items: [
          {
            id: this.model.get('id'),
            title: this.model.get('name'),
          },
        ],
        moveOptions: {
          groupsLabel: this.messages.ag_move_label,
          groups: MoveItem.backbone.collectionToGroups(
            this.model.collection.view != null
              ? this.model.collection.view.parentCollection
              : undefined,
            col => col.get('assignments')
          ),
        },
        onMoveSuccess: res => {
          const keys = {
            model: 'assignments',
            parent: 'assignment_group_id',
          }
          return MoveItem.backbone.reorderAcrossCollections(
            res.data.order,
            res.groupId,
            this.model,
            keys
          )
        },
        focusOnExit: () => {
          return document.querySelector(`#assignment_${this.model.id} a[id*=manage_link]`)
        },
        formatSaveUrl({groupId}) {
          return `${ENV.URLS.assignment_sort_base_url}/${groupId}/reorder`
        },
      }

      return MoveItem.renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
    }

    updatePublishState() {
      this.view.$el
        .find('.speed-grader-link-container')
        ?.toggleClass('hidden', !this.view.model.get('published'))
      return this.view.$el
        .find('.ig-row')
        .toggleClass('ig-published', this.view.model.get('published'))
    }

    // call remove on children so that they can clean up old dialogs.
    render() {
      this.toggleHidden(this.model, this.model.get('hidden'))
      if (this.publishIconView) {
        this.publishIconView.remove()
      }
      if (this.lockIconView) {
        this.lockIconView.remove()
      }
      if (this.editAssignmentView) {
        this.editAssignmentView.remove()
      }
      if (this.dateDueColumnView) {
        this.dateDueColumnView.remove()
      }
      if (this.dateAvailableColumnView) {
        this.dateAvailableColumnView.remove()
      }

      super.render(...arguments)
      this.initializeSisButton()
      $('.ig-details').addClass('rendered')
      // reset the model's view property; it got overwritten by child views
      if (this.model) {
        return (this.model.view = this)
      }
    }

    afterRender() {
      this.createModuleToolTip()

      if (this.editAssignmentView) {
        this.editAssignmentView.hide()
        if (this.canEdit()) {
          this.editAssignmentView.setTrigger(this.$editAssignmentButton)
        }
      }

      const {attributes = {}} = this.model
      const {assessment_requests: assessmentRequests} = attributes
      if (assessmentRequests && assessmentRequests.length) {
        const peerReviewElem =
          this.$el.find(`#assignment_student_peer_review_${this.model.id}`) ?? []
        const mountPoint = peerReviewElem[0]
        if (mountPoint) {
          ReactDOM.render(
            React.createElement(StudentViewPeerReviews, {
              assignment: attributes,
            }),
            mountPoint
          )
        }
      }

      if (this.canReadGrades()) {
        return this.updateScore()
      }
    }

    toggleHidden(model, hidden) {
      this.$el.toggleClass('hidden', hidden)
      return this.$el.toggleClass('search_show', !hidden)
    }

    stopMoveIfProtected(e) {
      if (!this.canMove()) {
        return e.stopPropagation()
      }
    }

    createModuleToolTip() {
      const link = this.$el.find('.tooltip_link')
      if (link.length > 0) {
        return link.tooltip({
          position: {
            my: 'center bottom',
            at: 'center top-10',
            collision: 'fit fit',
          },
          tooltipClass: 'center bottom vertical',
          content() {
            return $(link.data('tooltipSelector')).html()
          },
        })
      }
    }

    toJSON() {
      let modules
      let data = this.model.toView()
      data.canManage = this.canManage()
      if (!data.canManage) {
        data = this._setJSONForGrade(data)
      }
      data.courseId = this.model.get('course_id')
      data.differentiatedModulesFlag = ENV.FEATURES?.differentiated_modules
      data.showSpeedGraderLinkFlag = ENV.FLAGS?.show_additional_speed_grader_link
      data.showSpeedGraderLink = ENV.SHOW_SPEED_GRADER_LINK
      // publishing and unpublishing the underlying model does not rerender this view.
      // this sets initial value, then it keeps up with class toggling behavior on updatePublishState()
      data.initialUnpublishedState = !this.model.get('published')
      data.canEdit = this.canEdit()
      data.canShowBuildLink = this.canShowBuildLink()
      data.canMove = this.canMove()
      data.canDelete = this.canDelete()
      data.canDuplicate = this.canDuplicate()
      data.is_locked = this.model.isRestrictedByMasterCourse()
      data.showAvailability =
        !(this.model.inPacedCourse() && this.canManage()) &&
        (this.model.multipleDueDates() || !this.model.defaultDates().available())
      data.showDueDate =
        !(this.model.inPacedCourse() && this.canManage()) &&
        (this.model.multipleDueDates() || this.model.singleSectionDueDate())

      data.cyoe = CyoeHelper.getItemData(
        data.id,
        this.isGraded() && (!this.model.isQuiz() || data.is_quiz_assignment)
      )
      data.return_to = encodeURIComponent(window.location.pathname)

      data.quizzesRespondusEnabled = this.model.quizzesRespondusEnabled()

      data.DIRECT_SHARE_ENABLED = !!ENV.DIRECT_SHARE_ENABLED
      data.canOpenManageOptions = this.canOpenManageOptions()

      data.item_assignment_type = data.is_quiz_assignment
        ? 'quiz'
        : data.isQuizLTIAssignment
        ? 'lti-quiz'
        : 'assignment'

      if (data.canManage) {
        data.spanWidth = 'span3'
        data.alignTextClass = ''
      } else {
        data.spanWidth = 'span4'
        data.alignTextClass = 'align-right'
      }

      if (this.model.isQuiz()) {
        data.menu_tools = ENV.quiz_menu_tools || []
        data.menu_tools.forEach(tool => {
          return (tool.url = tool.base_url + `&quizzes[]=${this.model.get('quiz_id')}`)
        })
      } else if (this.model.isDiscussionTopic()) {
        data.menu_tools = ENV.discussion_topic_menu_tools || []
        data.menu_tools.forEach(tool => {
          return (tool.url =
            tool.base_url +
            `&discussion_topics[]=${__guard__(this.model.get('discussion_topic'), x => x.id)}`)
        })
      } else {
        data.menu_tools = ENV.assignment_menu_tools || []
        data.menu_tools.forEach(tool => {
          return (tool.url = tool.base_url + `&assignments[]=${this.model.get('id')}`)
        })
      }

      if ((modules = this.model.get('modules'))) {
        const moduleName = modules[0]
        const has_modules = modules.length > 0
        const joinedNames = modules.join(',')
        return Object.assign(data, {
          modules,
          module_count: modules.length,
          module_name: moduleName,
          has_modules,
          joined_names: joinedNames,
        })
      } else {
        return data
      }
    }

    addAssignmentToList(response) {
      if (!response) {
        return
      }
      const assignment = new Assignment(response)
      // Force the positions to match what is in the db.
      this.model.collection.forEach(a => {
        return a.set('position', response.new_positions[a.get('id')])
      })
      if (this.hasIndividualPermissions()) {
        ENV.PERMISSIONS.by_assignment_id[assignment.id] =
          ENV.PERMISSIONS.by_assignment_id[assignment.originalAssignmentID()]
      }
      this.model.collection.add(assignment)
      return this.focusOnAssignment(response)
    }

    addMigratedQuizToList(response) {
      if (!response) {
        return
      }
      const quizzes = response.migrated_assignment
      if (quizzes) {
        return this.addAssignmentToList(quizzes[0])
      }
    }

    onDuplicate(e) {
      if (!this.canDuplicate()) {
        return
      }
      e.preventDefault()
      return this.model.duplicate(this.addAssignmentToList)
    }

    onDuplicateFailedRetry(e) {
      e.preventDefault()
      const $button = $(e.target)
      $button.prop('disabled', true)
      return this.model
        .duplicate_failed(response => {
          this.addAssignmentToList(response)
          return this.delete({silent: true})
        })
        .always(() => $button.prop('disabled', false))
    }

    onAlignmentCloneFailedRetry(e) {
      e.preventDefault()
      const $button = $(e.target)
      $button.prop('disabled', true)
      return this.model
        .alignment_clone_failed(response => {
          return this.updateAssignmentCollectionItem(response)
        })
        .always(() => $button.prop('disabled', false))
    }

    updateAssignmentCollectionItem(response) {
      if (!response) {
        return
      }
      this.model.collection.forEach(a => {
        if (a.get('id') === response.id) {
          a.set('workflow_state', response.workflow_state)
          a.set('duplication_started_at', response.duplication_started_at)
          a.set('updated_at', response.updated_at)
        }
      })
    }

    onMigrateFailedRetry(e) {
      e.preventDefault()
      const $button = $(e.target)
      $button.prop('disabled', true)
      return this.model
        .retry_migration(response => {
          this.addMigratedQuizToList(response)
          return this.delete({silent: true})
        })
        .always(() => $button.prop('disabled', false))
    }

    onDuplicateOrImportFailedCancel(e) {
      e.preventDefault()
      return this.delete({silent: true})
    }

    renderItemAssignToTray(open, returnFocusTo, itemProps) {
      ReactDOM.render(
        <ItemAssignToTray
          open={open}
          onClose={() => {
            ReactDOM.unmountComponentAtNode(document.getElementById('assign-to-mount-point'))
          }}
          onDismiss={() => {
            this.renderItemAssignToTray(false, returnFocusTo, itemProps)
            returnFocusTo.focus()
          }}
          itemType="assignment"
          locale={ENV.LOCALE || 'en'}
          timezone={ENV.TIMEZONE || 'UTC'}
          {...itemProps}
        />,
        document.getElementById('assign-to-mount-point')
      )
    }

    onAssign(e) {
      e.preventDefault()
      const returnFocusTo = $(e.target).closest('ul').prev('.al-trigger')

      const courseId = e.target.getAttribute('data-assignment-context-id')
      const itemName = e.target.getAttribute('data-assignment-name')
      const itemContentId = e.target.getAttribute('data-assignment-id')
      const pointsPossible = this.model.get('points_possible')
      const iconType = e.target.getAttribute('data-assignment-type')
      this.renderItemAssignToTray(true, returnFocusTo, {
        courseId,
        itemName,
        itemContentId,
        pointsPossible,
        iconType,
      })
    }

    onDelete(e) {
      e.preventDefault()
      if (!this.canDelete()) {
        return
      }
      // eslint-disable-next-line no-alert
      if (!window.confirm(this.messages.confirm)) {
        return this.$el.find('a[id*=manage_link]').focus()
      }
      if (this.previousAssignmentInGroup() != null) {
        this.focusOnAssignment(this.previousAssignmentInGroup())
        return this.delete()
      } else {
        const id = this.model.attributes.assignment_group_id
        this.delete()
        return this.focusOnGroupByID(id)
      }
    }

    onSendAssignmentTo(e) {
      e.preventDefault()
      const renderModal = open => {
        const mountPoint = document.getElementById('send-to-mount-point')
        if (!mountPoint) {
          return
        }
        ReactDOM.render(
          React.createElement(DirectShareUserModal, {
            open,
            courseId: ENV.COURSE_ID || ENV.COURSE.id,
            contentShare: {content_type: 'assignment', content_id: this.model.id},
            shouldReturnFocus: false,
            onDismiss: dismissModal,
          }),
          mountPoint
        )
      }

      const dismissModal = () => {
        renderModal(false)
        // delay necessary because something else is messing with our focus, even with shouldReturnFocus: false
        return setTimeout(() => this.$settingsButton.focus(), 100)
      }

      return renderModal(true)
    }

    onCopyAssignmentTo(e) {
      e.preventDefault()
      const renderTray = open => {
        const mountPoint = document.getElementById('copy-to-mount-point')
        if (!mountPoint) {
          return
        }
        ReactDOM.render(
          React.createElement(DirectShareCourseTray, {
            open,
            sourceCourseId: ENV.COURSE_ID || ENV.COURSE.id,
            contentSelection: {assignments: [this.model.id]},
            shouldReturnFocus: false,
            onDismiss: dismissTray,
          }),
          mountPoint
        )
      }

      const dismissTray = () => {
        renderTray(false)
        // delay necessary because something else is messing with our focus, even with shouldReturnFocus: false
        return setTimeout(() => this.$settingsButton.focus(), 100)
      }

      return renderTray(true)
    }

    onUnlockAssignment(e) {
      return e.preventDefault()
    }

    onLockAssignment(e) {
      return e.preventDefault()
    }

    delete(opts) {
      if (opts == null) {
        opts = {silent: false}
      }
      const callbacks = {}
      if (!opts.silent) {
        callbacks.success = () => $.screenReaderFlashMessage(I18n.t('Assignment was deleted'))
      }
      this.model.destroy(callbacks)
      return this.$el.remove()
    }

    hasIndividualPermissions() {
      return ENV.PERMISSIONS.by_assignment_id != null
    }

    canDelete() {
      const modelResult =
        (this.userIsAdmin || this.model.canDelete()) && !this.model.isRestrictedByMasterCourse()
      const userResult = this.hasIndividualPermissions()
        ? !!(ENV.PERMISSIONS.by_assignment_id[this.model.id] != null
            ? ENV.PERMISSIONS.by_assignment_id[this.model.id].delete
            : undefined)
        : ENV.PERMISSIONS.manage_assignments_delete
      return modelResult && userResult
    }

    canDuplicate() {
      return (this.userIsAdmin || this.canAdd()) && this.model.canDuplicate()
    }

    canMove() {
      return this.userIsAdmin || (this.canManage() && this.model.canMove())
    }

    canEdit() {
      if (!this.hasIndividualPermissions()) {
        return this.userIsAdmin || this.canManage()
      }

      return (
        this.userIsAdmin ||
        (this.canManage() &&
          !!(ENV.PERMISSIONS.by_assignment_id[this.model.id] != null
            ? ENV.PERMISSIONS.by_assignment_id[this.model.id].update
            : undefined))
      )
    }

    canAdd() {
      return ENV.PERMISSIONS.manage_assignments_add
    }

    canManage() {
      return ENV.PERMISSIONS.manage
    }

    canShowBuildLink() {
      return !!(ENV.FLAGS && this.model.isQuizLTIAssignment())
    }

    canOpenManageOptions() {
      return this.canManage() || this.canAdd() || this.canDelete() || ENV.DIRECT_SHARE_ENABLED
    }

    isGraded() {
      const submission_types = this.model.get('submission_types')
      return (
        submission_types &&
        !submission_types.includes('not_graded') &&
        !submission_types.includes('wiki_page')
      )
    }

    gradeStrings(grade) {
      const pass_fail_map = {
        incomplete: I18n.t('incomplete', 'Incomplete'),
        complete: I18n.t('complete', 'Complete'),
      }

      grade = pass_fail_map[grade] || grade

      return {
        percent: {
          nonscreenreader: I18n.t('grade_percent', '%{grade}%', {grade}),
          screenreader: I18n.t('grade_percent_screenreader', 'Grade: %{grade}%', {grade}),
        },
        pass_fail: {
          nonscreenreader: `${grade}`,
          screenreader: I18n.t('grade_pass_fail_screenreader', 'Grade: %{grade}', {grade}),
        },
        letter_grade: {
          nonscreenreader: `${grade}`,
          screenreader: I18n.t('grade_letter_grade_screenreader', 'Grade: %{grade}', {grade}),
        },
        gpa_scale: {
          nonscreenreader: `${grade}`,
          screenreader: I18n.t('grade_gpa_scale_screenreader', 'Grade: %{grade}', {grade}),
        },
      }
    }

    _setJSONForGrade(json) {
      let submission
      let {gradingType} = json
      const {pointsPossible} = json

      if (typeof pointsPossible === 'number' && !Number.isNaN(pointsPossible)) {
        json.pointsPossible = round(pointsPossible, round.DEFAULT)
      }

      if ((submission = this.model.get('submission'))) {
        const submissionJSON = submission.present ? submission.present() : submission.toJSON()
        const score = submission.get('score')
        if (typeof score === 'number' && !Number.isNaN(score)) {
          submissionJSON.score = round(score, round.DEFAULT)
        }
        json.submission = submissionJSON
        let grade = submission.get('grade')
        // it should skip this logic if it is a pass/fail assignment or if the 
        // grading type is letter grade and the grade represents the letter grade
        // and the score represents the numerical grade
        // this is usually how the grade is stored when the assignment is letter grade
        // but this does not happen when points possible is 0, then the grade is not saved as a letter grade
        // and needs to be converted
        if (json.restrict_quantitative_data && gradingType !== 'pass_fail' && !(gradingType === 'letter_grade' && String(grade) !== String(score))) {
          gradingType = 'letter_grade'
          if (json.pointsPossible === 0 && json.submission.score < 0) {
            grade = json.submission.score
          } else if (json.pointsPossible === 0 && json.submission.score > 0) {
            grade = scoreToGrade(100, ENV.grading_scheme)
          } else if (json.pointsPossible === 0 && json.submission.score === 0) {
            grade = 'complete'
          } else {
            grade = scoreToGrade(
              scoreToPercentage(json.submission.score, json.pointsPossible),
              ENV.grading_scheme
            )
          }
        }

        if (grade !== null) {
          const gradeString = this.gradeStrings(grade)[gradingType]
          json.submission.gradeDisplay =
            gradeString != null ? gradeString.nonscreenreader : undefined
          json.submission.gradeDisplayForScreenreader =
            gradeString != null ? gradeString.screenreader : undefined
        }
      }

      if (json.submission != null) {
        json.submission.gradingType = gradingType
        json.submission.restrict_quantitative_data = json.restrict_quantitative_data // This is so this variable is accessible on the {{#with submission}} block.
        json.submission.pointsPossible = json.pointsPossible
      }

      if (json.gradingType === 'not_graded') {
        json.hideGrade = true
      }
      return json
    }

    updateScore() {
      let json = this.model.toView()
      if (!this.canManage()) {
        json = this._setJSONForGrade(json)
      }
      return this.$('.js-score').html(scoreTemplate(json))
    }

    canReadGrades() {
      return ENV.PERMISSIONS.read_grades
    }

    goToNextItem() {
      if (this.nextAssignmentInGroup() != null) {
        return this.focusOnAssignment(this.nextAssignmentInGroup())
      } else if (this.nextVisibleGroup() != null) {
        return this.focusOnGroup(this.nextVisibleGroup())
      } else {
        return this.focusOnFirstGroup()
      }
    }

    goToPrevItem() {
      if (this.previousAssignmentInGroup() != null) {
        return this.focusOnAssignment(this.previousAssignmentInGroup())
      } else {
        return this.focusOnGroupByID(this.model.attributes.assignment_group_id)
      }
    }

    editItem() {
      return this.$(`#assignment_${this.model.id}_settings_edit_item`).click()
    }

    deleteItem() {
      return this.$(`#assignment_${this.model.id}_settings_delete_item`).click()
    }

    addItem() {
      const group_id = this.model.attributes.assignment_group_id
      return $('.add_assignment', `#assignment_group_${group_id}`).click()
    }

    showAssignment() {
      return $('.ig-title', `#assignment_${this.model.id}`)[0].click()
    }

    assignmentGroupView() {
      return this.model.collection.view
    }

    visibleAssignments() {
      return this.assignmentGroupView().visibleAssignments()
    }

    nextVisibleGroup() {
      return this.assignmentGroupView().nextGroup()
    }

    nextAssignmentInGroup() {
      const current_assignment_index = this.visibleAssignments().indexOf(this.model)
      return this.visibleAssignments()[current_assignment_index + 1]
    }

    previousAssignmentInGroup() {
      const current_assignment_index = this.visibleAssignments().indexOf(this.model)
      return this.visibleAssignments()[current_assignment_index - 1]
    }

    focusOnAssignment(assignment) {
      return $(`#assignment_${assignment.id}`).attr('tabindex', -1).focus()
    }

    focusOnGroup(group) {
      return $(`#assignment_group_${group.attributes.id}`).attr('tabindex', -1).focus()
    }

    focusOnGroupByID(group_id) {
      return $(`#assignment_group_${group_id}`).attr('tabindex', -1).focus()
    }

    focusOnFirstGroup() {
      return $('.assignment_group').filter(':visible').first().attr('tabindex', -1).focus()
    }
  }
  AssignmentListItemView.initClass()
  return AssignmentListItemView
})()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
