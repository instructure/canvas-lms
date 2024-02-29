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
//

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, pick, keys, filter, find, uniqueId, each, includes, every, isEmpty} from 'lodash'
import {Collection} from '@canvas/backbone'
import DialogBaseView from '@canvas/dialog-base-view'
import template from '../../jst/MessageFormDialog.handlebars'
import preventDefault from '@canvas/util/preventDefault'
import composeTitleBarTemplate from '../../jst/composeTitleBar.handlebars'
import composeButtonBarTemplate from '../../jst/composeButtonBar.handlebars'
import addAttachmentTemplate from '../../jst/addAttachment.handlebars'
import Message from '../models/Message'
import AutocompleteView from './AutocompleteView'
import CourseSelectionView from './CourseSelectionView'
import ContextMessagesView from './ContextMessagesView'
import 'jquery.elastic'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('conversation_dialog')

// #
// reusable message composition dialog
export default class MessageFormDialog extends DialogBaseView {
  static initClass() {
    this.prototype.template = template

    this.prototype.els = {
      '.message_course': '$messageCourse',
      '.message_course_ro': '$messageCourseRO',
      'input[name=context_code]': '$contextCode',
      '.message_subject': '$messageSubject',
      '.message_subject_ro': '$messageSubjectRO',
      '.context_messages': '$contextMessages',
      '.media_comment': '$mediaComment',
      'input[name=media_comment_id]': '$mediaCommentId',
      'input[name=media_comment_type]': '$mediaCommentType',
      '#bulk_message': '$bulkMessage',
      '.ac': '$recipients',
      '.attachment_list': '$attachments',
      '.attachments-pane': '$attachmentsPane',
      '.message-body': '$messageBody',
      '.conversation_body': '$conversationBody',
      '.compose_form': '$form',
      '.user_note': '$userNote',
      '.user_note_info': '$userNoteInfo',
    }

    this.prototype.messages = {flashSuccess: I18n.t('message_sent', 'Message sent!')}

    this.prototype.defaultCourse = null

    this.prototype.imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg']
  }

  dialogOptions() {
    const smallTablet = window.matchMedia('(min-width: 550px)').matches
    const tablet = window.matchMedia('(min-width: 700px)').matches

    const responsiveMinWidth = smallTablet ? 550 : 320
    const responsiveWidth = tablet ? 700 : smallTablet ? 550 : 320
    const responsiveHeight = smallTablet ? 550 : 'auto'

    return {
      id: 'compose-new-message',
      autoOpen: false,
      minWidth: responsiveMinWidth,
      width: responsiveWidth,
      minHeight: 500,
      height: responsiveHeight,
      resizable: true,
      title: I18n.t('Compose Message'),
      // Event handler for catching when the dialog is closed.
      // Overridding @close() or @cancel() doesn't work alone since
      // hitting ESC doesn't trigger either of those events.
      close: () => this.afterClose(),
      resize: () => {
        this.resizeBody()
        return this._limitContentSize()
      },
      buttons: [
        {
          text: I18n.t('#buttons.cancel', 'Cancel'),
          click: this.cancel,
        },
        {
          text: I18n.t('#buttons.send', 'Send'),
          class: 'btn-primary send-message',
          'data-track-category': 'Compose Message',
          'data-track-action': 'Edit',
          'data-track-label': 'Send',
          'data-text-while-loading': I18n.t('Sending...'),
          click: e => this.sendMessage(e),
        },
      ],
      modal: true,
      zIndex: 1000,
    }
  }

  show(model, options) {
    if ((this.model = model)) {
      this.message =
        (options != null ? options.message : undefined) || this.model.messageCollection.at(0)
    }
    this.to = options != null ? options.to : undefined
    if (options.trigger) {
      this.returnFocusTo = options.trigger
    }
    if (options.remoteLaunch) {
      this.launchParams = pick(options, 'context', 'user')
    }

    this.render()
    this.appendAddAttachmentTemplate()

    super.show(...arguments)
    this.initializeForm()
    return this.resizeBody()
  }

  // this method handles a layout bug with jqueryUI that occurs when you
  // attempt to resize the modal beyond the viewport.
  _limitContentSize() {
    if (this.$el.width() > this.$fullDialog.width()) {
      return this.$el.width('100%')
    }
  }

