require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'contacts')
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def load_contacts(username)
    sql = "SELECT * FROM contacts WHERE username_id = $1;"
    result = query(sql, find_user_id(username))
    contacts = {}
    result.each do |tuple|
      contacts[tuple['id'].to_i] = {
        first: tuple['first'], 
        last: tuple['last'], 
        email: tuple['email'], 
        phone: tuple['phone']}
    end
    contacts
  end

  def save_contacts(contacts, username)
    first, last, email, phone = contacts
    sql = "INSERT INTO contacts (first, last, email, phone, username_id) VALUES ($1, $2, $3, $4, $5);"
    query(sql, first, last, email, phone, find_user_id(username))
  end

  def find_user_id(username)
    sql = "SELECT id FROM users WHERE username = $1"
    query(sql, username).field_values('id').first
  end

  def update_contact(contacts, contact_id, username)
    first, last, email, phone = contacts
    sql = "UPDATE contacts SET first = $1, last = $2, email = $3, phone = $4 WHERE id = $5 AND username_id = $6;"
    query(sql, first, last, email, phone, contact_id, find_user_id(username))
  end

  def delete_contact(id, username)
    sql = "DELETE FROM contacts WHERE id = $1 AND username_id = $2"
    query(sql, id, find_user_id(username))
  end

  def load_credentials(user)
    sql = "SELECT pass FROM users WHERE username = $1 LIMIT 1"
    query(sql, user).field_values('pass').first
  end

  def save_credentials(user, pass)
    sql = "INSERT INTO users (username, pass) VALUES ($1, $2)"
    query(sql, user, pass)
  end
end