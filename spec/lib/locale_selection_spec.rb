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

describe LocaleSelection do
  def ls
    Class.new { extend LocaleSelection }
  end

  context "accept-language" do
    it "ignores malformed accept-language headers" do
      expect(ls.infer_browser_locale("en not valid", "en" => nil)).to be_nil
    end

    it "matches valid locale ranges" do
      expect(ls.infer_browser_locale("en", "en" => nil)).to eql("en")
    end

    it "does not match invalid locale ranges" do
      expect(ls.infer_browser_locale("it", "en" => nil)).to be_nil
    end

    it "does case-insensitive matching" do
      expect(ls.infer_browser_locale("en-us", "en-US" => nil)).to eql("en-US")
    end

    # see rfc2616 ... en means any en(-.*)? is acceptable
    it "does range prefix-matching" do
      expect(ls.infer_browser_locale("en", "en-US" => nil)).to eql("en-US")
    end

    # while tag prefix-matching might be desirable (sometimes), it should not
    # be done automatically on the server-side (though the user-agent can do
    # it). from the rfc:
    #   [U]sers might [incorrectly] assume that on selecting "en-gb", they
    #   will be served any kind of English document if British English is not
    #   available. A user agent might suggest in such a case to add "en" to
    #   get the best matching behavior.
    it "does not do tag prefix-matching" do
      expect(ls.infer_browser_locale("en-US", "en" => nil)).to be_nil
    end

    it "assigns quality values based on the best match" do
      expect(ls.infer_browser_locale("en-US, es;q=0.9, en;q=0.8", "en-US" => nil, "es" => nil)).to eql("en-US")

      # no tag prefix-matching
      expect(ls.infer_browser_locale("en-US, es;q=0.9, en;q=0.8", "en" => nil, "es" => nil)).to eql("es")

      # order doesn't matter
      expect(ls.infer_browser_locale("es;q=0.9, en", "en" => nil, "es" => nil)).to eql("en")

      # although the en range matches the en-US tag, the en-US range is
      # a better (read: longer) match. so the es tag ends up with a higher
      # quality value than en-US tag
      expect(ls.infer_browser_locale("en, es;q=0.9, en-US;q=0.8", "en-US" => nil, "es" => nil)).to eql("es")
    end

    it "understands wildcards" do
      expect(ls.infer_browser_locale("*, pt;q=0.8", "ru" => nil, "pt" => nil)).to eql("ru")
      expect(ls.infer_browser_locale("*, pt;q=0.8, ru;q=0.7", "ru" => nil, "pt" => nil)).to eql("pt")
      # the pt range is explicitly rejected, so we don't get a locale
      expect(ls.infer_browser_locale("pt-BR, *;q=0.9, pt;q=0", "pt" => nil)).to be_nil
      # no pt variants supported, so we get the first alternative
      expect(ls.infer_browser_locale("pt-BR, pt;q=0.9, *;q=0.8", "es" => nil, "fr" => nil)).to eql("es")
      # equal matches sort by position before alphabetical
      expect(ls.infer_browser_locale("en, *", "ar" => nil, "en" => nil)).to eql("en")
    end

    it "handles aliases" do
      expect(ls.infer_browser_locale("zh-TW, *", "zh-TW" => "zh-Hant", "zh-Hant" => nil, "en" => nil)).to eql("zh-Hant")
    end
  end

  context "locale matching" do
    before do
      allow(I18n.config).to receive(:available_locales).and_return(%i[en it es fr de pt zh])
      I18n.config.clear_available_locales_set
      @root_account = Account.create
      @account = Account.create(parent_account: @root_account)
      user_factory
      course_factory
      @course.account = @account
      @course.save
    end

    after do
      I18n.config.clear_available_locales_set
    end

    it "uses the default locale if there is no other context" do
      expect(ls.infer_locale).to eql("en")
      expect(ls.infer_locale(root_account: @root_account)).to eql("en")
      expect(ls.infer_locale(root_account: @root_account, user: @user)).to eql("en")
      expect(ls.infer_locale(root_account: @root_account, user: @user, context: @course)).to eql("en")
    end

    it "infers the locale from the accept_language" do
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account)).to eql("it")
      expect(@user.browser_locale).to be_nil
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user)).to eql("it")
      expect(@user.browser_locale).to eql("it")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @account)).to eql("it")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @course)).to eql("it")
    end

    it "infers the locale from the root account" do
      @root_account.update_attribute(:default_locale, "es")

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user)).to eql("es")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @account)).to eql("es")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @course)).to eql("es")
    end

    it "infers the locale from the account" do
      @root_account.update_attribute(:default_locale, "es")
      @account.update_attribute(:default_locale, "fr")

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user)).to eql("es")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @account)).to eql("fr")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @course)).to eql("fr")
    end

    it "infers the locale from the user" do
      @root_account.update_attribute(:default_locale, "es")
      @account.update_attribute(:default_locale, "fr")
      @user.update_attribute(:locale, "de")

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user)).to eql("de")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @account)).to eql("de")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @course)).to eql("de")
    end

    it "ignores bogus locales" do
      @root_account.update_attribute(:default_locale, "es")
      @account.update_attribute(:default_locale, "fr")
      allow(@user).to receive(:locale).and_return("bogus")

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user)).to eql("es")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @account)).to eql("fr")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @course)).to eql("fr")
    end

    it "infers the locale from the course" do
      @root_account.update_attribute(:default_locale, "es")
      @account.update_attribute(:default_locale, "fr")
      @user.update_attribute(:locale, "de")
      @course.update_attribute(:locale, "pt")

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user)).to eql("de")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @account)).to eql("de")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: @course)).to eql("pt")
    end

    it "infers the locale of a group from the group's context" do
      @course.update_attribute(:locale, "es")
      course_gc = @course.group_categories.create!(name: "Discussion Groups")
      course_gr = Group.create!(name: "Group 1", group_category: course_gc, context: @course)

      @account.update_attribute(:default_locale, "fr")
      account_gc = @account.group_categories.create!(name: "Other Groups")
      account_gr = Group.create!(name: "Group 1", group_category: account_gc, context: @account)

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: account_gr)).to eql("fr")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, user: @user, context: course_gr)).to eql("es")
    end

    it "infers the locale from the session" do
      @root_account.update_attribute(:default_locale, "es")
      @account.update_attribute(:default_locale, "fr")
      @user.update_attribute(:locale, "de")

      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, context: @account, session_locale: "zh")).to eql("zh")
      expect(ls.infer_locale(accept_language: "it", root_account: @root_account, context: @account, user: @user, session_locale: "zh")).to eql("de")
    end
  end

  describe "available_locales" do
    it "does not include custom locales" do
      allow(I18n).to receive(:available_locales).and_return([:en, :ja])
      allow(I18n).to receive(:t).with(:locales, locale: :en).and_return(en: "English")
      allow(I18n).to receive(:t).with(:custom, locale: :en).and_return(nil)
      allow(I18n).to receive(:t).with(:locales, locale: :ja).and_return(ja: "Japanese")
      allow(I18n).to receive(:t).with(:custom, locale: :ja).and_return(true)
      expect(ls.available_locales).to eq("en" => "English")

      ps = PluginSetting.new(name: "i18n", settings: { "ja" => true })
      allow(Canvas::Plugin).to receive(:find).with(:i18n).and_return(ps)
      expect(ls.available_locales).to eq("en" => "English", "ja" => "Japanese")
    end
  end
end