  // #
  // detach events that were dynamically added when the dialog is closed.
  afterClose() {
    this.$fullDialog.off('click', '.message-body')
    this.$fullDialog.off('click', '.attach-file')
    this.$fullDialog.off('click', '.attachment .remove_link')
    this.$fullDialog.off('keydown', '.attachment')
    this.$fullDialog.off('click', '.attachment')
    this.$fullDialog.off('dblclick', '.attachment')
    this.$fullDialog.off('change', '.file_input')
    this.$fullDialog.off('click', '.attach-media')
    this.$fullDialog.off('click', '.media-comment .remove_link')

    this.launchParams = null

    this.trigger('close')
    if (this.returnFocusTo) {
      $(this.returnFocusTo).focus()
      return delete this.returnFocusTo
    }
  }

  sendMessage(e) {
    e.preventDefault()
    e.stopPropagation()
    this.removeEmptyAttachments()
    return this.$form.submit()
  }

  initialize() {
    super.initialize(...arguments)
    this.$fullDialog = this.$el.closest('.ui-dialog')
    // Customize titlebar
    const $titlebar = this.$fullDialog.find('.ui-dialog-titlebar')
    const $closeBtn = $titlebar.find('.ui-dialog-titlebar-close')
    $closeBtn.html(composeTitleBarTemplate())

    // add custom class to dialog container for
    this.$fullDialog.addClass('compose-message-dialog')

    // add attachment and media buttons to bottom bar
    this.$fullDialog.find('.ui-dialog-buttonpane').prepend(composeButtonBarTemplate({}))

    return (this.$addMediaComment = this.$fullDialog.find('.attach-media'))
  }

  prepareTextarea($scope) {
    const $textArea = $scope.find('textarea')
    return $textArea.elastic()
  }

  onCourse(course) {
    this.recipientView.setContext(course, true)
    if (course != null ? course.id : undefined) {
      this.$contextCode.val(course.id)
      this.recipientView.disable(false)
    } else {
      this.$contextCode.val('')
    }
    return this.$messageCourseRO.text(course ? course.name : I18n.t('no_course', 'No course'))
  }

  setDefaultCourse(course) {
    return (this.defaultCourse = course)
  }

