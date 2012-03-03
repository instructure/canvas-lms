define [
  'jquery'
  'jst/AssignmentGroupWeightsDialog'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_jquery_patches'
  'jquery.instructure_misc_helpers'
  'vendor/jquery.ba-tinypubsub'
], ($, assignmentGroupWeightsDialogTemplate) -> class AssignmentGroupWeightsDialog

  constructor: (options) ->
    @$dialog = $ assignmentGroupWeightsDialogTemplate()
    @$dialog.dialog
      autoOpen: false
      resizable: false
      width: 350
      buttons: [{
        text: @$dialog.find('button[type=submit]').hide().text()
        click: @save
      }]

    @$dialog.delegate 'input', 'change keyup keydown input', @calcTotal
    @$dialog.find('#group_weighting_scheme').change (event) =>
      disable = !event.currentTarget.checked
      @$dialog.find('table').css('opacity', if disable then 0.5 else 1 )
      @$dialog.find('.assignment_group_row input').attr('disabled', disable)

    @$group_template = @$dialog.find('.assignment_group_row.blank').removeClass('blank').detach().show()
    @$groups_holder = @$dialog.find('.groups_holder')
    @update(options)

  render: =>
    @$groups_holder.empty()
    for group in @options.assignmentGroups
      uniqueId = "assignment_group_#{group.id}_weight"
      @$group_template
        .clone()
        .data('assignment_group', group)
        .find('label').attr('for', uniqueId ).text(group.name).end()
        .find('input').attr('id', uniqueId).val(group.group_weight).end()
        .appendTo(@$groups_holder)
    @$dialog.find('#group_weighting_scheme').prop('checked', @options.context.group_weighting_scheme == 'percent').change()
    @calcTotal()

  update: (newOptions) =>
    @options = newOptions
    @render()

  calcTotal: =>
    total = 0
    @$dialog.find('.assignment_group_row input').each ->
      total += Number($(this).val())
    @$dialog.find('.total_weight').text(total)

  save: =>
    courseUrl = "/courses/#{@options.context.context_id}"
    requests = []

    newGroupWeightingScheme = if @$dialog.find('#group_weighting_scheme').is(':checked') then 'percent' else 'equal'
    if newGroupWeightingScheme != @options.context.group_weighting_scheme
      requests.push $.ajaxJSON courseUrl, 'PUT', {'course[group_weighting_scheme]' : newGroupWeightingScheme}, (data) =>
        @options.context.group_weighting_scheme = data.course.group_weighting_scheme

    @$dialog.find('.assignment_group_row').each (i, row)->
      group = $(row).data('assignment_group')
      newWeight = Number($(row).find('input').val())
      if newWeight != group.group_weight
        requests.push $.ajaxJSON "#{courseUrl}/assignment_groups/#{group.id}", 'PUT', {'assignment_group[group_weight]' : newWeight}, (data) ->
          $.extend(group, data.assignment_group)

    # when all the requests come back, call @afterSave
    promise = $.when.apply($, requests).done(@afterSave)
    @$dialog.disableWhileLoading(promise, buttons: ['.ui-button-text'])

  afterSave: =>
    @$dialog.dialog('close')
    @render()
    $.publish('assignment_group_weights_changed', @options)

