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

  describe "numbers" do
    it "formats count" do
      expect(I18n.t({one: "1 thing", other: "%{count} things"}, {count: 1500})).to eq '1,500 things'
    end

    it "formats interpolated numbers" do
      expect(I18n.t("user count: %{foo}", {foo: 1500})).to eq "user count: 1,500"
    end

    it "does not format numbery strings" do
      expect(I18n.t("user count: %{foo}", {foo: "1500"})).to eq "user count: 1500"
    end

    it "does not mutate the options" do
      options = {foo: 1500}
      I18n.t("user count: %{foo}", options)
      expect(options[:foo]).to eq 1500
    end
  end

  describe ".n" do
    before do
      format = {
        delimiter: '_',
        separator: ',',
        precision: 3,
        format: '%n %'
      }
      allow(I18n).to receive(:translate).with(:'number.format', anything).and_return(format)
      allow(I18n).to receive(:translate).with(:'number.percentage.format', anything).and_return(format)
      allow(I18n).to receive(:translate).with(:'number.precision.format', anything).and_return(format)
    end

    context "without precision" do
      it "uses delimiter" do
        expect(I18n.n(1000)).to eq "1_000"
      end

      it "uses separator" do
        expect(I18n.n(100.56)).to eq "100,56"
      end
    end

    context "with precision" do
      it "uses delimiter" do
        expect(I18n.n(1000, precision: 2)).to eq "1_000,00"
      end

      it "truncates overly precise input" do
        expect(I18n.n(1000.2345, precision: 2)).to eq "1_000,23"
      end
    end

    context "percentage" do
      it "formats without precision" do
        expect(I18n.n(76.6, percentage: true)).to eq "76,6 %"
      end

      it "formats with precision" do
        expect(I18n.n(76.6, precision: 2, percentage: true)).to eq "76,60 %"
      end

      it "has a max precision of 5 by default" do
        expect(I18n.n(100.567891, percentage: true)).to eq "100,56789 %"
      end
    end
  end
end
