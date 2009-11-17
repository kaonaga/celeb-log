#!/opt/local/bin/ruby
# for centos
# /usr/local/bin/ruby

class Crowler
  require 'net/http'
  require 'net/pop'
  require 'cgi'
  require 'mysql'
  require 'date'
  require 'nkf'
  require 'logger'
  $KCODE = 'UTF8'

  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'

  @@logger = Logger.new("/Users/BillEvans/Workspace/celeb-log/log/crowl.log", 'daily')
  # @@logger = Logger.new("/var/www/html/celeb-log/log/crowl.log", 'daily')

  @@use_apop = false
  @@pop_server = {
    :address => 'mail.MyDNS.JP',
    :port => 110,
    :account => 'mydns28275',
    :password => 'vH3Dsty4'
    }

  def self.create_blog_listed_count
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    begin
      blog_query = object.query("select id from blogs where delete_flg is null")
      while blog_hash = blog_query.fetch_hash
        blog_id = blog_hash['id']
        listed_count = object.query("select count(id) count from posts where blog_id = #{blog_id} and delete_flg is null").fetch_hash['count']
        object.query("update blogs set listed_count = #{listed_count} where id = #{blog_id}")
        # start debug
        @@logger.debug("=> blog_id = #{blog_id}: listed_count = #{listed_count}")
        puts "=> blog_id = #{blog_id}: listed_count = #{listed_count}"
        # end debug
      end
    rescue => error
      p error
    end
    object.close
  end

  def self.create_brand_listed_count
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)

    begin
      brand_query = object.query("select id from brands where delete_flg is null")
      while brand_hash = brand_query.fetch_hash
        brand_id = brand_hash['id']
        listed_count = object.query("select count(id) count from posts where brand_id = #{brand_id} and delete_flg is null").fetch_hash['count']
        object.query("update brands set listed_count = '#{listed_count}' where id = '#{brand_id}'")
        # start debug
        @@logger.debug("=> brand_id = #{brand_id}: listed_count = #{listed_count}")
        puts "=> brand_id = #{brand_id}: listed_count = #{listed_count}"
        # end debug
      end
    rescue => error
      p error
    end
    object.close
  end

  def self.analyze_ng_words(blog_id, brand_id, ng_type, line)
    # object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    object = Mysql.init()
    object.options(Mysql::SET_CHARSET_NAME, "utf8")
    object.real_connect(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    ng_flg = nil
    ng_words_query = object.query("select ng_word from ng_words where (blog_id is null or blog_id = #{blog_id}) and brand_id = #{brand_id} and ng_type = #{ng_type}")
    unless ng_words_query == []
      # start iteration for each ng_word
      while ng_word = ng_words_query.fetch_hash
        if /(#{ng_word['ng_word']})/ =~ line
          ng_flg = $1
          @@logger.debug("#{ng_word['ng_word']} was detected as NG Word\r\n")
          puts "#{ng_word['ng_word']} was detected as NG Word\r\n"
          break
        end
      end
      # end iteration for each ng_word
    end
    object.close
    ng_flg
  end

  def self.dns_health_check
    # consoleからkickする場合
    # script/runner -e development "app = ActionController::Integration::Session.new; app.get 'posts/new/mail'"
    begin
      # Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
      Net::POP3.APOP(@@use_apop).start(@@pop_server[:address],
                                     @@pop_server[:port],
                                     @@pop_server[:account],
                                     @@pop_server[:password])
    rescue => e
      p e
    end
  end
end