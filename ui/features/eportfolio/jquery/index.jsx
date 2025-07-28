/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

// There's technically a security vulnerability here.  Since we let
// the user insert arbitrary content into their page, it's possible
// they'll create elements with the same class names we're using to
// find endpoints for updating settings and content.  However, since
// only the portfolio's owner can set this content, it seems like
// the worst they can do is override endpoint urls for eportfolio
// settings on their own personal eportfolio, they can't
// affect anyone else

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import PortfolioPortal from '../react/PortfolioPortal'
import ReactDOM from 'react-dom/client'
import userSettings from '@canvas/user-settings'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {fetchContent} from './eportfolio_section'
import sanitizeHtml from 'sanitize-html-with-tinymce'
import {raw} from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.tree' /* instTree */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, getFormData, formErrors, errorBox */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/rails-flash-notifications' /* $.screenReaderFlashMessageExclusive */
import '@canvas/jquery/jquery.instructure_misc_helpers' /* scrollSidebar */
import replaceTags from '@canvas/util/replaceTags'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/loading-image'
import '@canvas/util/templateData' /* fillTemplateData, getTemplateData */
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jqueryui/progressbar'
import 'jqueryui/sortable'
import CreatePortfolioForm from '../react/CreatePortfolioForm'
import {Portal} from '@instructure/ui-portal'
import PageNameContainer from '../react/PageNameContainer'

const I18n = createI18nScope('eportfolio')

// optimization so user isn't waiting on RCS to
// respond when they hit edit
RichContentEditor.preloadRemoteModule()

const ePortfolioValidations = {
  object_name: 'eportfolio',
  property_validations: {
    name(value) {
      if (!value || value.trim() === '') {
        return I18n.t('errors.name_required', 'Name is required')
      }
      if (value && value.length > 255) {
        return I18n.t('errors.name_too_long', 'Name is too long')
      }
    },
  },
}

function ePortfolioFormData() {
  let data = $('#edit_page_form').getFormData({
    object_name: 'eportfolio_entry',
    values: [
      'eportfolio_entry[name]',
      'eportfolio_entry[allow_comments]',
      'eportfolio_entry[show_comments]',
    ],
  })
  let idx = 0
  $('#edit_page_form .section').each(function () {
    const $section = $(this)
    const section_type = $section.getTemplateData({textValues: ['section_type']}).section_type
    if (section_type === 'rich_text' || section_type === 'html' || $section.hasClass('read_only')) {
      idx++
      const name = 'section_' + idx
      const sectionContent = fetchContent($section, section_type, name)
      data = $.extend(data, sectionContent)
    }
  })
  data.section_count = idx
  return data
}

function saveObject($obj, type) {
  const isSaving = $obj.data('event_pending')
  if (isSaving || $obj.length === 0) {
    return
  }
  let method = 'PUT'
  let url = $obj.find('.rename_' + type + '_url').attr('href')
  if ($obj.attr('id') === type + '_new') {
    method = 'POST'
    url = $('.add_' + type + '_url').attr('href')
  }
  const $objs = $obj.parents('ul').find('.' + type + ':not(.unsaved)')
  let newName = $obj.find('#' + type + '_name').val()
  $objs.each(function () {
    if (this !== $obj[0] && $(this).find('.name').text() === newName) {
      newName = ''
    }
  })
  if (!newName) {
    return false
  }
  let object_name = 'eportfolio_category'
  if (type === 'page') {
    object_name = 'eportfolio_entry'
  }
  const data = {}
  data[object_name + '[name]'] = newName
  if (type === 'page') {
    data[object_name + '[eportfolio_category_id]'] = $('#eportfolio_category_id').text()
  }
  if (method === 'POST') {
    $obj.attr('id', type + '_saving')
  }
  $obj.data('event_pending', true)
  $obj.addClass('event_pending')
  $.ajaxJSON(
    url,
    method,
    data,
    res => {
      $obj.removeClass('event_pending')
      $obj.removeClass('unsaved')
      const obj = res[object_name]
      if (method === 'POST') {
        $obj.remove()
        $(document).triggerHandler(type + '_added', res)
      } else {
        $(document).triggerHandler(type + '_updated', res)
      }
      $obj.fillTemplateData({
        data: obj,
        id: type + '_' + obj.id,
        hrefValues: ['id', 'slug'],
      })
      $obj.data('event_pending', false)
    },
    // error callback
    (_res, xhr, _textStatus, _errorThrown) => {
      $obj.removeClass('event_pending')
      $obj.data('event_pending', false)
      let name_message = I18n.t('errors.section_name_invalid', 'Section name is not valid')
      if (xhr.name && xhr.name.length > 0 && xhr.name[0].message === 'too_long') {
        name_message = I18n.t('errors.section_name_too_long', 'Section name is too long')
      }
      if ($obj.hasClass('unsaved')) {
        alert(name_message)
        $obj.remove()
      } else {
        // put back in "edit" mode
        $obj.find('.edit_section_link').click()
        $obj.find('#section_name').errorBox(name_message).css('z-index', 20)
      }
    },
    // options
    {skipDefaultError: true},
  )
  return true
}

