require File.expand_path(File.dirname(__FILE__) + '/../common')

def create_assignment(type = 'online_text_entry')
  assignment = @course.assignments.build({
                                             :name => 'media assignment',
                                             :submission_types => type
                                         })
  assignment.workflow_state = 'published'
  assignment.save!
  assignment
end

def create_assignment_and_go_to_page(type = 'online_text_entry')
  assignment = create_assignment type
  get "/courses/#{@course.id}/assignments/#{assignment.id}"
  assignment
end

def open_media_comment_dialog
  f('.media_comment_link').click
  # swf and stuff loads, give it a sec to do its thing
  sleep 0.5
end

def submit_media_comment_1
  open_media_comment_dialog
  # pretend like we are flash sending data to the JS
  driver.execute_script <<-JS
      var entries1 = [{"duration":1.664,"thumbnailUrl":"http://www.instructuremedia.com/p/100/sp/10000/thumbnail/entry_id/0_jd6ger47/version/0","numComments":-1,"status":1,"rank":-1,"userScreenName":"_100_1_1","displayCredit":"_100_1_1","partnerLandingPage":null,"dataUrl":"http://www.instructuremedia.com/p/100/sp/10000/flvclipper/entry_id/0_jd6ger47/version/100000","sourceLink":"","subpId":10000,"puserId":"1_1","views":0,"height":0,"description":null,"hasThumbnail":false,"width":0,"kshowId":"0_pb7id2lf","kuserId":"","userLandingPage":"","mediaType":2,"plays":0,"partnerId":100,"adminTags":"","entryVersion":"","downloadUrl":"http://www.instructuremedia.com/p/100/sp/10000/raw/entry_id/0_jd6ger47/version/100000","createdAtDate":"1970-01-16T09:24:02.931Z","votes":-1,"uploaderName":null,"tags":"","entryName":"ryanf@instructure.com 2012-02-21T16:48:37.729Z","entryType":1,"entryId":"0_jd6ger47","createdAtAsInt":1329842931,"uid":"E78A81CC-D03D-CD10-B449-A0D0D172EF38"}]
      addEntryComplete(entries1)
  JS
  wait_for_ajax_requests
end

def submit_media_comment_2
  open_media_comment_dialog
  driver.execute_script <<-JS
      var entries2 = [{"duration":1.829,"thumbnailUrl":"http://www.instructuremedia.com/p/100/sp/10000/thumbnail/entry_id/0_5hcd9mro/version/0","numComments":-1,"status":1,"rank":-1,"userScreenName":"_100_1_1","displayCredit":"_100_1_1","partnerLandingPage":null,"dataUrl":"http://www.instructuremedia.com/p/100/sp/10000/flvclipper/entry_id/0_5hcd9mro/version/100000","sourceLink":"","subpId":10000,"puserId":"1_1","views":0,"height":0,"description":null,"hasThumbnail":false,"width":0,"kshowId":"0_pb7id2lf","kuserId":"","userLandingPage":"","mediaType":2,"plays":0,"partnerId":100,"adminTags":"","entryVersion":"","downloadUrl":"http://www.instructuremedia.com/p/100/sp/10000/raw/entry_id/0_5hcd9mro/version/100000","createdAtDate":"1970-01-16T09:24:03.563Z","votes":-1,"uploaderName":null,"tags":"","entryName":"ryanf@instructure.com 2012-02-21T16:59:11.249Z","entryType":1,"entryId":"0_5hcd9mro","createdAtAsInt":1329843563,"uid":"22A2C625-5FAB-AF3A-1A76-A0DA7572BFE4"}]
      addEntryComplete(entries2)
  JS
  wait_for_ajax_requests
end

