require File.expand_path(File.dirname(__FILE__) + '/../common')

describe 'developer keys' do
  include_context 'in-process server selenium tests'

  before(:each) do
    course_with_admin_logged_in
  end

  def add_developer_key
    Account.default.developer_keys.create!(name: 'Cool Tool', email: 'admin@example.com', tool_id: 'cool_tool',
                                           redirect_uri: 'http://example.com', icon_url: '/images/delete.png')
  end

  it 'should create without error', priority: "1", test_id: 344077 do
    get "/accounts/#{Account.default.id}/developer_keys"
    expect(ff("#keys tbody tr").length).to eq 0

    f(".add_key").click
    expect(f("#edit_dialog")).to be_displayed
    f("#key_name").send_keys("Cool Tool")
    f("#email").send_keys("admin@example.com")
    f("#tool_id").send_keys("cool_tool")
    f("#redirect_uri").send_keys("http://example.com")
    f("#icon_url").send_keys("/images/delete.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.name).to eq "Cool Tool"
    expect(key.tool_id).to eq "cool_tool"
    expect(key.email).to eq "admin@example.com"
    expect(key.redirect_uri).to eq "http://example.com"
    expect(key.icon_url).to eq "/images/delete.png"
    expect(ff("#keys tbody tr").length).to eq 1
  end

  it 'should update without error', priority: "1", test_id: 344078 do
    add_developer_key
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .edit_link").click
    expect(f("#edit_dialog")).to be_displayed
    replace_content(f("#key_name"), "Cooler Tool")
    replace_content(f("#email"), "admins@example.com")
    replace_content(f("#tool_id"), "cooler_tool")
    replace_content(f("#redirect_uri"), "https://example.com")
    replace_content(f("#icon_url"), "/images/add.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.name).to eq "Cooler Tool"
    expect(key.email).to eq "admins@example.com"
    expect(key.tool_id).to eq "cooler_tool"
    expect(key.redirect_uri).to eq "https://example.com"
    expect(key.icon_url).to eq "/images/add.png"
    expect(ff("#keys tbody tr").length).to eq 1
  end

  it 'should delete without error', priority: "1", test_id: 344079 do
    add_developer_key
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .edit_link").click
    expect(f("#edit_dialog")).to be_displayed
    f("#tool_id").clear
    f("#icon_url").clear
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.tool_id).to eq nil
    expect(key.icon_url).to eq nil
    expect(ff("#keys tbody tr").length).to eq 1

    f("#keys tbody tr.key .delete_link").click
    driver.switch_to.alert.accept
    driver.switch_to.default_content
    keep_trying_until { ff("#keys tbody tr").length == 0 }
    expect(Account.default.developer_keys.nondeleted.count).to eq 0
  end

  it "should be paginated", priority: "1", test_id: 344532 do
    25.times { |i| Account.default.developer_keys.create!(name: "tool #{i}") }
    get "/accounts/#{Account.default.id}/developer_keys"
    expect(f("#loading")).not_to have_class('loading')
    # pagination should load 10 objects by default
    expect(ff("#keys tbody tr").length).to eq 10
    expect(f('#loading')).to have_class('show_more')
    f("#loading .show_all").click
    wait_for_ajaximations
    keep_trying_until do
      expect(f("#loading")).not_to have_class('loading')
      true
    end
    expect(ff("#keys tbody tr").length).to eq 25
  end
end
