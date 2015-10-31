require_relative '../../helpers/android_common'

def bookmark_original_label
  'goto_Course_Grades'
end

def bookmark_edited_label
  'my_Grades'
end

def bookmark_routing_target
  'Grades'
end

def click_add_bookmark
  find_ele_by_attr('tag', 'android.widget.ImageView', 'name', /(More options)/).click
  text_exact('Add Bookmark').click
end

# Multiple elements may exist with the same resource id.
# This chooses the element which is vertically aligned with the bookmark text.
def get_more_options(bookmark)
  ids('overflowRipple').each do |more_options|
    return more_options if more_options.location.y <= bookmark.location.y + bookmark.size.height / 4
  end
  raise('Unable to find more options button for bookmark.')
end

# Selects either 'Edit' or 'Delete' option on a given bookmark object
def click_bookmark_option(bookmark, option)
  navigate_to('Bookmarks') unless exists{ text_exact('Bookmarks') }
  get_more_options(bookmark).click
  if option == 'Edit' || option == 'Delete'
    text_exact(option).click
  else
    raise('Unsupported bookmark feature')
  end
end

# When deleting a bookmark, the user may decide to cancel the deletion.
# This provides two ways to cancel, press 'back' or tap 'No'
def cancel_delete(bookmark, option)
  click_bookmark_option(bookmark, 'Delete')
  if option == 'No'
    text_exact('No').click
  elsif option == 'Back'
    back
  else
    raise('Unsupported bookmark feature')
  end
  expect(exists{ text_exact('Remove Bookmark?') }).to be false
end

def verify_bookmark(bookmark_title)
  navigate_to('Bookmarks')
  wait_true(timeout: 10, interval: 0.100){ text_exact('Bookmarks') }

  # Check routing
  find_ele_by_attr('id', 'title', 'text', /(#{bookmark_title})/).click
  expect(exists(1){ text_exact(bookmark_routing_target) }).to be true
  expect(exists{ text_exact('Bookmarks') }).to be false

  # Check back-stack, returns to 'Bookmarks'
  back
  expect(exists(1){ text_exact(bookmark_routing_target) }).to be false
  expect(exists{ text_exact('Bookmarks') }).to be true
end