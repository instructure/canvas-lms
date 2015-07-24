#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe I18n do
  context "_core_en.js" do
    it "should be up-to-date" do
      skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
      skip('core en changed in Rails 4 - commit updated _core_en.js after switch') unless CANVAS_RAILS3
      translations = {'en' => I18n.backend.direct_lookup('en').slice(*I18nTasks::Utils::CORE_KEYS)}

      # HINT: if this spec fails, run `rake i18n:generate_js`...
      # it probably means you added a format or a new language
      expect(File.read('public/javascripts/translations/_core_en.js')).to eq(
          I18nTasks::Utils.dump_js(translations)
      )
    end
  end

  context "interpolation" do
    before { I18n.locale = I18n.default_locale }
    after { I18n.locale = I18n.default_locale }

    it "should fall back to en if the current locale's interpolation is broken" do
      I18n.locale = :es
      I18n.backend.stub es: {__interpolation_test: "Hola %{mundo}"} do
        expect(I18n.t(:__interpolation_test, "Hello %{mundo}", {mundo: "WORLD"})).
          to eq "Hola WORLD"
        expect(I18n.t(:__interpolation_test, "Hello %{world}", {world: "WORLD"})).
          to eq "Hello WORLD"
      end
    end

    it "should raise an error if the the en interpolation is broken" do
      expect {
        I18n.t(:__interpolation_test, "Hello %{world}", {foo: "bar"})
      }.to raise_error(I18n::MissingInterpolationArgument)
    end
  end
end
