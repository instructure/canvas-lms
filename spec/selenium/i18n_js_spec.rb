#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + "/common")

describe "i18n js" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
    # get I18n global for all the tests
    driver.execute_script "require(['i18nObj'], function (I18n) { window.I18n = I18n });"
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
      skip("Rails 5.1 specific") unless CANVAS_RAILS5_1
      skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
      skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
      core_keys = I18nTasks::Utils::CORE_KEYS
      core_translations = Hash[I18n.available_locales.map do |locale|
        [locale.to_s, I18n.backend.send(:translations)[locale].slice(*core_keys)]
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
        driver.execute_script("I18n.locale = '#{locale}'")
        rb_value = I18n.t('dashboard.confirm.close', 'fake en default', locale: locale)
        js_value = driver.execute_script("return I18n.scoped('dashboard').t('confirm.close', 'fake en default');")
        expect(js_value).to eq(rb_value)
      end
    end
  end
end
