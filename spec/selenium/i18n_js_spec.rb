require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
    # get I18n and _ global for all the tests
    driver.execute_script "require(['i18nObj', 'underscore'], function (I18n, _) { window.I18n = I18n; window._ = _; });"
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
      keep_trying_until do
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
