require_relative "client"
require "gtk3"

$receiving_message = Thread.new do
  loop {
    if $client.message_set == true
      msg = $client.message
      chat_view = $builder.get_object('main_chat')
      iter = chat_view.buffer.end_iter
      chat_view.buffer.insert(iter, "\n"+ msg)
      update_scroll
      $client.message_unset
    end
  }
end

$client = Client.new()
$builder = Gtk::Builder.new
main_window_res = 'window.glade'
$builder.add_from_file(main_window_res)

def update_scroll
  chat_view = $builder.get_object('main_chat')
  scroll = $builder.get_object('scroll_window')
  chat_view.signal_connect("size-allocate") do
    scroll.vadjustment.value = scroll.vadjustment.upper -
    scroll.vadjustment.page_size
  end
end

def client_connect
  port = $builder.get_object('port')
  host = $builder.get_object('host')
  address = host.buffer.text
  port = port.buffer.text
  $client.address = address
  $client.port = port.to_i
  $client.receiving_thread = $receiving_message
  begin
    $client.connect
    server_write_to_chat("Connected to server")
  rescue
    server_write_to_chat("Was not able to connect")
  end
  connect_button = $builder.get_object('connect')
  connect_button.label = 'Disconnect'
end

def client_disconnect
  $client.send(":exit")
  connect_button = $builder.get_object('connect')
  connect_button.label = 'Connect'
end

def connect_clicked_cb(object)
  connect_button = $builder.get_object('connect')
  if connect_button.label == "Connect"
    client_connect
  else
    client_disconnect
  end
end

def fetch_message_from_input
  input_text = $builder.get_object('input_text')
  message = input_text.buffer.text.chomp
  input_text.buffer.text = ""
  message
end

def server_write_to_chat(msg)
  if msg.empty?
    return
  end
  chat_view = $builder.get_object('main_chat')
  iter = chat_view.buffer.end_iter
  chat_view.buffer.insert(iter, "\n"+ msg)
end

def self_write_to_chat(msg)
  if msg.empty?
    return
  end
  chat_view = $builder.get_object('main_chat')
  iter = chat_view.buffer.end_iter
  chat_view.buffer.insert(iter, "\nYou:"+ msg)
end

def input_text_activate_cb(object)
  message = fetch_message_from_input
  puts message
  self_write_to_chat(message)
  $client.send(message)
end

def send_button_clicked_cb(object)
  message = fetch_message_from_input
  puts message
  puts "buttonclicked"
  self_write_to_chat(message)
  $client.send(message)
end

def on_main_window_destroy(object)
  begin
  $client.send(':exit')
  Thread.kill $client.response
  rescue
    puts 'exiting'
  end
  Thread.kill $receiving_message
  Gtk.main_quit()
  exit
end

def about_menu_option_click_cb
  about_builder = Gtk::Builder.new
  window_res = 'about.glade'
  about_builder.add_from_file(window_res)
  about = about_builder.get_object('about')
  about.run
  about.destroy
end

def command_menu_option_cb
  command_builder = Gtk::Builder.new
  command_res = 'command.glade'
  command_builder.add_from_file(command_res)
  command = command_builder.get_object('command')
  command.run
  command.destroy
end


#def on_about_destroy(object)
#  gtk_widget_destroy(object)
#end

# Attach signals handlers
$builder.connect_signals do |handler|
  begin
    method(handler)
  rescue
    puts "#{handler} not yet implemented!"
    method('not_yet_implemented')
  end
end

main_window = $builder.get_object('main_window')
main_window.show()

Gtk.main
