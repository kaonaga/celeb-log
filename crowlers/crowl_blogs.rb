#!/opt/local/bin/ruby

class CrowlBlogs
  require 'net/http'
  require 'mysql'
  require 'date'
  $KCODE = 'UTF8'

  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'
  @@crowl_type = {0 => 'official.ameba.jp', 
                  1 => 'www.style-walker.com', 
                  2 => 'www.smooche.jp'#, 
                # 3 => 'star-studio.jp', 
                # 4 => 'www2.studio-fumina.com'
                }

  def self.crowl_ameblo
    # start iteration for ameblo
    host = @@crowl_type[0]
    for i in 1..44
      index_path = "/kana/kana#{i}.html"
      body = self.get_body(host, index_path)
      match = body.scan(/<dd class="name clr">.*?<a href="(.+?)">(.+?)<br \/>.*?\((.+?)\).*?<ul>(.+?)<\/ul>.+?<dd class="word">(.*?)<\/dd>/m)
      match.each do |m|
        # start put tags in hash and reformat
        line = m[3].strip.split("</li>")
        m[3] = []
        line.each do |l|
          genre = l.scan(/<a href=.+?>(.+?)<\/a>/)
          m[3].push(genre[0][0])
        end
        # end put tags in hash and reformat
        author = m[1].gsub("'", "''")
        phonetic = m[2].gsub("'", "''")
        title = m[4].gsub("'", "''")
        uri = m[0].gsub("'", "''")
        tags = m[3].join(",").gsub("'", "''")
        crowl_type = 0
        time = Date.today.to_s + " " + Time.now.strftime("%X")

        self.insert_blog(author, phonetic, tags, uri, title, crowl_type, time)

        # start debug
        puts author
        puts title
        puts uri
        puts tags
        puts "crowl_type = #{crowl_type}"
        puts "\r\n"
        # end debug

      end
    end
    # end iteration for ameblo
  end

  def self.crowl_style_walker
    # start iteration for style walker
    host = @@crowl_type[1]
    index_path = "/sw/s/community/blog?sT=collabo"
    body = self.get_body(host, index_path)
    match = body.scan(/<div class="s1p blogBox01">.+?<strong>(.+?)<\/strong>.+?<div class="s1p blogBox02">(.+?)<\/div>.+?<div class="s1p blogBox03"><a href="(.+?)"[^>]+?>(.+?)<\/a><\/div>/m)
    match.each do |m|
      author = m[0].gsub(/<.+?>/, "").gsub("'", "''")
      phonetic = nil
      tags = m[1].gsub("、", ",").gsub("・", ",").gsub("＆", ",").gsub(/\(.+\)/, "").gsub("'", "''")
      uri = "http://" + host + m[2].gsub("'", "''")
      title = m[3].gsub("'", "''")
      crowl_type = 1
      time = Date.today.to_s + " " + Time.now.strftime("%X")

      self.insert_blog(author, phonetic, tags, uri, title, crowl_type, time)

      # start debug
      p author
      p title
      p uri
      p tags
      puts "crowl_type = #{crowl_type}"
      puts "\r\n"
      # end debug

    end
    # end iteration for style walker
  end

  def self.crowl_smooche
    # start crowl rinka's blog
    author = "梨花"
    phonetic = "りんか"
    tags = "モデル,タレント"
    uri = "http://www.smooche.jp/rinka/"
    title = "RinkaのHappy Life"
    crowl_type = 2
    time = Date.today.to_s + " " + Time.now.strftime("%X")

    self.insert_blog(author, phonetic, tags, uri, title, crowl_type, time)

    # start debug
    puts author
    puts title
    puts uri
    puts tags
    puts "crowl_type = #{crowl_type}"
    puts "\r\n"
    # end debug
  end

  def self.get_body(host, index_path)
    # Webサーバへ接続
    http = Net::HTTP.new(host)
    # Webサーバからレスポンス(ヘッダとボディ)を受け取る
    header,body = http.get(index_path)
    return body
  end

  def self.insert_blog(author, phonetic, tags, uri, title, crowl_type, time)

    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    blog_id = object.query("select id from blogs where uri = '#{uri}'").fetch_hash
    if blog_id.nil?
      object.query("insert into blogs (author, phonetic, title, uri, tags, crowl_type, last_update, created_at, updated_at) values('#{author}', '#{phonetic}', '#{title}', '#{uri}', '#{tags}', '#{crowl_type}', 'NULL', '#{time}', '#{time}')")
    else
      object.query("update blogs set author = '#{author}', phonetic = '#{phonetic}', title = '#{title}', uri = '#{uri}', tags = '#{tags}', crowl_type = '#{crowl_type}', updated_at = '#{time}' where uri = '#{uri}'")
      # start debug
      puts "this blog has been already listed as id:#{blog_id['id']}"
      # end debug
    end
    object.close
  end

end


CrowlBlogs.crowl_ameblo
CrowlBlogs.crowl_style_walker
CrowlBlogs.crowl_smooche
