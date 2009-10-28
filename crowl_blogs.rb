#!/opt/local/bin/ruby

require 'net/http'
require 'cgi'
require 'mysql'
require 'dbi'

host = 'official.ameba.jp'
# port = 80
mysql_host = 'localhost'
mysql_user = 'mysql'
mysql_password = 'mysqlclient'
mysql_db = 'celeb-log_development'


for i in 1..44
  index_path = "/kana/kana#{i}.html"

  # require 'socket'
  # 
  # # Webサーバへ接続
  # socket = TCPSocket.new(host, port)
  # 
  # # Webサーバへリクエストを送る
  # socket.puts "GET #{index_path} HTTP/1.0\r\n"
  # socket.puts "Host: #{host}\r\n"
  # socket.puts "\r\n"
  # 
  # # puts socket.read.split("\r\n\r\n")[1..-1].join("\r\n\r\n")
  # # Webサーバからのレスポンスを受け取る
  # res = socket.read.split("\r\n\r\n")[1..-1].join("\r\n\r\n")
  # # ヘッダとボディ部に分割
  # headers, body = res.split("\r\n\r\n",2)
  # # ボディ部を1行づつ出力
  # body.each do |res_line|
  #   puts res_line
  # end
  # 
  # socket.close

  # open-uriではPOSTできない
  # require 'open-uri'
  # 
  # target = "http://#{host}#{index_path}"
  # 
  # open(target) {|con|
  #   con.each do |line|
  #     puts line
  #   end
  # }

  # Webサーバへ接続
  http = Net::HTTP.new(host)
  # Webサーバからレスポンス(ヘッダとボディ)を受け取る
  header,body = http.get(index_path)

  match = body.scan(/<dd class="name clr">.*?<a href="(.+?)">(.+?)<br \/>.*?\((.+?)\).*?<ul>(.+?)<\/ul>.+?<dd class="word">(.*?)<\/dd>/m)
  match.each do |m|
    line = m[3].strip.split("</li>")
    m[3] = []
    line.each do |l|
      genre = l.scan(/<a href=.+?>(.+?)<\/a>/)
      m[3].push(genre[0][0])
    end

    p m
    puts "\r\n"

    # CGI::unescapeHTML("HTML escaped string")
    author = CGI.escapeHTML(m[1].gsub("'", "''"))
    phonetic = CGI.escapeHTML(m[2].gsub("'", "''"))
    title = CGI.escapeHTML(m[4].gsub("'", "''"))
    uri = m[0].gsub("'", "''")
    tags = CGI.escapeHTML(m[3].join(",").gsub("'", "''"))
    crowl_type = 0 if /ameblo.jp/ =~ uri
    time = Date.today.to_s + " " + Time.now.strftime("%X")

    # begin
    #     # MySQLサーバへ接続
    #     dbh = DBI.connect("localhost", "mysql", "millmilkhill1000")
    #     # サーババージョンの文字列を取得して、表示する。
    #     row = dbh.select_one("SELECT VERSION()")
    #     puts "Server version: " + row[0]
    #     dbh.do("insert into blogs (author, phonetic, title, uri, tags, crowl_type) values(?, ?, ?, ?, ?)", author, phonetic, title, uri, tags, 0)
    # rescue DBI::DatabaseError => e
    #     puts "An error occurred"
    #     puts "Error code: #{e.err}"
    #     puts "Error message: #{e.errstr}"
    # ensure
    #     # サーバから切断
    #     dbh.disconnect if dbh
    # end

    object = Mysql::new(mysql_host, mysql_user, mysql_password, mysql_db)

    if object.query("select id from blogs where uri = '#{uri}'").fetch_hash.nil?
      object.query("insert into blogs (author, phonetic, title, uri, tags, crowl_type, last_update, created_at, updated_at) values('#{author}', '#{phonetic}', '#{title}', '#{uri}', '#{tags}', '#{crowl_type}', 'NULL', '#{time}', '#{time}')")
    else
      object.query("update blogs set author = '#{author}', phonetic = '#{phonetic}', title = '#{title}', uri = '#{uri}', tags = '#{tags}', crowl_type = '#{crowl_type}', updated_at = '#{time}' where uri = '#{uri}'")
    end
    object.close
  end
end