require_relative '../common'
require_relative 'groups_common'
require_relative 'shared_examples_common'

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================
shared_examples 'home_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should display a coming up section with relevant events", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273602, teacher: 319909) do
    # Create an event to have something in the Coming up Section
    event = @testgroup[0].calendar_events.create!(title: "ohai",
                                                  start_at: Time.zone.now + 1.day)
    get url

    expect('.coming_up').to be_present
    expect(ff('.coming_up .event a').size).to eq 1
    expect(f('.coming_up .event a b')).to include_text("#{event.title}")
  end

  it "should display a view calendar link on the group home page", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273603, teacher: 319910) do
    get url
    expect(f('.event-list-view-calendar')).to be_displayed
  end

  it "should have a working link to add an announcement from the group home page", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273604, teacher: 319911) do
    get url
    expect_new_page_load { fln('Announcement').click }
    expect(f('.btn-primary')).to be_displayed
  end

  it "should display recent activity feed on the group home page", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273605, teacher: 319912) do
    DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                            title: 'Discussion Topic', message: 'test')
    @testgroup.first.announcements.create!(title: 'Test Announcement', message: 'Message',user: @teacher)

    get url
    expect(f('.recent-activity-header')).to be_displayed
    activity = ff('.stream_header .title')
    expect(activity.size).to eq 2
    expect(activity[0]).to include_text('1 Announcement')
    expect(activity[1]).to include_text('1 Discussion')
  end

  it "should display announcements on the group home page feed", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273609, teacher: 319913) do
    @testgroup.first.announcements.create!(title: 'Test Announcement', message: 'Message',user: @teacher)
    get url
    expect(f('.title')).to include_text('1 Announcement')
    f('.toggle-details').click
    expect(f('.content_summary')).to include_text('Test Announcement')
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'announcements_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should center the add announcement button if no announcements are present", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273606, teacher: 324936) do
    get announcements_page
    expect(f('#content div')).to have_attribute(:style, 'text-align: center;')
    expect(f('.btn.btn-large.btn-primary')).to be_displayed
  end

  it "should list all announcements", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273608, teacher: 324935) do
    # Create 5 announcements in the group
    announcements = []
    5.times do |n|
      announcements << @testgroup.first.announcements.create!(title: "Announcement #{n+1}", message: "Message #{n+1}",user: @teacher)
    end

    get announcements_page
    expect(ff('.discussion-topic').size).to eq 5
  end

  it "should only list in-group announcements in the content right pane", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273621, teacher: 324934) do
    # create group and course announcements
    @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
    @course.announcements.create!(title: 'Course Announcement', message: 'Course',user: @teacher)

    get announcements_page
    expect_new_page_load { f('.btn-primary').click }
    fj(".ui-accordion-header a:contains('Announcements')").click
    expect(fln('Group Announcement')).to be_displayed
    expect(f("#content")).not_to contain_link('Course Announcement')
  end

  it "should only access group files in announcements right content pane", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273624, teacher: 324931) do
    add_test_files
    get announcements_page
    expect_new_page_load { f('.btn-primary').click }
    expand_files_on_content_pane
    expect(ffj('.file .text:visible').size).to eq 1
  end

  it "should have an Add External Feed link on announcements", priority: "2", test_id: pick_test_id(context, student: 329628, teacher: 329629) do
    get announcements_page
    expect(fln('Add External Feed')).to be_displayed
  end

  it "should have an RSS feed button on announcements", priority: "2", test_id: pick_test_id(context, student: 329630, teacher: 329631) do
    @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
    get announcements_page
    expect(f('.btn[title="RSS feed"]')).to be_displayed
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'pages_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should load pages index and display all pages", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273610, teacher: 324927) do
    @testgroup.first.wiki.wiki_pages.create!(title: "Page 1", user: @teacher)
    @testgroup.first.wiki.wiki_pages.create!(title: "Page 2", user: @teacher)
    get pages_page
    expect(ff('.collectionViewItems .clickable').size).to eq 2
  end

  it "should only list in-group pages in the content right pane", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273620, teacher: 324928) do
    # create group and course announcements
    group_page = @testgroup.first.wiki.wiki_pages.create!(user: @teacher,
                                                          title: 'Group Page')
    course_page = @course.wiki.wiki_pages.create!(user: @teacher,
                                                  title: 'Course Page')

    get pages_page
    f('.btn-primary').click
    wait_for_ajaximations
    fj(".ui-accordion-header a:contains('Wiki Pages')").click
    expect(fln("#{group_page.title}")).to be_displayed
    expect(f("#content")).not_to contain_link("#{course_page.title}")
  end

  it "should only access group files in pages right content pane", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 303700, teacher: 324932) do
    add_test_files
    get pages_page
    f('.btn-primary').click
    wait_for_ajaximations
    expand_files_on_content_pane
    expect(ffj('.file .text:visible').size).to eq 1
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'people_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should allow group users to see group registered services page", priority: pick_priority(context, student: "1", teacher: "2"),test_id: pick_test_id(context, student: 323329, teacher: 324926) do
    get people_page
    expect_new_page_load do
      f("#people-options .Button").click
      fln('View Registered Services').click
    end
    # Checks that we are on the Registered Services page
    expect(f('.btn.button-sidebar-wide')).to be_displayed
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'discussions_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should only list in-group discussions in the content right pane", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273622, teacher: 324930) do
    # create group and course announcements
    group_dt = DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                                       title: 'Group Discussion', message: 'Group')
    course_dt = DiscussionTopic.create!(context: @course, user: @teacher,
                                        title: 'Course Discussion', message: 'Course')

    get discussions_page
    expect_new_page_load { f('.btn-primary').click }
    fj(".ui-accordion-header a:contains('Discussions')").click
    expect(fln("#{group_dt.title}")).to be_displayed
    expect(f("#content")).not_to contain_link("#{course_dt.title}")
  end

  it "should only access group files in discussions right content pane", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 303701, teacher: 324933) do
    add_test_files
    get discussions_page
    expect_new_page_load { f('.btn-primary').click }
    expand_files_on_content_pane
    expect(ffj('.file .text:visible').size).to eq 1
  end

  it "should allow group users to reply to group discussions", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 312868, teacher: 312870) do
    DiscussionTopic.create!(context: @testgroup.first, user: @teacher,
                            title: 'Group Discussion', message: 'Group')
    get discussions_page
    fln('Group Discussion').click
    wait_for_ajaximations
    f('.discussion-reply-action').click
    type_in_tiny('textarea', 'Good discussion')
    fj('.btn-primary:contains("Post Reply")').click
    wait_for_ajaximations
    expect(f('.entry')).to be_present
    expect(ff('.message.user_content')[1]).to include_text 'Good discussion'
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'files_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should allow group users to rename a file", priority: "2", test_id: pick_test_id(context, student: 312869, teacher: 315577) do
    add_test_files
    get files_page
    edit_name_from_cog_icon('cool new name')
    wait_for_ajaximations
    expect(fln('cool new name')).to be_present
  end

  it "should search files only within the scope of a group", priority: pick_priority(context, student: "1", teacher: "2"), test_id: pick_test_id(context, student: 273627, teacher: 324937) do
    add_test_files
    get files_page
    f('input[type="search"]').send_keys 'example.pdf'
    driver.action.send_keys(:return).perform
    refresh_page
    # This checks to make sure there is only one file and it is the group-level one
    expect(all_files_folders.count).to eq 1
    expect(ff('.ef-name-col__text').first).to include_text('example.pdf')
  end
