require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
    # get I18n and _ global for all the tests
    driver.execute_script "require(['i18nObj', 'underscore'], function (I18n, _) { window.I18n = I18n; window._ = _; });"
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
    
    it "should html-escape translations and interpolations if any placeholders are flagged as safe" do
      driver.execute_script(<<-JS).should == 'only one of these won\'t get escaped: &lt;input&gt;, &lt;img&gt;, <br> &amp; &lt;hr&gt;'
        return I18n.scoped('foo').translate('bar', "only one of these won't get escaped: <input>, %{a}, %h{b} & %{c}", {a: '<img>', b: '<br>', c: '<hr>'})
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
      driver.execute_script(<<-JS).upcase.should == date.strftime(format).upcase
        var date = new Date(#{date.strftime('%s')} * 1000 + #{date.strftime('%L').gsub(/^0+/, '')});
        return I18n.strftime(date, '#{format}');
      JS
    end
  end

  context "locales" do
    it "should pull in core translations for all locales" do
      pending('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      driver.execute_script(<<-JS).sort.should == I18n.available_locales.map(&:to_s).sort
        var ary = [];
        _.each(I18n.translations, function(translations, locale) {
          if (_.all(['date', 'time', 'number', 'datetime', 'support'], function(k) { return translations[k] })) {
            ary.push(locale);
          }
        })
        return ary;
      JS
    end
  end

  context "scoped" do
    it "should use the scoped translations" do
      pending('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      pending('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
      (I18n.available_locales - [:en]).each do |locale|
        exec_cs("I18n.locale = '#{locale}'")
        require_exec('i18n!conferences', "i18n.t('confirm.delete')").should ==
          I18n.t('conferences.confirm.delete', :locale => locale)
      end
    end
  end
end
