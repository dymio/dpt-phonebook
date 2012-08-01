class Contact < ActiveRecord::Base
  has_many :phones
  attr_accessible :name

  # get all contacts and his phones by one query and collapse it
  def self.get_full_collection
    all_contacts = ActiveRecord::Base.connection.execute('SELECT "contacts".id, "contacts".name, "phones".id as ph_id, "phones".number FROM "contacts" INNER JOIN "phones" ON "phones"."contact_id" = "contacts"."id" ORDER BY "contacts".name')

    phlines = []
    prev_contact_name = nil

    all_contacts.each do |one|
      unless prev_contact_name == one['name']
        phlines << {id: one['id'], name: one['name'], phones: [{id: one['ph_id'], number: one['number']}]}
        prev_contact_name = one['name']
      else
        phlines.last[:phones] << {id: one['ph_id'], number: one['number']}
      end
    end

    phlines
  end


end
