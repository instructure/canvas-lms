require File.expand_path(File.dirname(__FILE__) + "/common")
require 'lib/handlebars/handlebars'

describe "handlebars selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    get "/"
  end

  it "should render templates correctly" do
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
    driver.execute_script Handlebars.compile_template(template, 'test')

    result = driver.execute_script("return Template('test', {title: 'greetings', name: 'katie', type: 'yoga', items: ['dont forget to stretch!!!'], url: 'http://foo.bar'})")
    result.should eql(<<-RESULT)
      <h1>greetings</h1>
      <p>ohai my name is katie im your <b>yoga</b> instructure!! ;) heres some tips to get you started:</p>
      <ol>
        
        <li>Important yoga tip: dont forget to stretch!!!</li>
        
      </ol>
      welp, see you l8r! dont forget 2 <a href="http://foo.bar">like us</a> on facebook lol
    RESULT
  end

end
