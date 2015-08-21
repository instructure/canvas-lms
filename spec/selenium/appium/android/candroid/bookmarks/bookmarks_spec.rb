require_relative 'bookmarks_common'

describe 'bookmarks and internal routing' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'candroid'
  include_context 'course with a single user', 'student', 'candroid'

  # uses *bookmark_original_label* for creating a new bookmark
  # uses *bookmark_edited_label* for editing and deleting bookmarks
  context 'navigated to a page that can be bookmarked' do
    before(:each) do
      navigate_to('Course_Grades')
      click_add_bookmark
    end

    it 'displays new bookmark view', priority: "1", test_id: 369240 do
      expect(text_exact('Add Bookmark')).to be_truthy
      expect(textfield_exact('Label')).to be_truthy
      expect(text_exact('Cancel')).to be_truthy
      expect(text_exact('Done')).to be_truthy
      text_exact('Cancel').click
    end

    it 'does not create invalid bookmarks', priority: "1", test_id: 369241 do
      # A label was not entered; bookmarks without a label are invalid
      find_element(:id, 'buttonDefaultPositive').click

      # Bookmarks page displays 'Create a bookmark' if user has no bookmarks
      navigate_to('Bookmarks')
      expect(text('Create a bookmark')).to be_truthy
      back # TODO: remove *back* when new navigation framework is complete
    end

    it 'creates a new bookmark to course grades', priority: "1", test_id: 208761 do
      find_element(:id, 'bookmarkEditText').send_keys(bookmark_original_label)
      find_element(:id, 'buttonDefaultPositive').click
      verify_bookmark(bookmark_original_label)
    end
  end

  context 'navigated to bookmarks page' do
    before(:each) do
      navigate_to('Bookmarks')
    end

    it 'displays bookmark options', priority: "1", test_id: 369242 do
      # Tap the vertical ellipsis to display 'Edit' and 'Delete' options
      get_more_options(text_exact(bookmark_original_label)).click
      expect(text_exact('Edit')).to be_truthy
      expect(text_exact('Delete')).to be_truthy

      # Close the Bookmark Options by tapping 'Back Button'
      back
    end

    it 'displays a bookmark edit view', priority: "1", test_id: 369243 do
      # Tap the vertical ellipsis to display 'Edit' and 'Delete' options
      click_bookmark_option(text_exact(bookmark_original_label), 'Edit')
      expect(find_element(:id, 'title').text).to eq('Edit Bookmark')
      expect(find_element(:id, 'bookmarkEditText').text).to eq(bookmark_original_label)
      expect(text_exact('Done')).to be_truthy

      # Close the Bookmark Options by tapping 'Back Button'
      back
    end

    it 'displays a bookmark delete view', priority: "1", test_id: 369244 do
      # Tap the vertical ellipsis to display 'Edit' and 'Delete' options
      click_bookmark_option(text_exact(bookmark_original_label), 'Delete')
      expect(find_element(:id, 'title').text).to eq('Remove Bookmark?')
      expect(find_element(:id, 'content').text).to eq(bookmark_original_label)
      expect(text_exact('No')).to be_truthy
      expect(text_exact('Yes')).to be_truthy

      # Close the Bookmark Options by tapping 'Back Button'
      back
    end

    it 'edits the bookmark label', priority: "1", test_id: 209406 do
      click_bookmark_option(text_exact(bookmark_original_label), 'Edit')

      # Make the edit
      find_element(:id, 'bookmarkEditText').send_keys(bookmark_edited_label)
      expect(find_element(:id, 'bookmarkEditText').text).to eq(bookmark_edited_label)
      text_exact('Done').click
      expect(exists{ text_exact(bookmark_original_label) }).to be false
      verify_bookmark(bookmark_edited_label)
    end

    it 'closes the \'Remove Bookmark?\' dialogue', priority: "1", test_id: 369245 do
      cancel_delete(text_exact(bookmark_edited_label), 'No')
      verify_bookmark(bookmark_edited_label)
    end

    it 'closes the \'Remove Bookmark?\' dialogue when using back button', priority: "1", test_id: 369246 do
      cancel_delete(text_exact(bookmark_edited_label), 'Back')
      verify_bookmark(bookmark_edited_label)
    end

    it 'deletes the bookmark', priority: "1", test_id: 209422 do
      click_bookmark_option(text_exact(bookmark_edited_label), 'Delete')
      text_exact('Yes').click
      expect(exists{ text_exact(bookmark_edited_label) }).to be false
    end
  end
end
