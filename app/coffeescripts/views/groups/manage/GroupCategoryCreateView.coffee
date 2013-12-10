define [
  'underscore'
  'i18n!groups'
  'compiled/views/groups/manage/GroupCategoryEditView'
  'jst/groups/manage/groupCategoryCreate'
], (_, I18n, GroupCategoryEditView, template) ->

  class GroupCategoryCreateView extends GroupCategoryEditView

    template: template
    className: "form-dialog group-category-create"

    defaults:
      width: 600
      height: if ENV.allow_self_signup then 460 else 310
      title: I18n.t('create_group_set', 'Create Group Set')

    els: _.extend {},
      GroupCategoryEditView::els
      '.admin-signup-controls': '$adminSignupControls'
      '#split_groups': '$splitGroups'

    events: _.extend {},
      GroupCategoryEditView::events
      'click [name=split_group_count]': 'clickSplitGroupCount'

    toggleSelfSignup: ->
      enabled = @$selfSignupToggle.prop('checked')
      @$el.toggleClass('group-category-self-signup', enabled)
      @$el.toggleClass('group-category-admin-signup', !enabled)
      @$selfSignupControls.find(':input').prop 'disabled', !enabled
      @$adminSignupControls.find(':input').prop 'disabled', enabled

    clickSplitGroupCount: (e) ->
      # firefox doesn't like multiple inputs in the same label, so a little js to the rescue
      e.preventDefault()
      @$splitGroups.click()

    toJSON: ->
      _.extend {},
        super,
        num_groups: '<input name="create_group_count" type="number" min="0" class="input-micro" value="0">'
        split_num: '<input name="split_group_count" type="number" min="0" class="input-micro">'

