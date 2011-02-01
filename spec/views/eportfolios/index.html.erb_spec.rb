#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
# require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

# describe "/eportfolios/index" do
  # it "should render" do
    # eportfolio_with_user
    # view_portfolio
    # assigns[:portfolios] = [@portfolio]
    # render "eportfolios/index"
    # response.should_not be_nil
  # end
# end

# <% content_for :page_title do %>
  # My ePortfolios
# <% end %>

# <% content_for :page_header do %>
  # <h1>My ePortfolios</h1>
# <% end %>

# <% content_for :page_subhead do %>
  # <h2>List of created ePortfolios</h2>
# <% end %>

# <% content_for :primary_nav do %>
  # <%= render :partial => "shared/primary_nav", :locals => {:view => "dashboard"} %>
# <% end %>

# <% content_for :secondary_nav do %>
  # <%= render :partial => "shared/dashboard_secondary_nav", :locals => {:view => "eportfolios"} %>
# <% end %>

# <% content_for :right_side do %>
  # <a href="#" class="add_eportfolio_link"><%= "add.png" %> Create an ePortfolio</a>
# <% end %>

# <% if @portfolios.empty? %>
  # <p>You haven't created any ePortfolios yet.  Would you like to make one now?  It's really easy, I promise.</p>
  # <div style="text-align: right;">
  # <input type="button" class="add_eportfolio_link" value="Create an ePortfolio" style="font-size: 1.5em;"/>
  # </div>
# <% else %>
  # <h2>My ePortfolios</h2>
  # <% @portfolios.each do |p| %>
    
  # <% end %>
# <% end %>
# <script>
# $(document).ready(function() {
  # $(".add_eportfolio_link").click(function(event) {
    # event.preventDefault();
    # $("#add_eportfolio_form").slideToggle();
  # });
# });
# </script>
# <% form_for Eportfolio.new, :url => eportfolios_url, :html => {:style => "display: none;", :id => "add_eportfolio_form"} do |f| %>
# <table class="formtable">
  # <tr>
    # <td><%= f.label :name, "ePortfolio Name:" %></td>
    # <td><%= f.text_field :name %></td>
  # </tr><tr>
    # <td colspan="2">
      # <%= f.check_box :public, :value => true %>
      # <%= f.label :public, "Public ePortfolio", :checked => true %>
    # </td>
  # </tr><!--tr>
    # <td>This is For:</tr>
    # <td>
      # <select>
        # <optgroup label="My Class">
          # <option value="">Biology 100</option>
          # <option value="">Biology 100</option>
        # </optgroup>
        # <optgroup label="My Institution">
          # <option value="">Biology 100</option>
        # </optgroup>
        # <optgroup label="Other">
          # <option value="">Biology 100</option>
        # </optgroup>
      # </select>
    # </td>
  # </tr--><tr>
    # <td colspan="2" style="text-align: right;">
      # <%= f.submit "Make ePortfolio" %>
      # <input type="button" value="Cancel"/>
    # </td>
  # <td>
# </table>
# <% end %>