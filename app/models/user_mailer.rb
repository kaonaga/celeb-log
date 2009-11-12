class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://localhost:3000/activate/#{user.activation_code}"
    # @body[:url]  = "http://celeb-log.info/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://localhost:3000/"
    # @body[:url]  = "http://celeb-log.info/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "info@celeb-log.info"
      @subject     = "[celeb-log.info セレブログ] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
