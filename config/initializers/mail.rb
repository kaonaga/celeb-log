require "smtp_tls"

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "celeb-log.info",
  :authentication => :plain,
  :user_name => "info@celeb-log.info",
  :password => "infoceleblogaccountpassword"
}
