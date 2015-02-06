require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ToursController do

  before :each do
    Tour.tour(:fake_tour, 1, 'users#index')
    user(:active_all => true)
    user_session(@user)
  end

  it "should add dismissed tours to user preferences" do
    expect(@user.preferences[:dismissed_tours]).to be_nil
    delete 'dismiss', :name => 'FakeTour'
    @user.reload
    expect(@user.preferences[:dismissed_tours]).to eq({:fake_tour => 1})
  end

  it "should override old dismissed tours with new versions" do
    # set version one back as though the user dismissed v0 already
    @user.preferences[:dismissed_tours] = {:fake_tour => 0}
    expect(@user.preferences[:dismissed_tours]).to eq({:fake_tour => 0})
    delete 'dismiss', :name => 'FakeTour'
    @user.reload
    # :fake_tour should be the current version (1) not the old version (0)
    expect(@user.preferences[:dismissed_tours]).to eq({:fake_tour => 1})
  end

  it "should add dismissed tours to user session" do
    delete 'dismiss_session', :name => 'FakeTour'
    expect(request.session[:dismissed_tours]).to eq({:fake_tour => 1})
  end

end

