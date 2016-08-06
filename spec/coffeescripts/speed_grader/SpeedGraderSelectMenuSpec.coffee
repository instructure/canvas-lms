define [
  'jquery',
  'speed_grader_select_menu'
], ($, SpeedgraderSelectMenu)->

  module "SpeedGraderSelectMenu",
    setup: ->
      @fixtureNode = document.getElementById("fixtures")
      @testArea = document.createElement('div')
      @testArea.id = "test_area"
      @fixtureNode.appendChild(@testArea)
      @selectMenu = new SpeedgraderSelectMenu(null, null)

    teardown: ->
      @fixtureNode.innerHTML = ""
      $(".ui-selectmenu-menu").remove()

  test "Properly changes the a and select tags", ->
    @testArea.innerHTML = '<select id="students_selectmenu" style="foo" aria-disabled="true"></select><a class="ui-selectmenu" role="presentation" aria-haspopup="true" aria-owns="true"></a>'
    @selectMenu.selectMenuAccessibilityFixes(@testArea)

    equal(@testArea.innerHTML,'<select id="students_selectmenu" class="screenreader-only" tabindex="0"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"></a>')


  test "The span tag decorates properly with focus event", ->
    @testArea.innerHTML = '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("focus", true, true)

    document.getElementById('hit_me').dispatchEvent(event)
    equal(@testArea.innerHTML, '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>')


  test "The span tag decorates properly with focusout event", ->
    @testArea.innerHTML = '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("blur", true, true)

    document.getElementById('hit_me').dispatchEvent(event)
    equal(@testArea.innerHTML, '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>')


  test "The span tag decorates properly with select tag focus event", ->
    @testArea.innerHTML = '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("focus", true, true)

    document.getElementById('students_selectmenu').dispatchEvent(event)
    equal(@testArea.innerHTML, '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>')


  test "The span tag decorates properly with select tag focusout event", ->
    @testArea.innerHTML = '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
    @selectMenu.focusHandlerAccessibilityFixes(@testArea)
    event = document.createEvent('Event')
    event.initEvent("blur", true, true)

    document.getElementById('students_selectmenu').dispatchEvent(event)
    equal(@testArea.innerHTML, '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>')


  test "A key press event on the select menu causes the change function to call", ->
    MENU_PARTS_DELIMITER = "----NO----"
    optionsHTML = '<option value="1" class="graded ui-selectmenu-hasIcon">Student 1----NO----graded----NO----graded</option><option value="2" class="not_graded ui-selectmenu-hasIcon">Student 2----NO----not graded----NO----not_graded</option>'
    fired = false
    selectMenu = new SpeedgraderSelectMenu(optionsHTML, MENU_PARTS_DELIMITER)
    selectMenu.appendTo('#test_area', (e)->
      fired = true
    )
    event = new Event('keyup')
    event.keyCode = 37

    document.getElementById('students_selectmenu').dispatchEvent(event)
    equal(fired, true)

  test "Properly replaces the default ui selectmenu icon with the min-arrow-down icon", ->
    @testArea.innerHTML = '<span class="ui-selectmenu-icon ui-icon"></span>'
    @selectMenu.replaceDropdownIcon(@testArea)

    equal(@testArea.innerHTML,'<span class="ui-selectmenu-icon"><i class="icon-mini-arrow-down"></i></span>')
