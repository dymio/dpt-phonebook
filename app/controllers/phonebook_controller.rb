class PhonebookController < ApplicationController
  
  def index
    @phlines = Contact.get_full_collection
  end

end
