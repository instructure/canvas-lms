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

  context "wrappers" do
    it "should auto-html-escape" do
      driver.execute_script(<<-JS).should == '<b>2</b> &gt; 1'
        return I18n.scoped('foo').translate('bar', '*2* > 1', {wrapper: '<b>$1</b>'})
      JS
    end

    it "should not escape already-escaped text" do
      driver.execute_script(<<-JS).should == '<b><input></b> &gt; 1'
        return I18n.scoped('foo').translate('bar', '*%{input}* > 1', {input: $.raw('<input>'), wrapper: '<b>$1</b>'})
      JS
    end

    it "should support multiple wrappers" do
      driver.execute_script(<<-JS).should == '<i>1 + 1</i> == <b>2</b>'
        return I18n.scoped('foo').translate('bar', '*1 + 1* == **2**', {wrapper: {'*': '<i>$1</i>', '**': '<b>$1</b>'}})
      JS
    end

    it "should replace globally" do
      driver.execute_script(<<-JS).should == '<i>1 + 1</i> == <i>2</i>'
        return I18n.scoped('foo').translate('bar', '*1 + 1* == *2*', {wrapper: '<i>$1</i>'})
      JS
    end
  end
end
