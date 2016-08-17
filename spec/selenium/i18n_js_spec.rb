require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
    if CANVAS_WEBPACK
      # I18n will already be exposed in webpack land
    else
      # get I18n and _ global for all the tests
      driver.execute_script "require(['i18nObj', 'underscore'], function (I18n, _) { window.I18n = I18n; window._ = _; });"
    end
  end

  context "strftime" do
    it "should format just like ruby" do
      # everything except %N %6N %9N %U %V %W %Z
      format = "%a %A %b %B %d %-d %D %e %F %h %H %I %j %k %l %L %m %M %n %3N %p %P %r %R %s %S %t %T %u %v %w %y %Y %z %%"
      date = Time.now
      expect(driver.execute_script(<<-JS).upcase).to eq date.strftime(format).upcase
        var date = new Date(#{date.strftime('%s')} * 1000 + #{date.strftime('%L').gsub(/^0+/, '')});
        return I18n.strftime(date, '#{format}');
      JS
    end
  end

  context "locales" do
    it "should pull in core translations for all locales" do
      skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
      core_keys = I18nTasks::Utils::CORE_KEYS
      core_translations = Hash[I18n.available_locales.map(&:to_s).map do |locale|
        [locale.to_s, I18n.backend.direct_lookup(locale).slice(*core_keys)]
      end].deep_stringify_keys

      expect(driver.execute_script(<<-JS)).to eq core_translations
        var core = {};
        var coreKeys = #{core_keys.map(&:to_s).inspect};
        Object.keys(I18n.translations).forEach(function(locale) {
          core[locale] = {};
          coreKeys.forEach(function(key) {
            if (I18n.translations[locale][key]) {
              core[locale][key] = I18n.translations[locale][key];
            }
          });
        });
        return core;
      JS
    end
  end

  context "scoped" do
    it "should use the scoped translations" do
      skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']

      (I18n.available_locales - [:en]).each do |locale|
        exec_cs("I18n.locale = '#{locale}'")
        rb_value = I18n.t('dashboard.confirm.close', 'fake en default', locale: locale)
        js_value = if CANVAS_WEBPACK
          driver.execute_script("return I18n.scoped('dashboard').t('confirm.close', 'fake en default');")
        else
          require_exec('i18n!dashboard', "i18n.t('confirm.close', 'fake en default')")
        end
        expect(js_value).to eq(rb_value)
      end
    end
  end
end
