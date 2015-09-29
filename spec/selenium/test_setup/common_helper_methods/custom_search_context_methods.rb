# contains custom methods that are added on to Selenium::WebDriver::SearchContext
module Selenium::WebDriver::SearchContext
  def find(css)
    find_element(:css, css)
  end

  def find_all(css)
    find_elements(:css, css)

  rescue Selenium::WebDriver::Error::NoSuchElementError
    []
  end

  # returns true if the current node does not contain
  # the specified css selector
  def not_found(css)
    raise "The selector, #{css} was found" if find_element(:css, css)

  rescue Selenium::WebDriver::Error::NoSuchElementError
    true
  end
end
