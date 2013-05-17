require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20130122193536_remove_multiple_root_folders'


describe 'DataFixup::RemoveMultipleRootFolders' do
  self.use_transactional_fixtures = false

  def get_root_folder_name(context)
    if context.is_a? Course
      root_folder_name = Folder::ROOT_FOLDER_NAME
    elsif context.is_a? User
      root_folder_name = Folder::MY_FILES_FOLDER_NAME
    else
      root_folder_name = "files"
    end
    root_folder_name
  end

  before :each do
    RemoveMultipleRootFolders.down

    @contexts = []

    12.times do |x|
      case x % 4
        when 0
          context = course
        when 1
          context = user
        when 2
          context = group
        when 3
          context = Account.create!
      end
      @contexts << context
    end
  end

  after :each do
    @contexts.each do |c|
      c.folders.each do |f|
        f.attachments.delete_all
      end
      c.folders.scoped.delete_all
      c.delete
    end
    RemoveMultipleRootFolders.up
  end

  it "should remove extra root folders if they are empty" do
    empty_folders = []

    @contexts.each do |context|
      Folder.root_folders(context)
      empty_folders << context.folders.create!(:name => "name1")
      empty_folders << context.folders.create!(:name => "name2")
      empty_folders << context.folders.create!(:name => "name3")

      scope = Folder.where(:context_type => context.class.to_s, :context_id => context)
      scope.update_all(:parent_folder_id => nil)

      scope.where("workflow_state<>'deleted' AND parent_folder_id IS NULL").count.should == 4
    end

    DataFixup::RemoveMultipleRootFolders.run(:limit => 2)

    @contexts.each do |c|
      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
        c.class.to_s, c).count.should == 1
    end

    empty_folders.each do |folder|
      folder.reload
      folder.workflow_state.should == 'deleted'
    end
  end

  it "should move extra root folders to one root folder if they are not empty (either a sub-folder or attachment)" do
    extra_folders = []

    @contexts.each do |context|
      Folder.root_folders(context)
      extra_folder1 = context.folders.create!(:name => "name1")
      extra_folders << extra_folder1
      extra_folder1.sub_folders.create!(:name => "name2", :context => context)

      extra_folder2 = context.folders.create!(:name => "name1")
      extra_folders << extra_folder2
      a = extra_folder2.active_file_attachments.build
      a.context = context
      a.uploaded_data = default_uploaded_data
      a.save!

      Folder.where(:id => [extra_folder1, extra_folder2]).update_all(:parent_folder_id => nil)

      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
        context.class.to_s, context).count.should == 3
    end

    DataFixup::RemoveMultipleRootFolders.run(:limit => 2)

    @contexts.each do |c|
      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
        c.class.to_s, c).count.should == 1
    end

    extra_folders.each do |folder|
      folder.reload
      folder.workflow_state.should_not == 'deleted'
      folder.parent_folder_id.should == Folder.root_folders(folder.context).first.id
    end
  end

  it "should move extra root folders to the root folder with the most content" do
    extra_folders = []

    empty_root_folder_ids = []
    root_folder_ids_with_content = []

    @contexts.each do |context|
      root_folder_name = get_root_folder_name(context)

      empty_root_folder = context.folders.create!(:name => root_folder_name)
      empty_root_folder_ids << empty_root_folder.id

      root_folder_with_content = context.folders.create!(:name => root_folder_name)
      root_folder_with_content.sub_folders.create!(:name => "name2", :context => context)
      root_folder_ids_with_content << root_folder_with_content.id

      extra_folder1 = context.folders.create!(:name => "name1")
      extra_folders << extra_folder1
      extra_folder1.sub_folders.create!(:name => "name2", :context => context)

      extra_folder2 = context.folders.create!(:name => "name1")
      extra_folders << extra_folder2
      a = extra_folder2.active_file_attachments.build
      a.context = context
      a.uploaded_data = default_uploaded_data
      a.save!

      Folder.where(:id => [extra_folder1, extra_folder2]).update_all(:parent_folder_id => nil)

      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
                                   context.class.to_s, context).count.should == 4
    end

    DataFixup::RemoveMultipleRootFolders.run(:limit => 2)

    @contexts.each do |c|
      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
                                   c.class.to_s, c).count.should == 1
    end

    extra_folders.each do |folder|
      folder.reload
      folder.workflow_state.should_not == 'deleted'
      folder.parent_folder_id.should == Folder.root_folders(folder.context).first.id
      empty_root_folder_ids.include?(folder.parent_folder_id).should be_false
      root_folder_ids_with_content.include?(folder.parent_folder_id).should be_true
    end
  end

  it "should create a new root folder with the proper name if it doesn't exist already" do
    extra_folders = []

    @contexts.each do |context|
      extra_folder1 = context.folders.create!(:name => "name1")
      extra_folders << extra_folder1
      extra_folder1.sub_folders.create!(:name => "name2", :context => context)

      extra_folder2 = context.folders.create!(:name => "name1")
      extra_folders << extra_folder2
      a = extra_folder2.active_file_attachments.build
      a.context = context
      a.uploaded_data = default_uploaded_data
      a.save!

      root_folder_name = get_root_folder_name(context)
      context.folders.find_by_name(root_folder_name).delete
      context.folders.find_by_name(root_folder_name).should be_nil

      Folder.where(:id => [extra_folder1, extra_folder2]).update_all(:parent_folder_id => nil)

      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
                                   context.class.to_s, context).count.should == 2
    end

    DataFixup::RemoveMultipleRootFolders.run(:limit => 2)

    @contexts.each do |c|
      Folder.where("context_type=? AND context_id=? AND workflow_state<>'deleted' AND parent_folder_id IS NULL",
                                   c.class.to_s, c).count.should == 1

      root_folder_name = get_root_folder_name(c)
      c.folders.find_by_name(root_folder_name).should_not be_nil
    end

    extra_folders.each do |folder|
      folder.reload
      folder.workflow_state.should_not == 'deleted'
      folder.parent_folder_id.should_not be_nil

      root_folder_name = get_root_folder_name(folder.context)
      folder.parent_folder.name.should == root_folder_name
    end
  end
end