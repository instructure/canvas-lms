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

  #tour(:first_time_login, 'users#user_dashboard') {
    #params[:registration_success] &&
    #@current_user &&
    #@current_user.initial_enrollment_type == 'teacher'
  #}

end

