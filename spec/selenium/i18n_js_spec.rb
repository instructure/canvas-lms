require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
    # get I18n global for all the tests
    driver.execute_script "require(['i18nObj'], function (I18n) { window.I18n = I18n });"
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

    it "should interpolate placeholders in wrappers" do
      # this functionality is primarily useful in handlebars templates where
      # wrappers are auto-generated ... in normal js you'd probably just
      # manually concatenate it into your wrapper
      driver.execute_script(<<-JS).should == 'you need to <a href="http://foo.bar">log in</a>'
        return I18n.scoped('foo').translate('bar', 'you need to *log in*', {wrapper: '<a href="%{url}">$1</a>', url: 'http://foo.bar'})
      JS
    end
  end

  context "strftime" do
    it "should format just like ruby" do
      # everything except %N %6N %9N %U %V %W %Z
      format = "%a %A %b %B %d %-d %D %e %F %h %H %I %j %k %l %L %m %M %n %3N %p %P %r %R %s %S %t %T %u %v %w %y %Y %z %%"
      date = Time.now
      driver.execute_script(<<-JS).should == date.strftime(format)
        var date = new Date(#{date.strftime('%s')} * 1000 + #{date.strftime('%L').gsub(/^0+/, '')});
        return I18n.strftime(date, '#{format}');
      JS
    end
  end
end
