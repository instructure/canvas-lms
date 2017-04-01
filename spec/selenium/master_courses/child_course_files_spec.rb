require_relative '../common'

describe "master courses - child courses - file locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @filename = 'file.txt'
    @original_file = Attachment.create!(:filename => @filename, :uploaded_data => StringIO.new('1'),
      :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
    @tag = @template.create_content_tag_for!(@original_file)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    @file_copy = Attachment.create!(:filename => @filename, :uploaded_data => StringIO.new('1'),
      :folder => Folder.root_folders(@copy_to).first, :context => @copy_to, :migration_id => @tag.migration_id)
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the manageable cog-menu options when a file is locked" do
    @tag.update_attribute(:restrictions, {:all => true})

    get "/courses/#{@copy_to.id}/files"

    expect(f('.ef-item-row .master-course-cell')).to contain_css('.icon-lock')

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to_not contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to_not include("Delete")
  end

  it "should not show the manageable cog-menu options when a folder contains a locked file" do
    subfolder = Folder.root_folders(@copy_to).first.sub_folders.create!(:name => "subfolder", :context => @copy_to)
    @file_copy.folder = subfolder
    @file_copy.save!
    @tag.update_attribute(:restrictions, {:all => true})

    get "/courses/#{@copy_to.id}/files"

    expect(f('.ef-item-row .ef-name-col').text).to include("subfolder") # we're looking at the folder right?
    expect(f('.ef-item-row .master-course-cell')).to contain_css('.icon-lock')

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to_not contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to_not include("Delete")
  end

  it "should show the manageable cog-menu options when a file is unlocked" do
    get "/courses/#{@copy_to.id}/files"

    expect(f('.ef-item-row .master-course-cell')).to contain_css('.icon-unlock')

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to include("Delete")
  end

  it "should show the manageable cog-menu options when a folder contains an unlocked file" do
    subfolder = Folder.root_folders(@copy_to).first.sub_folders.create!(:name => "subfolder", :context => @copy_to)
    @file_copy.folder = subfolder
    @file_copy.save!
    get "/courses/#{@copy_to.id}/files"

    f('.ef-item-row .ef-date-created-col').click # select the file
    expect(f('.ef-header')).to contain_css('.btn-delete')

    f('.ef-item-row .al-trigger').click
    expect(f('.al-options').text).to include("Delete")
  end
end
