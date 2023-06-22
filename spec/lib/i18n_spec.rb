# frozen_string_literal: true

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
#

describe I18n do
  context "DontTrustPluralizations" do
    it "does not raise an exception for a bad pluralization entry" do
      missing_other_key = { en: { __pluralize_test: { one: "One thing" } } }
      I18n.backend.stub(missing_other_key) do
        expect(I18n.t(:__pluralize_test, count: 123)).to eq ""
      end
    end
  end

  context "interpolation" do
    it "falls back to en if the current locale's interpolation is broken" do
      I18n.with_locale(:es) do
        I18n.backend.stub es: { __interpolation_test: "Hola %{mundo}" } do
          expect(I18n.t(:__interpolation_test, "Hello %{mundo}", { mundo: "WORLD" }))
            .to eq "Hola WORLD"
          expect(I18n.t(:__interpolation_test, "Hello %{world}", { world: "WORLD" }))
            .to eq "Hello WORLD"
        end
      end
    end

    it "raises an error if the the en interpolation is broken" do
      expect do
        I18n.t(:__interpolation_test, "Hello %{world}", { foo: "bar" })
      end.to raise_error(I18n::MissingInterpolationArgument)
    end

    it "formats count numbers" do
      I18n.backend.stub(en: { __interpolation_test: { one: "One thing", other: "%{count} things" } }) do
        expect(I18n.t(:__interpolation_test,
                      one: "One thing",
                      other: "%{count} things",
                      count: 1001)).to eq "1,001 things"
      end
    end
  end

  context "genitives" do
    it "forms with `'s` in english" do
      expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq("Cody's")
    end

    it "forms with `s` in german generally" do
      I18n.with_locale(:de) do
        expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq("Codys")
      end
    end

    it "forms with `'` in german when ending appropriately" do
      I18n.with_locale(:de) do
        expect(I18n.form_proper_noun_singular_genitive("Max")).to eq("Max'")
      end
    end

    it "forms with `de ` in spanish" do
      I18n.with_locale(:es) do
        expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq("de Cody")
      end
    end

    it "returns it untouched in chinese" do
      I18n.with_locale(:"zh-Hant") do
        expect(I18n.form_proper_noun_singular_genitive("Cody")).to eq("Cody")
      end
    end
  end
end
