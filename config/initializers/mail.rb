require "smtp_tls"

# 
# pop & imap settings
# 
module CelebLog
  USE_APOP = false
  POP_SERVER = {
    :address => 'mail.MyDNS.JP',
    :port => 995,
    :account => 'mydns28275',
    :password => 'vH3Dsty4'
    }
  IMAP_SERVER = {
    :address => 'imap.gmail.com',
    :port => 993,
    :account => 'go@tabelogo.com',
    :password => 'tabetabehihi'
    }
end

# 
# smtp settings
#
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "celeb-log.info",
  :authentication => :plain,
  :user_name => "info@celeb-log.info",
  :password => "infoceleblogaccountpassword"
}