#!/opt/local/bin/ruby
# for centos
# /usr/local/bin/ruby

class CreatePosts
  require 'net/http'
  require 'net/pop'
  require 'cgi'
  require 'mysql'
  require 'date'
  require 'nkf'
  require 'logger'
  $KCODE = 'UTF8'

  # port = 80
  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'

  @@logger = Logger.new("/Users/BillEvans/Workspace/celeb-log/log/crowl.log", 'daily')
  # @@logger = Logger.new("/var/www/html/celeb-log/log/crowl.log", 'daily')

  USE_APOP = false
  POP_SERVER = {
    :address => 'mail.MyDNS.JP',
    :port => 110,
    :account => 'mydns28275',
    :password => 'vH3Dsty4'
    }

  def self.create_posts
    # how many words to get around the keyword
    # content_rangge = 100 #words

    # object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    object = Mysql.init()
    object.options(Mysql::SET_CHARSET_NAME, "utf8")
    object.real_connect(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)

    brand_query = object.query("select id, name, phonetic from brands where delete_flg is null")

    # iteration for brands
    while brand_hash = brand_query.fetch_hash
      brand_id = brand_hash['id']
      name = brand_hash['name']
      phonetic = brand_hash['phonetic']
      escaped_name = name.gsub("'", "''")
      escaped_phonetic = phonetic.gsub("'", "''")

      # start debug
      @@logger.debug("#{brand_id}: #{name} (#{phonetic})")
      puts "#{brand_id}: #{name} (#{phonetic})"
      # end debug

      # iteration for blog entries
      # entry_query = object.query("select id, blog_id, content, created_at from blog_entries where content like '%#{escaped_name}%' or content like '%#{escaped_phonetic}%'")
      entry_query = object.query("select id, blog_id, content, created_at from blog_entries where match(content) against('#{escaped_name}%') or content like '%#{escaped_phonetic}%'")
      while entry = entry_query.fetch_hash
        blog_id = entry["blog_id"]
        blog_entry_id = entry["id"]
        content = entry["content"]
        posted_date = entry['created_at']
        time = Date.today.to_s + " " + Time.now.strftime("%X")

        # iteration for search method
        search_method = [name, phonetic].each do |m|
          case m
          when phonetic
            ng_type = 0
          when name
            ng_type = 1
          end
          # skip analyzing for names and phonetics that contain less than 3 words
          if m == name and m.split(//u).length <= 2
            next
          elsif m == phonetic and m.split(//u).length <= 3
            next
          end

          # alphabetical keyword search accuracy adjustment
          # ex) if keyword is "ash", except words like "flash"
          # if m == name
          #   # unless /[^a-zA-Z\\\/;:]+#{name}[^a-zA-Z\\\/;:]+/ =~ content.split(//u).slice(content_from, content_to).join.gsub("'", "''")
          #   unless /[^a-zA-Z\\\/;:]+#{name}[^a-zA-Z\\\/;:]+/ =~ content
          #     # start debug
          #     @@logger.debug("=> brand name cannot be specified\r\n")
          #     # end debug
          #     next
          #   end
          # end
          # end alphabetical keyword search accuracy adjustment

          content.each do |line|
            if /#{m}/ =~ line
              # start do not insert the same post
              if object.query("select id from posts where blog_id = '#{blog_id}' and blog_entry_id = '#{blog_entry_id}' and brand_id = '#{brand_id}'").fetch_hash.nil?
                ng_flg = analyze_ng_words(brand_id, ng_type, line)
                if ng_flg.nil?
                  begin
                    object.query("insert into posts (blog_id, blog_entry_id, brand_id, product_id, posted_date, created_at, updated_at) values(#{blog_id}, #{blog_entry_id}, '#{brand_id}', 'NULL', '#{posted_date}', '#{time}', '#{time}')")
                    # start debug
                    @@logger.debug("hit by #{m}")
                    @@logger.debug("=> 1 row inserted into posts successfully\r\n\r\n")
                    puts "hit by #{m}"
                    puts "=> 1 row inserted into posts successfully\r\n\r\n"
                    # end debug
                  rescue => error
                    p error
                  end
                else
                  @@logger.debug("=> this content has NG Word(s) and not collected\r\n\r\n")
                  puts "=> this content has NG Word(s) and not collected\r\n\r\n"
                end
              else
                # start debug
                @@logger.debug("blog_id = #{blog_id}")
                @@logger.debug("blog_entry_id = #{blog_entry_id}")
                @@logger.debug("=> This post has been already created\r\n\r\n")
                puts "blog_id = #{blog_id}"
                puts "blog_entry_id = #{blog_entry_id}"
                puts "=> This post has been already created\r\n\r\n"
                # end debug
              end
              # end do not insert the same post
            end
          end
          # end iteration for each line
        end
        # end iteration for search method
      end
      # end iteration for blog entries
    end
    # end iteration for brands
    object.close
  end

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

  def self.analyze_ng_words(brand_id, ng_type, line)
    # object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    object = Mysql.init()
    object.options(Mysql::SET_CHARSET_NAME, "utf8")
    object.real_connect(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)

    ng_flg = nil
    ng_words_query = object.query("select ng_word from ng_words where brand_id = #{brand_id} and ng_type = #{ng_type}")
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
      Net::POP3.APOP(USE_APOP).start(POP_SERVER[:address],
                                     POP_SERVER[:port],
                                     POP_SERVER[:account],
                                     POP_SERVER[:password])
    rescue => e
      p e
    end
  end
end

CreatePosts.create_posts
CreatePosts.create_blog_listed_count
CreatePosts.create_brand_listed_count
CreatePosts.dns_health_check