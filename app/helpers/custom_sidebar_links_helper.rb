# extension points for plugins to add sidebar links
# return an array of hashes containing +url+, +icon_class+, and +text+
module CustomSidebarLinksHelper

  # add a link to the account page sidebar
  # @account is the account
  def account_custom_links
    []
  end

  # add a link to the course page sidebar
  # @context is the course
  def course_custom_links
    []
  end

  # add a link to a user roster or profile page
  # @context is the course
  def roster_user_custom_links(user)
    []
  end

end
