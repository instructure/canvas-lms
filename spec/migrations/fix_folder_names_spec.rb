require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::FixFolderNames' do
  it "should work" do
    course_factory
    root = Folder.root_folders(@course).first
    ok_folder = root.sub_folders.create!(:name => "test", :context => @course)
    bad_folder = root.sub_folders.create!(:name => "test 2", :context => @course)
    Folder.where(:id => bad_folder).update_all(:name => "test ")

    DataFixup::FixFolderNames.run

    bad_folder.reload
    expect(bad_folder.name).to eq "test 2" # de-dups the name
  end
end