function renderCreateForm() {
  const createContainer = document.getElementById('create_portfolio_mount')
  const formContainer = document.getElementById('create_portfolio_form_mount')

  if (createContainer) {
    return (
      <Portal open={true} mountNode={createContainer}>
        <CreatePortfolioForm formMount={formContainer} />
      </Portal>
    )
  }
}

function renderPortal(portfolio_id) {
  const sectionListContainer = document.getElementById('section_list_mount')
  const submissionContainer = document.getElementById('recent_submission_mount')
  const pageListContainer = document.getElementById('page_list_mount')

  return (
    <QueryClientProvider client={queryClient}>
      <PortfolioPortal
        portfolioId={portfolio_id}
        sectionListNode={sectionListContainer}
        pageListNode={pageListContainer}
        submissionNode={submissionContainer}
        onPageUpdate={json => $(document).triggerHandler('page_updated', json)}
      />
    </QueryClientProvider>
  )
}

$(document).ready(function () {
  const portfolio_id = ENV.eportfolio_id
  // formRoot is for the name field in the edit page form and renders dynamically
  // root is for everything else and should always be rendered
  let formRoot = null
  const pageNameMount = document.getElementById('page_name_mount')
  if (pageNameMount) {
    formRoot = ReactDOM.createRoot(pageNameMount)
  }
  const root = ReactDOM.createRoot(document.getElementById('eportfolio_portal_mount'))
  if (portfolio_id) {
    root.render(renderPortal(portfolio_id))
  } else {
    root.render(renderCreateForm())
  }
  // Add ePortfolio related
  $('.add_eportfolio_link').click(function (event) {
    event.preventDefault()
    $('#whats_an_eportfolio').slideToggle()
    $('#add_eportfolio_form').slideToggle(function () {
      $(this).find(':text:first').focus().select()
    })
  })
  $('#add_eportfolio_form .cancel_button').click(() => {
    $('#add_eportfolio_form').slideToggle()
    $('#whats_an_eportfolio').slideToggle()
  })
  $('#add_eportfolio_form').submit(function () {
    const $this = $(this)
    const result = $this.validateForm(ePortfolioValidations)
    if (!result) {
      return false
    }
  })
  $('.edit_content_link').click(function (event) {
    event.preventDefault()
    $('.edit_content_link_holder').hide()
    $('#page_content').addClass('editing')
    $('#edit_page_form').addClass('editing')
    $('#page_sidebar').addClass('editing')
    $('#edit_page_form .section').each(function () {
      const $section = $(this)
      const sectionData = $section.getTemplateData({
        textValues: ['section_type'],
        htmlValues: ['section_content'],
      })
      sectionData.section_content = $.trim(sectionData.section_content)
      const section_type = sectionData.section_type
      const edit_type = 'edit_' + section_type + '_content'

      const $edit = $('#edit_content_templates .' + edit_type).clone(true)
      $section.append($edit.show())
      if (edit_type === 'edit_html_content') {
        $edit.find('.edit_section').attr('id', 'edit_' + $section.attr('id'))
        $edit.find('.edit_section').val(sectionData.section_content)
      } else if (edit_type === 'edit_rich_text_content') {
        const $richText = $edit.find('.edit_section')
        $richText.attr('id', 'edit_' + $section.attr('id'))
        RichContentEditor.loadNewEditor($richText, {defaultContent: sectionData.section_content})
      }
    })
    if (formRoot) {
      const currentPageName = $('#content h2 .name').text()
      const pageButtonContainer = document.getElementById('page_button_mount')
      const sideButtonContainer = document.getElementById('side_button_mount')

      formRoot.render(
        <PageNameContainer
          pageName={currentPageName}
          contentBtnNode={pageButtonContainer}
          sideBtnNode={sideButtonContainer}
          onPreview={previewPage}
          onCancel={cancel}
          onSave={submitPage}
          onKeepEditing={keepEditing}
          setHidden={setHidden}
        />,
      )
    }

    $('#edit_page_form :text:first').focus().select()
    $('#page_comments_holder').hide()
    $(document).triggerHandler('editing_page')
  })
  $('#edit_page_form')
    .find('.allow_comments')
    .change(function () {
      $('#edit_page_form .show_comments_box').showIf($(this).prop('checked'))
    })
    .change()
  function submitPage() {
    formRoot.render(null)
    $('#edit_page_form').submit()
  }
  function previewPage() {
    $('#page_content .section.failed').remove()
    $('#edit_page_form,#page_content,#page_sidebar').addClass('previewing')
    $('#page_content .section').each(function () {
      const $section = $(this)
      const $preview = $section
        .find('.section_content')
        .clone()
        .removeClass('section_content')
        .addClass('preview_content')
        .addClass('preview_section')
      const section_type = $section.getTemplateData({textValues: ['section_type']}).section_type
      if (section_type === 'html') {
        // xsslint safeString.function sanitizeHtml
        $preview.html(sanitizeHtml($section.find('.edit_section').val()))
        $section.find('.section_content').after($preview)
      } else if (section_type === 'rich_text') {
        const $richText = $section.find('.edit_section')
        const editorContent = RichContentEditor.callOnRCE($richText, 'get_code')
        if (editorContent) {
          $preview.html(sanitizeHtml(editorContent))
        }
        $section.find('.section_content').after($preview)
      }
    })
  }

  function keepEditing() {
    $('#edit_page_form,#page_content,#page_sidebar').removeClass('previewing')
    $('#page_content .preview_section').remove()
  }

  function cancel() {
    formRoot.render(null)
    $('#edit_page_form .edit_rich_text_content .edit_section').each(function () {
      RichContentEditor.destroyRCE($(this))
    })
    $('#edit_page_form,#page_content,#page_sidebar').removeClass('editing')
    $('#page_content .section.unsaved').remove()
    $('.edit_content_link_holder').show()
    $('#edit_page_form .edit_section').each(function () {
      $(this).remove()
    })
    $('#page_content .section .form_content').remove()
    $('#page_comments_holder').show()
  }

  function setHidden(pageName) {
    document.getElementById('page_name_field').value = pageName
  }

  $('#edit_page_form').formSubmit({
    processData(_data) {
      $('#page_content .section.unsaved').removeClass('unsaved')
      $('#page_content .section.failed').remove()
      $('#page_content .section').each(function () {
        const $section = $(this)
        const section_type = $section.getTemplateData({textValues: ['section_type']}).section_type
        if (section_type === 'rich_text' || section_type === 'html') {
          if (section_type === 'rich_text') {
            const $richText = $section.find('.edit_section')
            const editorContent = RichContentEditor.callOnRCE($richText, 'get_code')
            if (editorContent) {
              $section.find('.section_content').html(sanitizeHtml(editorContent))
            }
            RichContentEditor.destroyRCE($richText)
          } else {
            const code = sanitizeHtml($section.find('.edit_section').val())
            $section.find('.section_content').html(raw(code))
          }
        } else if (!$section.hasClass('read_only')) {
          $section.remove()
        }
      })
      return ePortfolioFormData()
    },
    beforeSubmit(_data) {
      $('#edit_page_form .edit_rich_text_content .edit_section').each(function () {
        RichContentEditor.destroyRCE($(this))
      })
      $('#edit_page_form,#page_content,#page_sidebar')
        .removeClass('editing')
        .removeClass('previewing')
      $('#page_content .section.unsaved,#page_content .section .form_content').remove()
      $('#edit_page_form .edit_section').each(function () {
        $(this).remove()
      })
      $(this).loadingImage()
    },
    success(data) {
      $(document).triggerHandler('page_updated', data)
      $('.edit_content_link_holder').show()
      if (data.eportfolio_entry.allow_comments) {
        $('#page_comments_holder').slideDown('fast')
      }
      $(this).loadingImage('remove')
    },
  })
  $('#edit_page_form .switch_views_link').click(function (event) {
    event.preventDefault()
    RichContentEditor.callOnRCE($('#edit_page_content'), 'toggle')
    //  todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(this).siblings('.switch_views_link').andSelf().toggle().focus()
  })
  $('#edit_page_sidebar .add_content_link').click(function (event) {
    event.preventDefault()
    $('#edit_page_form .keep_editing_button:first').click()
    const $section = $('#page_section_blank')
      .clone(true)
      .attr('id', 'page_section_' + ENV.SECTION_COUNT_IDX)
    $section.addClass('unsaved')
    $section.attr('id', 'page_section_' + ENV.SECTION_COUNT_IDX++)
    $('#page_content').append($section)
    let section_type = 'rich_text'
    let section_type_name = I18n.t(
      '#eportfolios._page_section.section_types.rich_text',
      'Rich Text Content',
    )
    if ($(this).hasClass('add_html_link')) {
      section_type = 'html'
      section_type_name = I18n.t(
        '#eportfolios._page_section.section_types.html',
        'HTML/Embedded Content',
      )
    } else if ($(this).hasClass('add_submission_link')) {
      section_type = 'submission'
      section_type_name = I18n.t(
        '#eportfolios._page_section.section_types.submission',
        'Course Submission',
      )
    } else if ($(this).hasClass('add_file_link')) {
      section_type = 'attachment'
      section_type_name = I18n.t(
        '#eportfolios._page_section.section_types.attachment',
        'Image/File Upload',
      )
    }
    const edit_type = 'edit_' + section_type + '_content'
    $section.fillTemplateData({
      data: {section_type, section_type_name},
    })
    const $edit = $('#edit_content_templates .' + edit_type).clone(true)
    $section.append($edit.show())
    if (edit_type === 'edit_html_content') {
      $edit.find('.edit_section').attr('id', 'edit_' + $section.attr('id'))
    } else if (edit_type === 'edit_rich_text_content') {
      const $richText = $edit.find('.edit_section')
      $richText.attr('id', 'edit_' + $section.attr('id'))
      RichContentEditor.loadNewEditor($richText, {focus: true, defaultContent: ''})
    }
    $section.hide().slideDown('fast', () => {
      $('html,body').scrollTo($section)
      if (section_type === 'html') {
        $edit.find('.edit_section').focus().select()
      }
      if (section_type === 'submission') {
        $edit.find('.submission:first .text').focus()
      }
    })
  })
  $('.delete_page_section_link').on('click', function (event) {
    event.preventDefault()
    $(this)
      .parents('.section')
      .confirmDelete({
        success() {
          $(this).slideUp(function () {
            $(this).remove()
          })
        },
      })
  })
  $('#page_content').sortable({
    handle: '.move_link',
    helper: 'clone',
    axis: 'y',
    start(_event, ui) {
      const $section = $(ui.item)
      if ($section.getTemplateData({textValues: ['section_type']}).section_type === 'rich_text') {
        const $richText = $section.find('.edit_section')
        RichContentEditor.destroyRCE($richText)
      }
    },
    stop(_event, ui) {
      const $section = $(ui.item)
      if ($section.getTemplateData({textValues: ['section_type']}).section_type === 'rich_text') {
        const $richText = $section.find('.edit_section')
        RichContentEditor.loadNewEditor($richText)
      }
    },
  })
  $('#page_content')
    .on('click', '.cancel_content_button', function (event) {
      event.preventDefault()
      $(this)
        .parents('.section')
        .slideUp(function () {
          $(this).remove()
        })
    })
    .on('click', '.select_submission_button', function (event) {
      event.preventDefault()
      const $section = $(this).parents('.section')
      const $selection = $section.find('.submission_list li.active-leaf:first')
      if ($selection.length === 0) {
        return
      }
      const url = $selection.find('.submission_info').attr('href')
      const title = $selection.find('.submission_info').text()
      const id = $selection.attr('id').substring(11)
      $section.fillTemplateData({
        data: {submission_id: id},
      })
      const $sectionContent = $section.find('.section_content')
      $sectionContent.empty()
      const $frame = $('#edit_content_templates').find('.submission_preview').clone()
      $frame.attr('src', url)
      $sectionContent.append($frame)
      $section.addClass('read_only')
      $(this).focus()
      $.screenReaderFlashMessage(I18n.t('submission added: %{title}', {title}))
    })
    .on('click', '.upload_file_button', function (event) {
      event.preventDefault()
      event.stopPropagation()
      const $section = $(this).parents('.section')
      const $message = $('#edit_content_templates').find('.uploading_file').clone()
      const $upload = $(this).parents('.section').find('.file_upload')

      if (!$upload.val() && $section.find('.file_list .leaf.active').length === 0) {
        return
      }

      $message.fillTemplateData({
        data: {file_name: $upload.val()},
      })
      $(this).parents('.section').find('.section_content').empty().append($message.show())
      const $form = $('#upload_file_form').clone(true).attr('id', '')
      $('body').append($form.css({position: 'absolute', zIndex: -1}))
      $form.data('section', $section)
      $form.find('.file_upload').remove().end().append($upload).submit()
      $section.addClass('read_only')
    })
  $('#upload_file_form').formSubmit({
    fileUpload: true,
    fileUploadOptions: {
      preparedFileUpload: true,
      upload_only: true,
      singleFile: true,
      context_code: ENV.context_code,
      folder_id: ENV.folder_id,
      formDataTarget: 'uploadDataUrl',
    },
    object_name: 'attachment',
    processData(data) {
      if (!data.uploaded_data) {
        const $section = $(this).data('section')
        const $file = $section.find('.file_list .leaf.active')
        // If the user has selected a file from the list instead of uploading
        if ($file.length > 0) {
          const templateData = $file.getTemplateData({textValues: ['id', 'name']})
          const id = templateData.id
          const uuid = $('#file_uuid_' + id).text()
          const name = templateData.name
          $section.find('.attachment_id').text(id)
          let url = $('.eportfolio_download_url').attr('href')
          url = replaceTags(url, 'uuid', uuid)
          if ($file.hasClass('image')) {
            const $image = $('#eportfolio_view_image').clone(true).removeAttr('id')
            $image.find('.eportfolio_image').attr('src', url).attr('alt', name)
            $image.find('.eportfolio_download').attr('href', url)
            $section.find('.section_content').empty().append($image)
          } else {
            const $download = $('#eportfolio_download_file').clone(true).removeAttr('id')
            $download.fillTemplateData({
              data: {filename: name},
            })
            $download.find('.eportfolio_download').attr('href', url)
            $section.find('.section_content').empty().append($download)
          }
          $(this).remove()
        } else {
          $(this).errorBox(I18n.t('errors.missing_file', 'Please select a file'))
        }
        return false
      }
    },
    success(attachment) {
      const $section = $(this).data('section')
      $section.find('.attachment_id').text(attachment.id)
      let url = $('.eportfolio_download_url').attr('href')
      url = replaceTags(url, 'uuid', attachment.uuid)
      if (attachment['content-type'].indexOf('image') !== -1) {
        const $image = $('#eportfolio_view_image').clone(true).removeAttr('id')
        $image.find('.eportfolio_image').attr('src', url).attr('alt', attachment.display_name)
        $image.find('.eportfolio_download').attr('href', url)
        $section.find('.section_content').empty().append($image)
      } else {
        const $download = $('#eportfolio_download_file').clone(true).removeAttr('id')
        $download.fillTemplateData({
          data: {filename: attachment.display_name},
        })
        $download.find('.eportfolio_download').attr('href', url)
        $section.find('.section_content').empty().append($download)
      }
      $(this).remove()
    },
    error(data) {
      const $section = $(this).data('section')
      $section.find('.uploading_file').text(I18n.t('errors.upload_failed', 'Upload Failed.'))
      $section.addClass('failed')
      $(this).remove()
      $section.formErrors(data.errors || data)
    },
  })

  $('.delete_comment_link').click(function (event) {
    event.preventDefault()
    $(this)
      .parents('.comment')
      .confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('confirm_delete_message', 'Are you sure you want to delete this message?'),
        success(_data) {
          $(this).slideUp(function () {
            $(this).remove()
          })
        },
      })
  })
  $('.delete_eportfolio_link').click(event => {
    event.preventDefault()
    $('#delete_eportfolio_form').toggle(() => {
      $('html,body').scrollTo($('#delete_eportfolio_form'))
    })
  })
  $(document).blur(() => {})

  $('.submission_list').instTree({
    multi: false,
    dragdrop: false,
  })
  $('.file_list > ul').instTree({
    autoclose: false,
    multi: false,
    dragdrop: false,
    overrideEvents: true,
    onClick(_e, _node) {
      $(this).parents('.file_list').find('li.active').removeClass('active')
      $(this).addClass('active')
    },
  })
  $(document).bind('page_added page_updated', (_event, data) => {
    const entry = data.eportfolio_entry
    const $activePage = $('#eportfolio_entry_' + entry.id)
    if ($activePage.length) {
      $activePage.fillTemplateData({
        id: 'eportfolio_entry_' + entry.id,
        data: entry,
      })
    }
  })
  $('#page_name')
    .keydown(function (event) {
      if (event.keyCode === 27) {
        // esc
      } else if (event.keyCode === 13) {
        // enter
        $(this).parents('li').find('.name').text($(this).val())
        saveObject($(this).parents('li'), 'page')
      }
    })
    .blur(function () {
      const $page = $(this).parents('li.page')
      saveObject($page, 'page')
    })

  const $wizard_box = $('#wizard_box')

  function setWizardSpacerBoxDisplay(action) {
    $('#wizard_spacer_box')
      .height($wizard_box.height() || 0)
      .showIf(action === 'show')
  }

  const pathname = window.location.pathname
  $('.close_wizard_link').click(event => {
    event.preventDefault()
    userSettings.set('hide_wizard_' + pathname, true)

    $wizard_box.slideUp('fast', () => {
      $('.wizard_popup_link').slideDown('fast')
      $('.wizard_popup_link').focus()
      setWizardSpacerBoxDisplay('hide')
    })
  })

  $('.wizard_popup_link').click(event => {
    event.preventDefault()
    $('.wizard_popup_link').slideUp('fast')
    $wizard_box.slideDown('fast', () => {
      $wizard_box.triggerHandler('wizard_opened')
      $wizard_box.focus()
      $([document, window]).triggerHandler('scroll')
    })
  })

  if ($wizard_box.length) {
    $wizard_box.bind('wizard_opened', () => {
      const $wizard_options = $wizard_box.find('.wizard_options'),
        height = $wizard_options.height()
      $wizard_options.height(height)
      $wizard_box.find('.wizard_details').css({
        maxHeight: height - 5,
        overflow: 'auto',
      })
      setWizardSpacerBoxDisplay('show')
    })

    $wizard_box.find('.wizard_options_list .option').click(function (event) {
      const $this = $(this)
      const $a = $(event.target).closest('a')
      if ($a.length > 0 && $a.attr('href') !== '#') {
        return
      }
      event.preventDefault()
      $this.parents('.wizard_options_list').find('.option.selected').removeClass('selected')
      $this.addClass('selected')
      const $details = $wizard_box.find('.wizard_details')
      const data = $this.getTemplateData({textValues: ['header']})
      data.link = data.header
      $details.fillTemplateData({
        data,
      })
      $details.find('.details').remove()
      $details.find('.header').after($this.find('.details').clone(true).show())
      const url = $this.find('.header').attr('href')
      if (url !== '#') {
        $details.find('.link').show().attr('href', url)
      } else {
        $details.find('.link').hide()
      }
      $details.hide().fadeIn('fast')
    })
    setTimeout(() => {
      if (!userSettings.get('hide_wizard_' + pathname)) {
        $('.wizard_popup_link.auto_open:first').click()
      }
    }, 500)
  }

  $('.download_eportfolio_link').click(function (event) {
    $(this).slideUp()
    event.preventDefault()
    $('#export_progress').progressbar().progressbar('option', 'value', 0)
    const $box = $('#downloading_eportfolio_message')
    $box.slideDown()
    $box
      .find('.message')
      .text(
        I18n.t(
          'Collecting ePortfolio resources. This may take a while if you have a lot of files in your ePortfolio.',
        ),
      )
    const url = $(this).attr('href')
    let errorCount = 0
    const check = function (first) {
      let req_url = url
      if (first) {
        req_url = url + '?compile=1'
      }
      $.ajaxJSON(
        req_url,
        'GET',
        {},
        data => {
          if (
            data.attachment &&
            data.attachment.file_state &&
            data.attachment.file_state === 'available'
          ) {
            $('#export_progress').progressbar('option', 'value', 100)
            window.location.href = url + '.zip'
            return
          } else if (data.attachment && data.attachment.file_state) {
            const progress = parseInt(data.attachment.file_state, 10)
            $('#export_progress').progressbar(
              'option',
              'value',
              Math.max(
                Math.min($('#export_progress').progressbar('option', 'value') + 0.1, 90),
                progress,
              ),
            )
          } else {
            $('#export_progress').progressbar(
              'option',
              'value',
              Math.min($('#export_progress').progressbar('option', 'value') + 0.1, 90),
            )
          }
          setTimeout(check, 2000)
        },
        _data => {
          errorCount++
          if (errorCount > 5) {
            $box
              .find('.message')
              .text(
                I18n.t(
                  'errors.compiling',
                  'There was an error compiling your eportfolio.  Please try again in a little while.',
                ),
              )
          } else {
            setTimeout(check, 5000)
          }
        },
      )
    }
    check(true)
  })
})
