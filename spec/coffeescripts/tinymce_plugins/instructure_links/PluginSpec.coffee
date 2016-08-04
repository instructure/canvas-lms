define [
  'jquery',
  'tinymce_plugins/instructure_links/plugin',
  'tinymce_plugins/instructure_links/linkable_editor',
], ($, EditorLinks, LinkableEditor)->

  selection = null
  alt = 'preview alt text'

  module "InstructureLinks Tinymce Plugin",
    setup: ->
      selection = {
        getContent: (()-> return "Selection Content" )
      }
    teardown: ->
      $(".ui-dialog").remove()

  test "buttonToImg builds an img tag", ->
    target =
      closest: (str)->
        attr: (str)->
          "some/img/url"
    equal(EditorLinks.buttonToImg(target), "<img src='some&#x2F;img&#x2F;url'/>")

  test "buttonToImg is not vulnerable to XSS", ->
    target =
      closest: (str)->
        attr: (str)->
          "<script>alert('attacked');</script>"
    equal(EditorLinks.buttonToImg(target), "<img src='&lt;script&gt;alert(&#x27;attacked&#x27;);&lt;&#x2F;script&gt;'/>")

  test "prepEditorForDialog snapshots the current selection state", ->
    called = false
    editor = { nodeChanged: (()-> called = true), selection: selection }
    EditorLinks.prepEditorForDialog(editor)
    equal(called, true)

  test "prepEditorForDialog wraps the editor in a linkable editor", ->
    editor = { nodeChanged: (()->), selection: selection }
    wrapper = EditorLinks.prepEditorForDialog(editor)
    equal(wrapper.selectedContent, "Selection Content")

  module "InstructureLinks Tinymce Plugin: bindLinkSubmit",
    setup: ->
      @box = $("
        <div data-editor='editorId'>
          <form id='instructure_link_prompt_form'>
            <input class='prompt' value='promptValue'/>
          </form>
          <div class='inst-link-preview-alt'>
            <input value='#{alt}'/>
          </div>
        </div>
      ")
      $("#fixtures").append(@box)
      @box.dialog()
      @form = @box.find("#instructure_link_prompt_form")
      @editor = { createLink: (()->) }
      @fetchClasses = (()-> "classes")

    teardown: ->
      $("#fixtures").empty()

  test "it fires my 'done' callback when form gets submitted", ->
    called = false
    done = (()-> called = true)
    EditorLinks.bindLinkSubmit(@box, @editor, @fetchClasses, done)
    @form.trigger('submit')
    ok(called)

  test "it removes any existing callbacks", ->
    called = false
    @form.on('submit', (()-> called = true))
    EditorLinks.bindLinkSubmit(@box, @editor, @fetchClasses, (()->))
    @form.trigger('submit')
    ok(!called)

  test "it prevents the event from propogating up the chain", ->
    called = false
    @box.on('submit', (()-> called = true))
    EditorLinks.bindLinkSubmit(@box, @editor, @fetchClasses, (()->))
    @form.trigger('submit')
    ok(!called)

  test "it closes the dialog box", ->
    @mock(@box).expects("dialog").once().withArgs('close')
    EditorLinks.bindLinkSubmit(@box, @editor, @fetchClasses, (()->))
    @form.trigger('submit')

  test "it inserts the link properly", ->
    @mock(@editor).expects("createLink").once().
      withArgs('promptValue', "classes", sinon.match({'preview-alt': alt}))
    called = false
    @box.on('submit', (()-> called = true))
    EditorLinks.bindLinkSubmit(@box, @editor, @fetchClasses, (()->))
    @form.trigger('submit')

  module "InstructureLinks Tinymce Plugin: buildLinkClasses"

  test "it removes any existing link-specific classes", ->
    box = $("<div></div>")
    priorClasses = "auto_open stylez inline_disabled stylee"
    classes = EditorLinks.buildLinkClasses(priorClasses, box)
    equal(classes, " stylez  stylee")

  test "is adds in auto_open if checked", ->
    box = $("<div>
      <input type='checkbox' checked class='auto_show_inline_content'/>
    </div>")
    priorClasses = ""
    classes = EditorLinks.buildLinkClasses(priorClasses, box)
    equal(classes, " auto_open")

  test "it adds in inline_disabled if checked", ->
    box = $("<div>
      <input type='checkbox' checked class='disable_inline_content'/>
    </div>")
    priorClasses = ""
    classes = EditorLinks.buildLinkClasses(priorClasses, box)
    equal(classes, " inline_disabled")
