require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')

describe Qti::AssessmentTestConverter do
  it "should interpret duration strings that include units" do
    assess = Qti::AssessmentTestConverter

    minutes_in_hour = 60
    minutes_in_day = 24 * minutes_in_hour

    assess.parse_time_limit("D1").should == minutes_in_day
    assess.parse_time_limit("d2").should == 2 * minutes_in_day
    assess.parse_time_limit("H4").should == 4 * minutes_in_hour
    assess.parse_time_limit("h1").should == minutes_in_hour
    assess.parse_time_limit("M120").should == 120
    assess.parse_time_limit("m14").should == 14

    #Canvas uses minutes, QTI uses seconds
    assess.parse_time_limit("60").should == 1
    assess.parse_time_limit("3600").should == 60
  end
end
