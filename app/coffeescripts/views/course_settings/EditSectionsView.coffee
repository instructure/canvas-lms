define [
  'i18n!course_settings'
  'jquery'
  'underscore'
  'compiled/views/DialogBaseView'
  'jst/courses/settings/EditSectionsView'
  'compiled/widget/ContextSearch'
  'str/htmlEscape'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, DialogBaseView, editSectionsViewTemplate, ContextSearch, h) ->

  class EditSectionsView extends DialogBaseView

    events:
      'click #user_sections li a': 'removeSection'

    dialogOptions:
      id: 'edit_sections'
      title: I18n.t 'titles.section_enrollments', 'Section Enrollments'

    render: ->
      @$el.html editSectionsViewTemplate
        sectionsUrl: ENV.SEARCH_URL
      @setupContextSearch()
      this

    setupContextSearch: ->
      @$('#section_input').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: I18n.t 'edit_sections_placeholder', 'Enter a section name'
        added: (data, $token, newToken) =>
          @$('#user_sections').append $token
        selector:
          baseData:
            type: 'section'
            context: "course_#{ENV.COURSE_ID}_sections"
            exclude: _.map(@model.get('enrollments'), (e) -> "section_#{e.course_section_id}")
          preparer: (postData, data, parent) ->
            row.noExpand = true for row in data
          browser:
            data:
              per_page: 100
              type: 'section'
              search_all_contexts: true
      input = @$('#section_input').data('token_input')
      input.$fakeInput.css('width', '100%')
      input.tokenValues = =>
        input.value for input in @$('#user_sections input')

      $sections = @$('#user_sections')
      for e in @model.get('enrollments')
        if section = ENV.CONTEXTS['sections'][e.course_section_id]
          sectionName = h section.name
          $sections.append $ """<li>
                                  <div class="ellipsis" title="#{sectionName}">#{sectionName}</div>
                                  <a></a>
                                  <input type="hidden" name="sections[]" value="section_#{section.id}">
                                </li>"""


    update: (e) =>
      e.preventDefault()

      enrollment = @model.get('enrollments')[0]
      currentIds = _.map @model.get('enrollments'), (en) -> en.course_section_id
      sectionIds = _.map $('#user_sections').find('input'), (i) -> parseInt($(i).val().split('_')[1])
      newSections = _.reject sectionIds, (i) => _.include currentIds, i
      deferreds = []
      # create new enrollments
      for id in newSections
        url = "/api/v1/sections/#{id}/enrollments"
        data =
          enrollment:
            user_id: @model.get('id')
            type: enrollment.type
            limit_privileges_to_course_section: enrollment.limit_priveleges_to_course_section
        deferreds.push $.ajaxJSON url, 'POST', data

      # delete old section enrollments
      sectionsToRemove = _.difference currentIds, sectionIds
      unenrolls = _.filter @model.get('enrollments'), (en) -> _.include sectionsToRemove, en.course_section_id
      for en in unenrolls
        url = "#{ENV.COURSE_ROOT_URL}/unenroll/#{en.id}"
        deferreds.push $.ajaxJSON url, 'DELETE'

      combined = $.when(deferreds...)
        .done =>
          @trigger 'updated'
          $.flashMessage I18n.t('flash.sections', 'Section enrollments successfully updated')
        .fail ->
          $.flashError I18n.t('flash.sectionError', "Something went wrong updating the user's sections. Please try again later.")
        .always => @close()
      @$el.disableWhileLoading combined, buttons: {'.btn-primary .ui-button-text': I18n.t('updating', 'Updating...')}

    removeSection: (e) ->
      $token = $(e.currentTarget).closest('li')
      if $token.closest('ul').children().length > 1
        $token.remove()
