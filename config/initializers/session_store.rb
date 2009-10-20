# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_celeb-log_session',
  :secret      => 'ba901b59203d8ee256289e9ea204e8087a3a68cf9e1c4fa851e0f321b0b5bab972be2d2fe1199b37e51a1ff1fcf703418d5c642b827787c4f06b3caff487d21d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
