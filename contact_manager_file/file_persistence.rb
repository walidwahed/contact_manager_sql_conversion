class FilePersistence
  def initialize(session)
    @session = session
  end

  def setup_contacts
    new_contacts unless contacts_exist?
    load_contacts
  end

  def save_contacts(contacts)
    File.write(contacts_path + '/contacts.yml', contacts.to_yaml)
  end

  def load_credentials
    YAML.load_file(credentials_path)
  end

  def save_credentials(credentials)
    File.write(credentials_path, credentials.to_yaml)
  end

  def credentials_path
    if ENV['RACK_ENV'] == 'test'
      File.expand_path('../test/users.yml', __FILE__)
    else
      File.expand_path('../users.yml', __FILE__)
    end
  end

  def contacts_path
    if ENV['RACK_ENV'] == 'test'
      File.expand_path("../test/data/#{@session[:user]}", __FILE__)
    else
      File.expand_path("../data/#{@session[:user]}", __FILE__)
    end
  end

  private

  def load_contacts
    YAML.load_file(contacts_path + '/contacts.yml')
  end

  def new_contacts
    FileUtils.mkdir_p(contacts_path)
    File.write(contacts_path + '/contacts.yml', {}.to_yaml)
  end

  def contacts_exist?
    File.file?(contacts_path + '/contacts.yml')
  end
end