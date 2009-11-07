#!/opt/local/bin/ruby

# Watch out for 4℃(ヨンドシー)!

class CrowlBrands
  require 'net/http'
  require 'mysql'
  require 'dbi'
  require 'cgi'
  require 'nkf'

  @@mysql_host = 'localhost'
  @@mysql_user = 'mysql'
  @@mysql_password = 'mysqlclient'
  @@mysql_db = 'celeb-log_development'

  def self.crowl_buyma
    host = 'www.buyma.com'
    index_path = ['/list/fashion.html', 
                  '/list/beauty.html', 
                  '/list/baby_kids.html', 
                  '/list/lifestyle.html', 
                  '/list/mens.html'
                  ]

    for i in 0..index_path.length - 1
      # Webサーバへ接続
      http = Net::HTTP.new(host)
      # Webサーバからレスポンス(ヘッダとボディ)を受け取る
      header,body = http.get(index_path[i])
      match = body.scan(/<li><a href=".+?">([^\()]+?)\(([^\)]+?)\)<\/a>.*?<\/li>/m)
      match.each do |m|
        name = CGI.unescapeHTML(m[0]).gsub("&apos;", "'").gsub("'", "''")
        phonetic = CGI.unescapeHTML(NKF.nkf('-w', m[1])).gsub("&apos;", "'").gsub("'", "''")
        time = Date.today.to_s + " " + Time.now.strftime("%X")
        insert_brand(name, phonetic, time)
      end
    end
  end

  def self.crowl_fashion_walker
    host = "gw.tv"
    index_path = "/fw/b/pc/Brand.html?mthd=69&SC=0F1&aid=&aid2=&aid3=&A=00&D=00"
    # Webサーバへ接続
    http = Net::HTTP.new(host)
    # Webサーバからレスポンス(ヘッダとボディ)を受け取る
    header, body = http.get(index_path)
    match = NKF.nkf('-w', body).scan(/<LI>.+?<A href="(.+?)">・(.+?)<\/A>.*?<\/LI>/m)
    match.each do |m|
      name = m[1]
      # get phonetic from linked page's title
      linked_path = m[0].sub("http://#{host}", "")
      header2, body2 = http.get(linked_path)
      match2 = NKF.nkf('-w', body2).scan(/<title>(.+?)<\/title>/)
      match2[0][0].sub!("#{name}　", "").sub!("｜ファッション通販ならファッションウォーカー", "")
      phonetic = CGI.unescapeHTML(NKF.nkf('-w', match2[0][0])).gsub("&apos;", "'").gsub("'", "''")
      name = CGI.unescapeHTML(m[1]).gsub("&apos;", "'").gsub("'", "''")
      time = Date.today.to_s + " " + Time.now.strftime("%X")

      insert_brand(name, phonetic, time)
    end
  end

  def self.insert_brand(name, phonetic, time, category = 0)
    object = Mysql::new(@@mysql_host, @@mysql_user, @@mysql_password, @@mysql_db)
    if object.query("select id from brands where name = '#{name}' and phonetic = '#{phonetic.gsub("　", "")}'").fetch_hash.nil?
      object.query("insert into brands (name, phonetic, category, created_at, updated_at) values ('#{name}', '#{phonetic}', #{category}, '#{time}', '#{time}')")
      # start debug
      puts name
      puts phonetic
      puts "=> 1 row inserted into brands successfully"
      puts "\r\n"
      # end debug
    else
      # start debug
      puts "#{name} has been already crowled"
      puts "\r\n"
      # end debug
    end
    object.close
  end
end

CrowlBrands.crowl_buyma
CrowlBrands.crowl_fashion_walker