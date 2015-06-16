# Define all the feature tours in this file with the tour method.
#
# examples:
#
#   tour(:first_time_login, 1, 'users#user_dashboard') {
#     # assuming we have this method, returning true will then initialize
#     # a tour found in coffeescripts/views/tours/FirstTimeLogin
#     user.has_never_logged_in?
#   }
#
#   # Can call with a hash instead, and omit the block to always
#   # include the tour.
#   tour({
#     :name => :course_tour,
#     :version => 1,
#     :actions => [
#       'courses#show',
#       'assignments#show',
#       'settings#show',
#     ]
#   })

Tour.config do

  tour(:quiz_regrade, 1, ['quizzes#edit'])
  
  # We are taking this out for now 
  # tour(:agenda_tour, 1, '*')


  #tour(:discussion_topic_auto_unread, 1, ['discussion_topics#show', 'discussion_topics#index']) do
    #if params["action"] == "show"
      #DiscussionTopic.find(params["id"]).discussion_entries.length > 0
    #elsif params["tour-topic-id"]
      #true
    #end
  #end

end

