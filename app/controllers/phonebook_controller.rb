class PhonebookController < ApplicationController
  
  def index
    @phlines = Contact.get_full_collection
  end

  # !!! remove
  # def populaten
  #   (1..2436).each do |i|
  #     Contact.create(name: 'The human ' + i.to_s)
  #     Phone.create(contact_id: Contact.last.id, number: '+74393475364')
  #     Phone.create(contact_id: Contact.last.id, number: '+74393475361') if (i % 3) == 0
  #   end
  # end

end