  initializeForm() {
    let messages, tokens
    this.prepareTextarea(this.$el)
    this.recipientView = new AutocompleteView({
      el: this.$recipients,
      disabled: this.model != null ? this.model.get('private') : undefined,
    }).render()
    this.recipientView.on('changeToken', this.recipientIdsChanged, this)
    this.recipientView.on('recipientTotalChange', this.recipientTotalChanged, this)

    if (!ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT) {
      this.$messageCourse.attr('aria-required', true)
      this.recipientView.disable(true)
    }

    this.$messageCourse.prop('disabled', !!this.model)
    this.courseView = new CourseSelectionView({
      el: this.$messageCourse,
      courses: this.options.courses,
      defaultOption: I18n.t('select_course', 'Select course'),
      messageableOnly: true,
      excludeConcluded: true,
    })
    if (this.model) {
      if (this.model.get('context_code')) {
        this.onCourse({id: this.model.get('context_code'), name: this.model.get('context_name')})
      } else {
        this.courseView.on('course', c => this.onCourse(c))
        this.courseView.setValue(`course_${keys(this.model.get('audience_contexts').courses)[0]}`)
      }
      this.recipientView.disable(false)
    } else if (this.launchParams) {
      this.courseView.on('course', c => this.onCourse(c))
      if (this.launchParams.context) {
        this.courseView.setValue(this.launchParams.context)
      }
      this.recipientView.disable(false)
    } else {
      this.courseView.on('course', c => this.onCourse(c))
      this.courseView.setValue(this.defaultCourse)
    }
    if (this.model) {
      this.courseView.$picker.css('display', 'none')
    } else {
      this.$messageCourseRO.css('display', 'none')
    }

    if ((this.tokenInput = this.$el.find('.recipients').data('token_input'))) {
      // since it doesn't infer percentage widths, just whatever the current pixels are
      this.tokenInput.$fakeInput.css('width', '100%')
      if (this.options.user_id) {
        const query = {
          user_id: this.options.user_id,
          from_conversation_id: this.options.from_conversation_id,
        }
        $.ajaxJSON(this.tokenInput.selector.url, 'GET', query, data => {
          if (data.length) {
            return this.tokenInput.addToken({
              value: data[0].id,
              text: data[0].name,
              data: data[0],
            })
          }
        })
      }
    }

    if (this.to && this.to !== 'forward' && this.message) {
      tokens = []
      tokens.push(this.message.get('author'))
      if (this.to === 'replyAll' || ENV.current_user_id === this.message.get('author').id) {
        tokens = tokens.concat(this.message.get('participants'))
        if (tokens.length > 1) {
          tokens = filter(tokens, t => t.id !== ENV.current_user_id)
        }
      }
      this.recipientView.setTokens(tokens)
    }

    if (this.launchParams) {
      this.recipientView.setTokens([this.launchParams.user])
    }

    if (this.model) {
      this.$messageSubject.css('display', 'none')
      this.$messageSubject.prop('disabled', true)
    } else {
      this.$messageSubjectRO.css('display', 'none')
    }
    if (this.model != null ? this.model.get('subject') : undefined) {
      this.$messageSubject.val(this.model.get('subject'))
      this.$messageSubjectRO.text(this.model.get('subject'))
    }

    if ((messages = this.model != null ? this.model.messageCollection : undefined)) {
      // include only messages which
      //   1) are older than @message
      //   2) have as participants a superset of the participants of @message
      const date = new Date(this.message.get('created_at'))
      const participants = this.message.get('participating_user_ids')
      const includedMessages = new Collection(
        messages.filter(
          m =>
            new Date(m.get('created_at')) <= date &&
            !find(participants, p => !includes(m.get('participating_user_ids'), p))
        )
      )
      const contextView = new ContextMessagesView({
        el: this.$contextMessages,
        collection: includedMessages,
      })
      contextView.render()
    }

    this.$fullDialog.on('click', '.message-body', e => this.handleBodyClick(e))
    this.$fullDialog.on('click', '.attach-file', () => this.addAttachment())
    this.$fullDialog.on(
      'click',
      '.attachment .remove_link',
      preventDefault(e => this.removeAttachment($(e.currentTarget)))
    )
    this.$fullDialog.on('keydown', '.attachment', e => this.handleAttachmentKeyDown(e))
    this.$fullDialog.on('click', '.attachment', e => this.handleAttachmentClick(e))
    this.$fullDialog.on('dblclick', '.attachment', e => this.handleAttachmentDblClick(e))
    this.$fullDialog.on('change', '.file_input', e => this.handleAttachment(e))

    this.$fullDialog.on(
      'click',
      '.attach-media',
      preventDefault(() => this.addMediaComment())
    )
    this.$fullDialog.on(
      'click',
      '.media_comment .remove_link',
      preventDefault(e => this.removeMediaComment($(e.currentTarget)))
    )
    this.$addMediaComment[INST.kalturaSettings ? 'show' : 'hide']()

    return this.$form.formSubmit({
      fileUpload: () => this.$fullDialog.find('.attachment_list').length > 0,
      files: () => this.$fullDialog.find('.file_input'),
      preparedFileUpload: true,
      context_code: `user_${ENV.current_user_id}`,
      folder_id: this.options.folderId,
      intent: 'message',
      formDataTarget: 'url',
      required: ['body'],
      property_validations: {
        token_capture: () => {
          if (this.recipientView && !this.recipientView.tokens.length) {
            return I18n.t('Invalid recipient name.')
          }
        },
      },
      handle_files(attachments, data) {
        data.attachment_ids = attachments.map(a => a.id)
        return data
      },
      processData: formData => {
        if (!formData.context_code) {
          formData.context_code =
            (this.launchParams != null ? this.launchParams.context : undefined) ||
            this.options.account_context_code
        }
        return formData
      },
      onSubmit: (request, _submitData) => {
        this.request = request
        const dfd = $.Deferred()
        $(this.el)
          .parent()
          .disableWhileLoading(dfd, {buttons: ['[data-text-while-loading] .ui-button-text']})
        this.trigger('submitting', dfd)
        // update conversation when message confirmed sent
        // TODO: construct the new message object and pass it to the MessageDetailView which will need to create a MessageItemView for it
        // store @to for the closure in case there are multiple outstanding send requests
        const localTo = this.to
        this.to = null
        $.when(this.request).then(response => {
          dfd.resolve()
          $.flashMessage(this.messages.flashSuccess)
          if (localTo) {
            let message = response.messages[0]
            message.author = {
              name: ENV.current_user.display_name,
              avatar_url: ENV.current_user.avatar_image_url,
            }
            message = new Message(response, {parse: true})
            this.trigger('addMessage', message.toJSON().conversation.messages[0], response)
          } else {
            this.trigger('newConversations', response)
          }
          return this.close()
        }) // close after DOM has been updated, so focus is properly restored
        // also don't close the dialog on failure, so the user's typed message isn't lost
        return $.when(this.request).fail(() => dfd.reject())
      },
    })
  }

