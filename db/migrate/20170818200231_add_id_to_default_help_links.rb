class AddIdToDefaultHelpLinks < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    default_links = Account::HelpLinks.default_links

    Account.root_accounts.active.find_each do |a|
      next unless a.settings[:custom_help_links]

      found_link = false
      new_links = a.settings[:custom_help_links].map do |link|
        next link unless link[:type] == 'default'
        default_link = default_links.find { |l| l[:url] == link[:url] }
        next link unless default_link
        found_link = true
        default_link
      end
      next unless found_link
      a.settings[:custom_help_links] = Account::HelpLinks.instantiate_links(new_links)
      a.save!
    end
  end
end
