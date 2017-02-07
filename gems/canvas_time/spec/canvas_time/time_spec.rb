require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CanvasTime do

  around do |example|
    Timecop.freeze(Time.zone.local(2010,10,1,0,0), &example)
  end

  describe "fancy_midnight" do
    it "returns the given date at 11:59pm if date is at 12:00 am" do
      time = Time.zone.now
      expect(CanvasTime.fancy_midnight(time)).to eq(time.end_of_day)
    end

    it "returns the given date if the date is not at 12:00 am" do
      time = Time.zone.now - 1.second
      expect(CanvasTime.fancy_midnight(time)).to eq(time)
    end

    it "works on a daylight savings boundary" do
      Time.use_zone('Alaska') do
        time = Time.zone.parse('2013-03-10T00:00:00')
        expect(CanvasTime.fancy_midnight(time).to_i).
          to eq(Time.zone.parse('2013-03-10T23:59:59').to_i)
      end
    end

    it "returns nil when passed nil" do
      expect(CanvasTime.fancy_midnight(nil)).to eq(nil)
    end
  end

  describe "#is_fancy_midnight" do

    it "returns true if hour is 23 and min is 59" do
      time = Time.now.end_of_day
      expect(CanvasTime.is_fancy_midnight?(time)).to eq(true)
    end

    it "returns false if hour is 23 but min isn't 59" do
      time = Time.now.end_of_day - 1.minute
      expect(CanvasTime.is_fancy_midnight?(time)).to eq(false)
    end

    it "returns false if hour isn't 23" do
      expect(CanvasTime.is_fancy_midnight?(Time.now)).to eq(false)
    end

    it "returns false for nil" do
      expect(CanvasTime.is_fancy_midnight?(nil)).to eq(false)
    end
  end

  describe ".try_parse" do
    it "converts a string into a time" do
      parsed_time = Time.zone.parse("2012-12-12 12:12:12 -0600")
      expect(CanvasTime.try_parse("2012-12-12 12:12:12 -0600")).to eq(parsed_time)
    end

    it "uses Time.zone.parse for proper timezone handling" do
      parsed_time = Time.zone.parse("2012-12-12 12:12:12")
      expect(CanvasTime.try_parse("2012-12-12 12:12:12")).to eq(parsed_time)
    end

    it "returns nil when no default is provided and time does not parse" do
      expect(CanvasTime.try_parse("NOT A TIME")).to be_nil
      expect(CanvasTime.try_parse("-45-45-45 12:12:12")).to be_nil
    end

    it "returns the provided default if it is provided and the time does not parse" do
      expect(CanvasTime.try_parse("NOT A TIME", :default)).to eq(:default)
      expect(CanvasTime.try_parse("-45-45-45 12:12:12", :default)).to eq(:default)
    end
  end

end
