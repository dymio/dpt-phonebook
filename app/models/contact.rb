class Contact < ActiveRecord::Base
  has_many :phones, :dependent => :destroy

  accepts_nested_attributes_for :phones

  attr_accessible :name, :phones_attributes

  validates :name, :presence => true

  def prepare_for_json
    to_json(only: [:id, :name], include: { :phones => { only: [:id, :number] } })
  end

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
