require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ToursController do

  before :each do
    Tour.tour(:fake_tour, 1, 'users#index')
    user(:active_all => true)
    user_session(@user)
  end

  it "should add dismissed tours to user preferences" do
    @user.preferences.should be_empty
    delete 'dismiss', :name => 'FakeTour'
    @user.reload
    @user.preferences[:dismissed_tours].should == {:fake_tour => 1}
  end

  it "should override old dismissed tours with new versions" do
    # set version one back as though the user dismissed v0 already
    @user.preferences[:dismissed_tours] = {:fake_tour => 0}
    @user.preferences[:dismissed_tours].should == {:fake_tour => 0}
    delete 'dismiss', :name => 'FakeTour'
    @user.reload
    # :fake_tour should be the current version (1) not the old version (0)
    @user.preferences[:dismissed_tours].should == {:fake_tour => 1}
  end

  it "should add dismissed tours to user session" do
    delete 'dismiss_session', :name => 'FakeTour'
    request.session[:dismissed_tours].should == {:fake_tour => 1}
  end

end

