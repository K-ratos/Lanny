require "socket"
class Server
  def initialize(address, port)
    @server = nil
    @connections  = {}
    @rooms = {}
    @clients = {}
    @user_room = {}
    @server = TCPServer.open( address, port )
    @connections[:server] = @server
    @connections[:rooms] = @rooms
    @connections[:clients] = @clients
    @connections[:user_room] = @user_room
    empty_room_delete
    run
  end

  def run
      loop {
        Thread.start(@server.accept) do | client |
          nick_name = client.gets.chomp.to_sym
          @connections[:clients].each do |other_name, other_client|
            if nick_name == other_name || client == other_client
              client.puts "This username already exist"
              client.puts ":exit_server"
              Thread.kill self
            end
          end
          puts "#{nick_name} #{client}"
          @connections[:clients][nick_name] = client
          loop {
            client.puts "Enter room to enter"
            list_rooms(client)
            room_to_enter = client.gets.chomp.to_sym
            if !@connections[:rooms].key?(room_to_enter)
              client.puts "->No Such room"
              client.puts "  do you want to create y/n ?"
              answer = client.gets.chomp
              if answer == "y"
                new_room(room_to_enter, nick_name)
                break
              else
                next
              end
            else
              @connections[:rooms][room_to_enter] << nick_name
              @connections[:user_room][nick_name] = room_to_enter
              break
            end
          }
          client.puts "Connection established! Happy chatting"
          listen_user_messages( nick_name, client )
          end
      }.join
    end

  def empty_room_delete
      @connections[:rooms].each{ |room_name, userlist|
        if userlist.empty?
          @connections[:rooms].delete(room_name)
        end
      }
  end

  def list_rooms(client)
    if @connections[:rooms].empty?
      client.puts "->no room in server\n  write a new room name"
    else
      @connections[:rooms].each{|room_name, user_list|
          client.puts("->" + room_name.to_s)
      }
    end
  end

  def list_users_inroom(username)
    msg = ""
    @connections[:rooms][@connections[:user_room][username]].each{ |other_user|
      unless other_user == username
        msg+="->"+other_user.to_s + "\n"
      end
    }
    msg
  end

  def new_room(room_name, nick_name)
    @connections[:rooms][room_name] = [nick_name]
    @connections[:user_room][nick_name] = room_name
  end

  def exit_chat(username)
    @connections[:clients][username].puts "Thank You for Connecting!"
    @connections[:clients][username].puts ":exit_server"
    @connections[:clients].delete(username)
    @connections[:rooms][@connections[:user_room][username]].delete(username)
    @connections[:user_room].delete(username)
    empty_room_delete
  end

  def broadcast_message(username,msg)
    @connections[:rooms][@connections[:user_room][username]].each { |other_name|
      unless other_name == username
        @connections[:clients][other_name].puts "#{username.to_s}: #{msg}"
      end
    }
  end

  def receive_message(client)
    msg = client.gets.chomp
    msg = msg.gsub("\\n" ,"\n")
    msg
  end

  def listen_user_messages( username, client )
    loop {
      msg = receive_message(client)
      #if msg == ":new_room"
      #  client.puts "Enter room name"
      #  room = client.gets.chomp.to_sym
      #  new_room(room, username)
      if msg == ":exit"
        broadcast_message(username, "exited")
        exit_chat(username)
        Thread.kill self
      elsif msg == ":list"
        client.puts(list_users_inroom(username))
      else
        broadcast_message(username, msg)
      end
    }
  end
end

Server.new( "localhost", 3000 )