end

#-----------------------------------------------------------------------------------------------------------------------
shared_examples 'conferences_page' do |context|
  include GroupsCommon
  include SharedExamplesCommon

  it "should allow group users to create a conference", priority: pick_priority(context, student: "1", teacher: "2"),test_id: pick_test_id(context, student: 307624, teacher: 308534) do
    skip_if_chrome('issue with invite_all_but_one_user method')
    title = 'test conference'
    get conferences_page
    create_conference(title: title)
    expect(f('#new-conference-list .ig-title').text).to include(title)
  end

  it "should allow group users to delete an active conference", priority: pick_priority(context, student: "1", teacher: "2"),test_id: pick_test_id(context, student: 323557, teacher: 323558) do
    WimbaConference.create!(title: "new conference", user: @user, context: @testgroup.first)
    get conferences_page

    delete_conference
    expect(f('#new-conference-list')).to include_text('There are no new conferences')
  end

  it "should allow group users to delete a concluded conference", priority: pick_priority(context, student: "1", teacher: "2"),test_id: pick_test_id(context, student: 323559, teacher: 323560) do
    cc = WimbaConference.create!(title: "cncluded conference", user: @user, context: @testgroup.first)
    conclude_conference(cc)
    get conferences_page

    delete_conference
    expect(f('#concluded-conference-list')).to include_text('There are no concluded conferences')
  end
end
