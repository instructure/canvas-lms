require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    get "/"
  end

  context "html safety" do
    it "should not html-escape translations or interpolations by default" do
      driver.execute_script(<<-JS).should == 'these are some tags: <input> and <img>'
        return I18n.scoped('foo').translate('bar', 'these are some tags: <input> and %{another}', {another: '<img>'})
      JS
    end
    
    it "should html-escape translations and interpolations if any interpolated values are htmlSafe" do
      driver.execute_script(<<-JS).should == 'only one of these won\'t get escaped: &lt;input&gt;, &lt;img&gt;, <br> &amp; &lt;hr&gt;'
        return I18n.scoped('foo').translate('bar', "only one of these won't get escaped: <input>, %{a}, %{b} & %{c}", {a: '<img>', b: $.raw('<br>'), c: '<hr>'})
      JS
    end
  end
end