  recipientIdsChanged(recipientIds) {
    if (isEmpty(recipientIds) || includes(recipientIds, /(teachers|tas|observers)$/)) {
      return this.toggleUserNote(false)
    } else {
      const canAddNotes = map(this.recipientView.tokenModels(), tokenModel =>
        this.canAddNotesFor(tokenModel)
      )
      return this.toggleUserNote(every(canAddNotes))
    }
  }

  recipientTotalChanged(lockBulkMessage) {
    if (lockBulkMessage && !this.bulkMessageLocked) {
      this.oldBulkMessageVal = this.$bulkMessage.prop('checked')
      this.$bulkMessage.prop('checked', true)
      this.$bulkMessage.prop('disabled', true)
      return (this.bulkMessageLocked = true)
    } else if (!lockBulkMessage && this.bulkMessageLocked) {
      this.$bulkMessage.prop('checked', this.oldBulkMessageVal)
      this.$bulkMessage.prop('disabled', false)
      return (this.bulkMessageLocked = false)
    }
  }

  canAddNotesFor(user) {
    if (!ENV.CONVERSATIONS.NOTES_ENABLED) {
      return false
    }
    if (user == null) {
      return false
    }
    if (user.id.match(/students$/) || user.id.match(/^group/)) return true
    const object = user.get('common_courses')
    for (const id in object) {
      const roles = object[id]
      if (
        roles.includes('StudentEnrollment') &&
        (ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_ACCOUNT ||
          ENV.CONVERSATIONS.CAN_ADD_NOTES_FOR_COURSES[id])
      )
        return true
    }
    return false
  }

  toggleUserNote(state) {
    this.$userNoteInfo.toggle(state)
    if (state === false) {
      this.$userNote.prop('checked', false)
    }
    return this.resizeBody()
  }

  resizeBody() {
    this.updateAttachmentOverflow()
    // Compute desired height of body
    return this.$messageBody.height(
      this.$el.offset().top +
        this.$el.height() -
        this.$messageBody.offset().top -
        this.$attachmentsPane.height()
    )
  }

  attachmentsShouldOverflow() {
    const $attachments = this.$attachments.children()
    return $attachments.length * $attachments.outerWidth() > this.$attachmentsPane.width()
  }

  addAttachment() {
    $('#file_input').attr('id', uniqueId('file_input'))
    this.appendAddAttachmentTemplate()
    this.updateAttachmentOverflow()

    return this.$fullDialog.find('.file_input:last').click()
  }

  appendAddAttachmentTemplate() {
    const $attachment = $(addAttachmentTemplate())
    this.$attachments.append($attachment)
    return $attachment.hide()
  }

  setAttachmentClip($attachment) {
    const $name = $attachment.find($('.attachment-name'))
    const $clip = $attachment.find($('.attachment-name-clip'))
    $clip.height($name.height())
    if ($name.height() < 35) {
      return $clip.addClass('hidden')
    }
  }

  handleBodyClick(e) {
    if (e.target === e.currentTarget) {
      return this.$conversationBody.focus()
    }
  }

  handleAttachmentClick(e) {
    // IE doesn't do this automatically
    $(e.currentTarget).focus()
  }

  handleAttachmentDblClick(e) {
    $(e.currentTarget).find('input').click()
  }

