Canvas::Plugin.register('address_book', nil, {
  :name => lambda{ t :name, 'Address Book' },
  :description => lambda{ t :description, 'Configure how to answer address book queries.' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '0.1.0',
  :settings_partial => 'plugins/address_book_settings',
  :validator => 'AddressBookValidator',
  # default settings
  :settings => { strategy: AddressBook::DEFAULT_STRATEGY }
})
