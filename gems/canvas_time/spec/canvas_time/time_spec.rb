require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CanvasTime do

  before { Timecop.freeze(Time.local(2010,10,1,0,0)) }
  after { Timecop.return }

  describe "fancy_midnight" do
    it "returns the given date at 11:59pm if date is at 12:00 am" do
      time = Time.now
      CanvasTime.fancy_midnight(time).should == time.end_of_day
    end

    it "returns the given date if the date is not at 12:00 am" do
      time = Time.now - 1.second
      CanvasTime.fancy_midnight(time).should == time
    end

    it "works on a daylight savings boundary" do
      Time.use_zone('Alaska') do
        time = Time.zone.parse('2013-03-10T00:00:00')
        CanvasTime.fancy_midnight(time).to_i.
          should == Time.zone.parse('2013-03-10T23:59:59').to_i
      end
    end

    it "returns nil when passed nil" do
      CanvasTime.fancy_midnight(nil).should == nil
    end
  end

  describe "#is_fancy_midnight" do

    it "returns true if hour is 23 and min is 59" do
      time = Time.now.end_of_day
      CanvasTime.is_fancy_midnight?(time).should == true
    end

    it "returns false if hour is 23 but min isn't 59" do
      time = Time.now.end_of_day - 1.minute
      CanvasTime.is_fancy_midnight?(time).should == false
    end

    it "returns false if hour isn't 23" do
      CanvasTime.is_fancy_midnight?(Time.now).should == false
    end

    it "returns false for nil" do
      CanvasTime.is_fancy_midnight?(nil).should == false
    end
  end

  describe ".try_parse" do
    it "converts a string into a time" do
      parsed_time = Time.zone.parse("2012-12-12 12:12:12 -0600")
      CanvasTime.try_parse("2012-12-12 12:12:12 -0600").should == parsed_time
    end

    it "uses Time.zone.parse for proper timezone handling" do
      parsed_time = Time.zone.parse("2012-12-12 12:12:12")
      CanvasTime.try_parse("2012-12-12 12:12:12").should == parsed_time
    end

    it "returns nil when no default is provided and time does not parse" do
      CanvasTime.try_parse("NOT A TIME").should be_nil
      CanvasTime.try_parse("-45-45-45 12:12:12").should be_nil
    end

    it "returns the provided default if it is provided and the time does not parse" do
      CanvasTime.try_parse("NOT A TIME", :default).should == :default
      CanvasTime.try_parse("-45-45-45 12:12:12", :default).should == :default
    end
  end

end
