require 'sequel'

DB = Sequel.connect("postgres://localhost/contacts")

class DatabasePersistence
  def initialize(logger)
    DB.logger = logger
  end

  def find_user_id(username)
    DB[:users].where(username: username).select(:id).first[:id]
  end

  def load_contacts(username)
    contacts = {}
    DB[:contacts].where(username_id: find_user_id(username)).each do |tuple|
      contacts[tuple[:id].to_i] = {
      first: tuple[:first], 
      last: tuple[:last], 
      email: tuple[:email], 
      phone: tuple[:phone]}
    end
    contacts
  end

  def save_contacts(contacts, username)
    first, last, email, phone = contacts
    DB[:contacts].insert(first: first, last: last, email: email, phone: phone, username_id: find_user_id(username))
  end

  def update_contact(contacts, contact_id, username)
    first, last, email, phone = contacts
    DB[:contacts].where(id: contact_id).update(first: first, last: last, email: email, phone: phone, username_id: find_user_id(username))
  end

  def delete_contact(id, username)
    DB[:contacts].delete(id: id, username_id: find_user_id(username))
  end

  def load_credentials(user)
    DB[:users].where(username: user).first[:pass]
  end

  def save_credentials(user, pass)
    DB[:users].insert(username: user, pass: pass)
  end
end