require File.expand_path(File.dirname(__FILE__) + "/common")
require 'lib/handlebars/handlebars'

describe "handlebars" do
  it_should_behave_like "in-process server selenium tests"

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
        url: 'http://foo.bar'
    CS

    result.should eql(<<-RESULT)
      <h1>greetings</h1>
      <p>ohai my name is katie im your <b>yoga</b> instructure!! ;) heres some tips to get you started:</p>
      <ol>
        
        <li>Important yoga tip: dont forget to stretch!!!</li>
        
      </ol>
      welp, see you l8r! dont forget 2 <a href="http://foo.bar">like us</a> on facebook lol
    RESULT
  end

  it "should 'require' partials used within template" do
    driver.execute_script Handlebars.compile_template("hi from inside partial", "_test_partial")
    driver.execute_script Handlebars.compile_template("outside partial {{>test_partial}}", "test_template")

    result = require_exec "jst/test_template", "test_template()"
    result.should eql "outside partial hi from inside partial"
  end
end