  handleAttachment(e) {
    const input = e.currentTarget
    const $attachment = $(input).closest('.attachment')
    this.updateAttachmentPane()
    if (!input.value) {
      $attachment.hide()
      return
    }
    this.focusAddAttachment()
    $attachment.slideDown('fast')
    const $icon = $attachment.find('.attachment-icon i')
    $icon.empty()
    const file = input.files[0]
    const {name} = file
    $attachment.find('.attachment-name').text(name)
    this.setAttachmentClip($attachment)

    // have the alert happen later so the focus change doesn't interrupt it
    const attachedFiles = this.$attachmentsPane.find('input:not([value=])')
    setTimeout(() => {
      $.screenReaderFlashMessageExclusive(
        I18n.t('File %{count} attached: %{name}', {count: attachedFiles.length, name})
      )
    }, 1000)

    const remove = $attachment.find('.remove_link')
    remove.attr('aria-label', `${remove.attr('title')}: ${name}`)
    const extension = name.split('.').pop().toLowerCase()
    if (this.imageTypes.includes(extension) && window.FileReader) {
      const picReader = new FileReader()
      picReader.addEventListener('load', e => {
        const picFile = e.target
        $icon.attr('class', '')
        return $icon.append($('<img />').attr('src', picFile.result))
      })
      picReader.readAsDataURL(file)
      return
    }
    let icon = 'paperclip'
    if (this.imageTypes.includes(extension)) {
      icon = 'image'
    } else if (extension === 'pdf') {
      icon = 'pdf'
    } else if (['doc', 'docx'].includes(extension)) {
      icon = 'ms-word'
    } else if (['xls', 'xlsx'].includes(extension)) {
      icon = 'ms-excel'
    }
    return $icon.attr('class', `icon-${icon}`)
  }

  handleAttachmentKeyDown(e) {
    if (e.keyCode === 37) {
      // left
      return this.focusPrevAttachment($(e.currentTarget))
    }
    if (e.keyCode === 39) {
      // right
      return this.focusNextAttachment($(e.currentTarget))
    }
    if ((e.keyCode === 13 || e.keyCode === 32) && !$(e.target).hasClass('remove_link')) {
      // enter, space
      this.handleAttachmentDblClick(e)
      return false
    }
    // delete, "d", enter, space
    if (e.keyCode !== 46 && e.keyCode !== 68 && e.keyCode !== 13 && e.keyCode !== 32) {
      return
    }
    this.removeAttachment(e.currentTarget)
    return false
  }

  removeEmptyAttachments() {
    each(this.$attachments.find('input:not([value])'), node => this.removeAttachment(node))
  }

  removeAttachment(node) {
    const $attachment = $(node).closest('.attachment')

    if (!this.focusNextAttachment($attachment)) {
      if (!this.focusPrevAttachment($attachment)) {
        this.focusAddAttachment()
      }
    }

    return $attachment.slideUp('fast', () => {
      $attachment.remove()
      return this.updateAttachmentPane()
    })
  }

  focusPrevAttachment($attachment) {
    const $newTarget = $attachment.prevAll(':visible').first()
    if (!$newTarget.length) {
      return false
    }
    return $newTarget.focus()
  }

  focusNextAttachment($attachment) {
    const $newTarget = $attachment.nextAll(':visible').first()
    if (!$newTarget.length) {
      return false
    }
    return $newTarget.focus()
  }

  focusAddAttachment() {
    return this.$fullDialog.find('.attach-file').focus()
  }

  addMediaComment() {
    return this.$mediaComment.mediaComment('create', 'any', (id, type) => {
      this.$mediaCommentId.val(id)
      this.$mediaCommentType.val(type)
      this.$mediaComment.show()
      return this.$addMediaComment.hide()
    })
  }

  removeMediaComment() {
    this.$mediaCommentId.val('')
    this.$mediaCommentType.val('')
    this.$mediaComment.hide()
    return this.$addMediaComment.show()
  }

  updateAttachmentOverflow() {
    return this.$attachmentsPane.toggleClass('overflowed', this.attachmentsShouldOverflow())
  }

  updateAttachmentPane() {
    this.$attachmentsPane[
      this.$attachmentsPane.find('input:not([value=])').length ? 'addClass' : 'removeClass'
    ]('has-items')
    return this.resizeBody()
  }
}
MessageFormDialog.initClass()
