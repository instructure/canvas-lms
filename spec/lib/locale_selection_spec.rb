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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocaleSelection do
  class TestClassForMixins
    extend LocaleSelection
  end

  def ls
    TestClassForMixins
  end

  context 'accept-language' do
    it "should ignore malformed accept-language headers" do
      ls.infer_browser_locale("en not valid", ['en']).should be_nil
    end

    it "should match valid locale ranges" do
      ls.infer_browser_locale("en", ['en']).should eql('en')
    end

    it "should not match invalid locale ranges" do
      ls.infer_browser_locale("it", ['en']).should be_nil
    end

    it "should do case-insensitive matching" do
      ls.infer_browser_locale("en-us", ['en-US']).should eql('en-US')
    end

    # see rfc2616 ... en means any en(-.*)? is acceptable
    it "should do range prefix-matching" do
      ls.infer_browser_locale("en", ['en-US']).should eql('en-US')
    end

    # while tag prefix-matching might be desirable (sometimes), it should not
    # be done automatically on the server-side (though the user-agent can do
    # it). from the rfc:
    #   [U]sers might [incorrectly] assume that on selecting "en-gb", they
    #   will be served any kind of English document if British English is not
    #   available. A user agent might suggest in such a case to add "en" to
    #   get the best matching behavior.
    it "should not do tag prefix-matching" do
      ls.infer_browser_locale("en-US", ['en']).should be_nil
    end

    it "should assign quality values based on the best match" do
      ls.infer_browser_locale("en-US, es;q=0.9, en;q=0.8", ['en-US', 'es']).should eql('en-US')

      # no tag prefix-matching
      ls.infer_browser_locale("en-US, es;q=0.9, en;q=0.8", ['en', 'es']).should eql('es')

      # order doesn't matter
      ls.infer_browser_locale("es;q=0.9, en", ['en', 'es']).should eql('en')

      # although the en range matches the en-US tag, the en-US range is
      # a better (read: longer) match. so the es tag ends up with a higher
      # quality value than en-US tag
      ls.infer_browser_locale("en, es;q=0.9, en-US;q=0.8", ['en-US', 'es']).should eql('es')
    end

    it "should understand wildcards" do
      ls.infer_browser_locale("*, pt;q=0.8", ['ru', 'pt']).should eql('ru')
      ls.infer_browser_locale("*, pt;q=0.8, ru;q=0.7", ['ru', 'pt']).should eql('pt')
      # the pt range is explicitly rejected, so we don't get a locale
      ls.infer_browser_locale("pt-BR, *;q=0.9, pt;q=0", ['pt']).should be_nil
      # no pt variants supported, so we get the first alternative
      ls.infer_browser_locale("pt-BR, pt;q=0.9, *;q=0.8", ['es', 'fr']).should eql('es')
      # equal matches sort by position before alphabetical
      ls.infer_browser_locale("en, *", ['ar', 'en']).should eql('en')
    end
  end

  context "locale matching" do
    before do
      I18n.stubs(:available_locales).returns([:en, :it, :es, :fr, :de, :pt, :zh])
      @root_account = Account.create
      @account = Account.create(:parent_account => @root_account)
      user
      course
      @course.account = @account
      @course.save
    end

    it "should use the default locale if there is no other context" do
      ls.infer_locale.should eql('en')
      ls.infer_locale(:root_account => @root_account).should eql('en')
      ls.infer_locale(:root_account => @root_account, :user => @user).should eql('en')
      ls.infer_locale(:root_account => @root_account, :user => @user, :context => @course).should eql('en')
    end

    it "should infer the locale from the accept_language" do
      ls.infer_locale(:accept_language => "it", :root_account => @root_account).should eql('it')
      @user.browser_locale.should be_nil
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user).should eql('it')
      @user.browser_locale.should eql('it')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @account).should eql('it')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @course).should eql('it')
    end

    it "should infer the locale from the root account" do
      @root_account.update_attribute(:default_locale, 'es')

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user).should eql('es')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @account).should eql('es')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @course).should eql('es')
    end

    it "should infer the locale from the account" do
      @root_account.update_attribute(:default_locale, 'es')
      @account.update_attribute(:default_locale, 'fr')

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user).should eql('es')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @account).should eql('fr')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @course).should eql('fr')
    end

    it "should infer the locale from the user" do
      @root_account.update_attribute(:default_locale, 'es')
      @account.update_attribute(:default_locale, 'fr')
      @user.update_attribute(:locale, 'de')

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user).should eql('de')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @account).should eql('de')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @course).should eql('de')
    end

    it "should ignore bogus locales" do
      @root_account.update_attribute(:default_locale, 'es')
      @account.update_attribute(:default_locale, 'fr')
      @user.stubs(:locale).returns('bogus')

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user).should eql('es')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @account).should eql('fr')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @course).should eql('fr')
    end

    it "should infer the locale from the course" do
      @root_account.update_attribute(:default_locale, 'es')
      @account.update_attribute(:default_locale, 'fr')
      @user.update_attribute(:locale, 'de')
      @course.update_attribute(:locale, 'pt')

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user).should eql('de')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @account).should eql('de')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => @course).should eql('pt')
    end

    it "should infer the locale of a group from the group's context" do
      @course.update_attribute(:locale, 'es')
      course_gc = @course.group_categories.create!(:name => "Discussion Groups")
      course_gr = Group.create!(:name => "Group 1", :group_category => course_gc, :context => @course)

      @account.update_attribute(:default_locale, 'fr')
      account_gc = @account.group_categories.create!(:name => "Other Groups")
      account_gr = Group.create!(:name => "Group 1", :group_category => account_gc, :context => @account)

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => account_gr).should eql('fr')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :user => @user, :context => course_gr).should eql('es')
    end

    it "should infer the locale from the session" do
      @root_account.update_attribute(:default_locale, 'es')
      @account.update_attribute(:default_locale, 'fr')
      @user.update_attribute(:locale, 'de')

      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :context => @account, :session_locale => 'zh').should eql('zh')
      ls.infer_locale(:accept_language => "it", :root_account => @root_account, :context => @account, :user => @user, :session_locale => 'zh').should eql('de')
    end
  end
end
