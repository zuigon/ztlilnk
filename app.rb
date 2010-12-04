require "rubygems"
require "sinatra"
require "haml"
require "net/http"
require 'open3'

def lista
  fn = "lista.txt"
  return Marshal.load(File.read(fn)) if File.exist? fn

  s = "z-trening.com|/training.php\?all_tasks\=1"
  link1, link2 = s.split('|'), s.gsub("_tasks", "_user_tasks").split('|')

  lista_s, output = "", ""
  [link1, link2].each{ |x|
    Net::HTTP.start(x[0]){ |http|
      resp=http.get(x[1]); lista_s=resp.body
    }
  }

  cmd = <<EOS
grep '&nbsp;<a href="tasks.php?show_task=.*>' | sed 's/.*&nbsp;//g' | grep -o '[0-9]\\{10\\}.*' | sed -e 's/">/ - /g' -e 's:</a></TD>::g'
EOS

  IO.popen(cmd, "w+") do |pipe|
    pipe.puts lista_s; pipe.close_write; output += pipe.read
  end

  r = output.gsub("\r", "").split("\n")
  # File.open("lista.txt", "w+"){|f| f.puts Marshal.dump r} # DUMP to file

  return r
end

get '/' do
  haml :index
end

get '/f' do
  @list = lista
  name = lambda {|id|
    @list.find{|el|
      el[/50+#{id} - /] rescue ""
    }[/ - (.+)/,1] rescue nil
  }

  @ids = params[:ids].split(/,| |, /).
    collect{|x| x if x.to_i.to_s == x}.compact.
    collect{|x| [x, name.call(x)]}
  haml :links
end

def l(id)
  return nil if id.to_i.to_s != id
  id = id.rjust(9).gsub(' ', '0')
  "http://z-trening.com/tasks.php?show_task=5%s" % [id]
end

get '/l/:id' do |id|
  z = l id
  return error 500 if z.nil?
  redirect z
end

__END__

@@layout
%html
  %head
    %title ZT linker

  %body
    %h1{:style=>"font-family: georgia; color: gray; font-style: italic; margin-top: 50px; margin-left: 100px;"} ZT linker v1
    = yield
    %br
    %br
    %br

@@index
%div{:style=>"font-family: georgia;"}
  %span ID-ovi zadataka:
  %br
  %form{:action=>"/f", :method=>"get"}
    %input{:type=>"text", :name=>"ids"}
  %span{:style=>""}
    %span{:style=>"color: gray;"} format:
    %span{:style=>"color: black; font-family: 'courier new'; font-size: .8em;"} id1 id2 id3
    %span{:style=>"color: gray;"} (sa ili bez zareza)

@@links

%div{:style=>"font-family: georgia; color: orange; text-decoration: none;"}
  %ul{:style=>"list-style-type: none; padding-left: 150px;"}
    - for id in @ids
      %li{:style=>"margin-bottom: 5px;"}
        %a{:href=>"/l/%s"%[id[0]]}= "Zadatak #{id[0]}#{" (#{id[1]})" if !id[1].nil?}"

