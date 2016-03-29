define ['compiled/str/apiUserContent'], (apiUserContent) ->

  mathml_html = null
  module "apiUserContent.convert",
    setup: ->
      mathml_html =  "<div><ul>\n" +
                "<li><img class=\"equation_image\" data-mathml=\"&lt;math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot; display=&quot;inline&quot;&gt;&lt;mi&gt;i&lt;/mi&gt;&lt;mi&gt;n&lt;/mi&gt;&lt;mi&gt;t&lt;/mi&gt;&lt;mi&gt;f&lt;/mi&gt;&lt;mo stretchy='false'&gt;(&lt;/mo&gt;&lt;mi&gt;x&lt;/mi&gt;&lt;mo stretchy='false'&gt;)&lt;/mo&gt;&lt;mo&gt;/&lt;/mo&gt;&lt;mi&gt;g&lt;/mi&gt;&lt;mo stretchy='false'&gt;(&lt;/mo&gt;&lt;mi&gt;x&lt;/mi&gt;&lt;mo stretchy='false'&gt;)&lt;/mo&gt;&lt;/math&gt;\"></li>\n" +
                "<li><img class=\"equation_image\" data-mathml='&lt;math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\"&gt;&lt;mo lspace=\"thinmathspace\" rspace=\"thinmathspace\"&gt;&amp;Sum;&lt;/mo&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mo&gt;.&lt;/mo&gt;&lt;mo&gt;.&lt;/mo&gt;&lt;mi&gt;n&lt;/mi&gt;&lt;/math&gt;'></li>\n" +
                "<li><img class=\"nothing_special\"></li>\n"+
             "</ul></div>"

    teardown: ->

  test "moves mathml into a screenreader element", ->
    output = apiUserContent.convert(mathml_html)
    ok(output.includes("<span class=\"hidden-readable\"><math "))

  test "mathml need not be screenreadered if editing content (this would start an update loop)", ->
    output = apiUserContent.convert(mathml_html, forEditing: true)
    ok(!output.includes("<span class=\"hidden-readable\"><math "))

  test "adds media comments for tagged audio content", ->
    html = "<div><audio class='instructure_inline_media_comment' data-media_comment_id='42' data-media_comment_type='audio'><span>24</span></audio></div>"
    output = apiUserContent.convert(html)
    expected = "<div><a id=\"media_comment_42\" data-media_comment_type=\"audio\" class=\"instructure_inline_media_comment audio_comment\"><span>24</span></a></div>"
    equal(output, expected)
