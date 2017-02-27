define [
  'jquery'
  'compiled/views/DiscussionTopic/DiscussionTopicToolbarView'
], ($, DiscussionTopicToolbarView) ->

  fixture = """
  <div id="discussion-topic-toolbar">
    <div id="keyboard-shortcut-modal-info" tabindex="0">
      <span class="accessibility-warning" style="display: none;"></span>
    </div>
  </div>
  """

  QUnit.module 'DiscussionTopicToolbarView',
    setup: ->
      $('#fixtures').html(fixture)
      @view = new DiscussionTopicToolbarView(el: '#discussion-topic-toolbar')
      @info = @view.$('#keyboard-shortcut-modal-info .accessibility-warning')

    teardown: ->
      $('#fixtures').empty()

  test 'keyboard shortcut modal info shows when it has focus', ->
    ok @info.css('display') is 'none'
    @view.$('#keyboard-shortcut-modal-info').focus()
    ok @info.css('display') isnt 'none'

  test 'keyboard shortcut modal info hides when it loses focus', ->
    @view.$('#keyboard-shortcut-modal-info').focus()
    ok @info.css('display') isnt 'none'
    @view.$('#keyboard-shortcut-modal-info').blur()
    ok @info.css('display') is 'none'
