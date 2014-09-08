require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe 'ActiveRecord::Associations::CollectionAssociation' do
  it 'should null the scope for new record association scoping' do
    AccessToken.create!(developer_key_id: nil)
    # without the patch, this query will find the record above
    DeveloperKey.new.access_tokens.active.should be_empty
  end
end
