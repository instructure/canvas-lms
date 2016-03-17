require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe I18n do
  describe '.bigeasy_locale' do
    it 'does explicit overrides' do
      I18n.locale = :fr
      expect(I18n.bigeasy_locale).to eq 'fr_FR'
    end

    it 'does underscore conversion' do
      I18n.locale = :'en-GB'
      expect(I18n.bigeasy_locale).to eq 'en_GB'
    end
  end

  describe '.moment_locale' do
    it 'does explicit overrides' do
      I18n.locale = :hy
      expect(I18n.moment_locale).to eq 'hy-am'
    end

    it 'does lowercase conversion' do
      I18n.locale = :'en-GB'
      expect(I18n.moment_locale).to eq 'en-gb'
    end
  end

  describe '.fullcalendar_locale' do
    it 'does explicit overrides' do
      I18n.locale = :hy
      expect(I18n.fullcalendar_locale).to eq 'en'
    end

    it 'does lowercase conversion' do
      I18n.locale = :'en-GB'
      expect(I18n.fullcalendar_locale).to eq 'en-gb'
    end
  end

  describe ".i18nliner_scope" do
    it "should be correct for model class and instances" do
      expect(User.i18nliner_scope.scope).to eq "user."
      expect(Group.new.i18nliner_scope.scope).to eq "group."
    end
  end
end
