require "socket"
class Client
  attr_accessor :response, :address, :port, :_output, :message, :message_set, :receiving_thread
  def initialize(iaddress="localhost", iport=3000, receiving_thread=nil)
    @response = nil
    @address = iaddress
    @port = iport
    @message_set = false
    @receiving_thread = receiving_thread
  end

  def connect
    @server = TCPSocket.open( address, port )
    listen
  end

  def message_unset
    self.message_set = false
    self.message = ""
  end

  def listen
    @response = Thread.new do
      loop {
        if self.message_set == false
          msg = @server.gets.chomp
          if msg == ":exit_server"
            puts "exiting server"
            Thread.kill @request
            Thread.kill Thread.current
            Thread.kill @receiving_thread
            message = msg
            message_set = true
          else
            self.message = msg
            self.message_set = true
          end
        end
      }
    end
  end

  def send(msg)
    if msg.empty?
      return
    end
    msg = msg.gsub(/\n/, "\\n")
    @server.puts(msg)
    #@request = Thread.new do
    #  loop {
    #    msg = $stdin.gets.chomp
    #    @server.puts( msg )

      #}
    #end
  end
end
