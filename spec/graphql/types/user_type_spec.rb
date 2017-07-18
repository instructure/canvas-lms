require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::UserType do
  let_once(:user) { student_in_course(active_all: true); @student }
  let(:user_type) { GraphQLTypeTester.new(Types::UserType, user) }

  it "works" do
    expect(user_type._id).to eq user.id
    expect(user_type.name).to eq "User"
  end

  context "avatarUrl" do
    it "is nil when avatars are not enabled" do
      expect(user_type.avatarUrl).to be_nil
    end

    it "returns an avatar url when avatars are enabled" do
      user.account.enable_service(:avatars)
      expect(user_type.avatarUrl).to match /avatar.*png/
    end
  end
end
