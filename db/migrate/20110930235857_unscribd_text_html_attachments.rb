class UnscribdTextHtmlAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    Attachment.where(:content_type => ['text/html', 'application/xhtml+xml', 'application/xml', 'text/xml']).
        update_all(:scribd_mime_type_id => nil, :scribd_doc => nil)
  end

  def self.down
  end
end
