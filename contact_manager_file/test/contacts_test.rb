ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../contacts'

class ContactTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    
  end

  # separating from setup because encryption takes long
  def create_credentials
    @storage = FilePersistence.new(session)
    @storage.save_credentials({ 'user' => bcrypt_pass('pass123'), 'user2' => bcrypt_pass('pass456') })
  end

  def remove_credentials
    File.delete(@storage.credentials_path)
  end

  def teardown
    FileUtils.rm_rf(@storage.contacts_path) if session
  end

  def session
    current_session = last_request.env['rack.session']
    @storage = FilePersistence.new(current_session)
    current_session
  end

  def user_session
    { 'rack.session' => { user: 'user' } }
  end

  def second_user_session
    { 'rack.session' => { user: 'user2' } } 
  end

  def test_index
    get '/', {}, user_session

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, %q(<h1>Contact Manager</h1>)
  end

  def test_index_without_login_redirect_to_signin
    get '/'

    assert_equal 302, last_response.status
    assert_equal 'Please sign in.', session[:message]
    
    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(thod="post" action="/signin">)
    assert_includes last_response.body, 'Please sign in.'
    assert_nil session[:message]
  end

  def test_add
    get '/add', {}, user_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<h2>Add contact</h2>)
    assert_includes last_response.body, %q(<form method="post" action="/add">)
  end

  def test_add_contact
    post '/add', {first: 'dude', last: 'man', email: 'email@address.com', phone: '555-555-5555'}, user_session

    assert_equal 302, last_response.status
    assert_equal 'Contact saved.', session[:message]

    get last_response['Location']
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Dude Man'
    assert_includes last_response.body, 'Contact saved.'
    assert_nil session[:message]
  end

  def test_add_another_contact
    post '/add', {first: 'funny', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session

    assert_equal 302, last_response.status
    assert_equal 'Contact saved.', session[:message]

    get last_response['Location']
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Funny Bunny'
    assert_includes last_response.body, 'Contact saved.'
    assert_nil session[:message]
  end

  def test_other_user_cant_see_others_contact
    post '/add', {first: 'true', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session

    get '/', {}, second_user_session

    refute_includes last_response.body, 'True Bunny'

    get '/', {}, user_session

    assert_includes last_response.body, 'True Bunny'
  end

  def test_add_invalid_first_name_blank
    post '/add', {first: '', last: 'popeye', email: 'pop@eye.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid first name (check for length or invalid characters).'
    assert_nil session[:message]
  end

  def test_add_invalid_first_name_invalid_character
    post '/add', {first: 'pop@12', last: 'popeye', email: 'pop@eye.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid first name (check for length or invalid characters).'
    assert_nil session[:message]
  end

  def test_add_invalid_first_name_invalid_character_2
    post '/add', {first: 'full name', last: 'popeye', email: 'pop@eye.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid first name (check for length or invalid characters).'
    assert_nil session[:message]
  end

  def test_add_invalid_last_name_too_short
    post '/add', {first: 'popeye', last: 'p', email: 'pop@eye.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid last name (check for length or invalid characters).'
    assert_nil session[:message]
  end

  def test_add_invalid_last_name_too_long
    post '/add', {first: 'popeye', last: 'popeyepopeyepopeyepopeyepopeyepopeye', email: 'pop@eye.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid last name (check for length or invalid characters).'
    assert_nil session[:message]
  end

  def test_add_invalid_email
    post '/add', {first: 'charlie', last: 'popeye', email: '@eye.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid email address.'
    assert_nil session[:message]
  end

  def test_add_invalid_email_2
    post '/add', {first: 'charlie', last: 'popeye', email: 'pop@.com', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid email address.'
    assert_nil session[:message]
  end

  def test_add_invalid_email_3
    post '/add', {first: 'charlie', last: 'popeye', email: 'pop@eye.c', phone: '555-555-5555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid email address.'
    assert_nil session[:message]
  end

  def test_add_invalid_phone
    post '/add', {first: 'charlie', last: 'popeye', email: 'pop@eye.com', phone: '555-555-555'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid phone number (format must be 555-555-5555).'
    assert_nil session[:message]
  end

  def test_add_invalid_phone_2
    post '/add', {first: 'charlie', last: 'popeye', email: 'pop@eye.com', phone: '555-555-555232'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid phone number (format must be 555-555-5555).'
    assert_nil session[:message]
  end

  def test_add_invalid_phone_3
    post '/add', {first: 'charlie', last: 'popeye', email: 'pop@eye.com', phone: '555555555232'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid phone number (format must be 555-555-5555).'
    assert_nil session[:message]
  end

  def test_add_invalid_phone_4
    post '/add', {first: 'charlie', last: 'popeye', email: 'pop@eye.com', phone: '(555)555-5552'}, user_session

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid phone number (format must be 555-555-5555).'
    assert_nil session[:message]
  end

  def test_details
    post '/add', {first: 'funny', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session
    get '/details/1'
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Funny Bunny'
    assert_includes last_response.body, 'email@address.com'
    assert_includes last_response.body, '555-555-5555'
    assert_includes last_response.body, %q(<p><a href="/">< back</a></p>)
  end

  def test_edit
    post '/add', {first: 'funny', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session
    get '/details/1/edit'

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<form method="post" action="/details/)
  end

  def test_save_edits
    post '/add', {first: 'funny', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session
    post '/details/1/edit', {first: 'bugs', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}

    assert_equal 302, last_response.status
    assert_equal 'Contact edits saved.', session[:message]

    get '/details/1'

    assert_includes last_response.body, 'Bugs Bunny'
    refute_includes last_response.body, 'Funny Bunny'

    get '/'

    assert_includes last_response.body, 'Bugs Bunny'
    refute_includes last_response.body, 'Funny Bunny'
  end

  def test_invalid_edit
    post '/add', {first: 'funny', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session
    post '/details/1/edit', {first: 'bu@gs', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}

    assert_equal 422, last_response.status
    assert_nil session[:message]
    assert_includes last_response.body, 'Invalid first name (check for length or invalid characters).', session[:message]

    get '/details/1'

    refute_includes last_response.body, 'Bugs Bunny'
    assert_includes last_response.body, 'Funny Bunny'
  end

  def test_delete
    post '/add', {first: 'funny', last: 'bunny', email: 'email@address.com', phone: '555-555-5555'}, user_session
    get last_response['Location']

    assert_includes last_response.body, 'Funny Bunny'

    post '/details/1/delete'

    assert_equal 302, last_response.status
    assert_equal 'Contact deleted.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, 'Funny Bunny'
  end

  def test_signin
    get '/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(thod="post" action="/signin">)
    assert_nil session[:message]
  end

  def test_signin_valid_attempt
    get '/'

    create_credentials

    post '/signin', {user: 'user', pass: 'pass123'}

    assert_equal 302, last_response.status
    assert_equal 'Login successful. Enjoy your contacts.', session[:message]

    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<h1>Contact Manager</h1>)
    assert_includes last_response.body, 'Login successful. Enjoy your contacts.'
    assert_nil session[:message]

    remove_credentials
  end

  def test_signin_non_existent_username
    get '/'

    create_credentials

    post '/signin', {user: 'popeye', pass: 'oliveoil'}

    assert_equal 422, last_response.status
    assert_nil session[:message]
    assert_includes last_response.body, 'Invalid username and/or password'

    remove_credentials
  end

  def test_signin_wrong_password
    get '/'

    create_credentials

    post '/signin', {user: 'user', pass: 'oliveoil'}

    assert_equal 422, last_response.status
    assert_nil session[:message]
    assert_includes last_response.body, 'Invalid username and/or password'

    remove_credentials
  end

  def test_signout
    get '/signout', {}, user_session

    assert_equal 302, last_response.status
    assert_nil session[:user]
    assert_equal 'Successfully logged out.', session[:message]
  end

  def test_signup
    get '/signup'

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<form method="post" action="/signup">)
  end

  def test_signup_successful
    get '/'

    create_credentials

    post '/signup', {user: 'monday', pass: '1234', pass2: '1234'}

    assert_equal 302, last_response.status
    assert_equal 'Account successfully created.', session[:message]

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Account successfully created.'
    assert_nil session[:message]

    post '/signin', {user: 'monday', pass: '1234'}

    assert_equal 302, last_response.status
    assert_equal 'Login successful. Enjoy your contacts.', session[:message]

    remove_credentials
  end

  def test_signup_invalid_username
    post '/signup', {user: 'monday@', pass: '1234', pass2: '1234'}

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid username.'
    assert_nil session[:message]
  end

  def test_signup_password_mismatch
    post '/signup', {user: 'monday', pass: '1234', pass2: '12345'}

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid password.'
    assert_nil session[:message]
  end

end