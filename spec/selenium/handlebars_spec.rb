require File.expand_path(File.dirname(__FILE__) + "/common")

describe "handlebars" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
  end

  def run_template(template, context, locale = 'en')
    compiled = HandlebarsTasks::Handlebars.compile_template(template, 'test')
    driver.execute_script compiled
    require_exec 'jst/test', <<-CS
      I18n.locale = '#{locale}'
      test(#{context.to_json})
    CS
  end

  it "should render templates correctly" do

    # need to inject the translation file onto the page because the compiled template requires it
    set_translations({})

    template = <<-HTML
      <h1>{{title}}</h1>
      <p>{{#t "message"}}ohai my name is {{name}} im your <b>{{type}}</b> instructure!! ;) heres some tips to get you started:{{/t}}</p>
      <ol>
        {{#each items}}
        <li>{{#t "protip" type=../type}}Important {{type}} tip:{{/t}} {{this}}</li>
        {{/each}}
      </ol>
      <p>{{#t "html"}}lemme instructure you some html: if you type {{input}}, you get {{{input}}}{{/t}}</p>
      <p>{{#t "reversed"}}in other words you get {{{input}}} when you type {{input}}{{/t}}</p>
      <p>{{#t "escapage"}}this is {{escaped}}{{/t}}</p>
      <p>{{#t "unescapage"}}this is {{{unescaped}}}{{/t}}</p>
      {{#t "bye"}}welp, see you l8r! dont forget 2 <a href="{{url}}">like us</a> on facebook lol{{/t}}
    HTML

    result = run_template(template, {
      title: 'greetings',
      name: 'katie',
      type: 'yoga',
      items: ['dont forget to stretch!!!'],
      input: '<input>',
      url: 'http://foo.bar',
      escaped: '<b>escaped</b>',
      unescaped: '<b>unescaped</b>'
    })

    expect(result).to eq <<-RESULT
      <h1>greetings</h1>
      <p>ohai my name is katie im your <b>yoga</b> instructure!! ;) heres some tips to get you started:</p>
      <ol>
        
        <li>Important yoga tip: dont forget to stretch!!!</li>
        
      </ol>
      <p>lemme instructure you some html: if you type &lt;input&gt;, you get <input></p>
      <p>in other words you get <input> when you type &lt;input&gt;</p>
      <p>this is &lt;b&gt;escaped&lt;/b&gt;</p>
      <p>this is <b>unescaped</b></p>
      welp, see you l8r! dont forget 2 <a href="http://foo.bar">like us</a> on facebook lol
    RESULT
  end

  it "should require partials used within template" do
    driver.execute_script HandlebarsTasks::Handlebars.compile_template("hi from inside partial", "_test_partial")
    driver.execute_script HandlebarsTasks::Handlebars.compile_template("outside partial {{>test_partial}}", "test_template")

    result = require_exec "jst/test_template", "test_template()"
    expect(result).to eq "outside partial hi from inside partial"
  end

  it "should translate the content" do
    translations = {
      pigLatin: {
        absolute_key: "Absoluteay eykay",
        inferred_key_c49e3743: "Inferreday eykay",
        inline_with_absolute_key: "Inlineay ithway absoluteay eykay",
        inline_with_inferred_key_88e68761: "Inlineay ithway inferreday eykay",
        test: {
          inline_with_relative_key: "Inlineay ithway elativeray eykay",
          relative_key: "Elativeray eykay"
        }
      }
    }
    set_translations(translations)

    template = <<-HTML
      <p>{{#t "#absolute_key"}}Absolute key{{/t}}</p>
      <p>{{#t "relative_key"}}Relative key{{/t}}</p>
      <p>{{#t}}Inferred key{{/t}}</p>

      <p>{{t "#inline_with_absolute_key" "Inline with absolute key"}}</p>
      <p>{{t "inline_with_relative_key" "Inline with relative key"}}</p>
      <p>{{t "Inline with inferred key"}}</p>

      <p>{{#t "not_yet_translated"}}No translation yet{{/t}}</p>
    HTML

    expect(run_template(template, {}, 'pigLatin')).to eq <<-HTML
      <p>Absoluteay eykay</p>
      <p>Elativeray eykay</p>
      <p>Inferreday eykay</p>

      <p>Inlineay ithway absoluteay eykay</p>
      <p>Inlineay ithway elativeray eykay</p>
      <p>Inlineay ithway inferreday eykay</p>

      <p>No translation yet</p>
    HTML
  end

  it "should properly apply wrappers for both defaults and translations" do
    set_translations({fr: {croissant: "*Je voudrais un croissant*"}})

    template = <<-HTML
      <p>
        {{#t "#croissant"}}
          <b>
            I'd like a croissant, please
          </b>
        {{/t}}
      </p>
      <p>
        {{#t "#not_translated"}}
          <i>
            Yes, that's true, he would
          </i>
        {{/t}}
      </p>
    HTML

    expect(run_template(template, {}, 'fr')).to eq <<-HTML
      <p>
        <b>Je voudrais un croissant</b>
      </p>
      <p>
        <i> Yes, that&#39;s true, he would </i>
      </p>
    HTML
  end
end

