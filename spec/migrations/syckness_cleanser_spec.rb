require_relative "../spec_helper"

describe DataFixup::SycknessCleanser do
  it "should remove the syckness" do
    user_factory
    @user.preferences = {:bloop => "blah"}
    @user.save!

    old_yaml = User.where(:id => @user).pluck("preferences as y").first
    new_yaml = old_yaml + Syckness::TAG
    User.where(:id => @user).update_all(["preferences = ?", new_yaml])

    DataFixup::SycknessCleanser.run(User, ['preferences'])

    expect(User.where(:id => @user).pluck("preferences as y").first).to eq old_yaml

    DataFixup::SycknessCleanser.run(User, ['preferences']) # make sure it doesn't break anything just in case

    expect(User.where(:id => @user).pluck("preferences as y").first).to eq old_yaml
  end
end
