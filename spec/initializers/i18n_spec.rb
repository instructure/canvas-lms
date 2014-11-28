require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe I18n do
  describe '.qualified_locale' do
    it 'should return the qualified locale for the given locale' do
      I18n.locale = :fr
      expect(I18n.qualified_locale).to eq 'fr-FR'
    end

    it 'should return en-US for a locale without a qualified locale' do
      I18n.backend.stub lolz: {key: "text"} do
        I18n.locale = :lolz
        expect(I18n.qualified_locale).to eq 'en-US'
      end
    end
  end
end
