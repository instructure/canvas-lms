require File.expand_path(File.dirname(__FILE__) + "/common")
require 'lib/handlebars/handlebars'

describe "handlebars" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
  end

  it "should render templates correctly" do

    # need to inject the translation file onto the page because the compiled template requires it
    driver.execute_script "define('translations/test', function(){ return {} });"

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
    compiled = Handlebars.compile_template(template, 'test')
    driver.execute_script compiled

    result = require_exec 'jst/test', <<-CS
      test
        title: 'greetings'
        name: 'katie'
        type: 'yoga'
        items: ['dont forget to stretch!!!']
        input: '<input>'
        url: 'http://foo.bar'
        escaped: '<b>escaped</b>'
        unescaped: '<b>unescaped</b>'
    CS

    result.should == <<-RESULT
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
    driver.execute_script Handlebars.compile_template("hi from inside partial", "_test_partial")
    driver.execute_script Handlebars.compile_template("outside partial {{>test_partial}}", "test_template")

    result = require_exec "jst/test_template", "test_template()"
    result.should == "outside partial hi from inside partial"
  end

  it "should translate the content" do
    translations = {
      :pigLatin => {
        :sup => 'upsay',
        :test => {
          :it_should_work => 'isthay ouldshay ebay anslatedtray frday'
        }
      }
    }

    # get our translations into js-land
    driver.execute_script <<-JS
      define('translations/test', ['i18nObj', 'jquery'], function(I18n, $) {
        $.extend(true, I18n, {translations: #{translations.to_json}});
      });
    JS

    template = <<-HTML
      <p>{{#t "#sup"}}sup{{/t}}</p>
      <p>{{#t 'it_should_work'}}this should be translated frd{{/t}}</p>
      <p>{{#t "not_yet_translated"}}but this shouldn't be{{/t}}</p>
    HTML

    compiled = Handlebars.compile_template(template, 'test')
    driver.execute_script compiled

    result = require_exec 'jst/test', <<-CS
      I18n.locale = 'pigLatin'
      test()
    CS

    result.should == <<-HTML
      <p>#{translations[:pigLatin][:sup]}</p>
      <p>#{translations[:pigLatin][:test][:it_should_work]}</p>
      <p>but this shouldn't be</p>
    HTML
  end
end

