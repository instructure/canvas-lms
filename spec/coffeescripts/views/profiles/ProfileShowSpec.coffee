define [
  'jquery'
  'compiled/views/profiles/ProfileShow'
], ($, ProfileShow) ->

  QUnit.module 'ProfileShow',
    setup: ->
      @fixtures = document.getElementById('fixtures')
      @fixtures.innerHTML = "<div class='.profile-link'></div>"
      @fixtures.innerHTML += "<textarea id='profile_bio'></textarea>"
      @fixtures.innerHTML += "<table id='profile_link_fields'></table>"

    teardown: ->
      @fixtures.innerHTML = ""

  test 'manages focus on link removal', ->
    @view = new ProfileShow
    @view.addLinkField()
    $row1 = $('#profile_link_fields tr:last-child')
    @view.addLinkField()
    $row2 = $('#profile_link_fields tr:last-child')

    @view.removeLinkRow(null, $row2.find('.remove_link_row'))
    equal document.activeElement, $row1.find('.remove_link_row')[0]
    @view.removeLinkRow(null, $row1.find('.remove_link_row'))
    equal document.activeElement, $('#profile_bio')[0]

  test 'focuses the name input when it is available and edit is clicked', ->
    @fixtures.innerHTML += "<input id='name_input' />"
    @view = new ProfileShow
    @view.showEditForm()
    equal(document.activeElement, $('#name_input')[0])

  test 'focuses the bio text area when the name input is not available and edit is clicked', ->
    @view = new ProfileShow
    @view.showEditForm()
    equal(document.activeElement, $('#profile_bio')[0])
