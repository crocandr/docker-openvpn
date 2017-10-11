#!/usr/bin/ruby

require 'net/smtp'
require 'optparse'

def_server = "192.168.10.254"
def_subject = "VPN Notice"
def_from = "noreply@mycompany.com"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: <this program.rb> [options]"

  opts.on('-x', '--server SERVER', 'address of the smtp server') { |server| options[:server] = server }
  opts.on('-t', '--mailto EMAILADDRESS', 'mail recipient') { |mailto| options[:mailto] = mailto }
  opts.on('-s', '--subject TEXT', 'subject of the mail') { |subject| options[:subject] = subject }
  opts.on('-f', '--from EMAILADDRESS', 'from address of the mail') { |from| options[:from] = from }
  opts.on('-m', '--message TEXT', 'message or path to a message file' ) { |message| options[:message] = message }

  opts.on('-h', '--help', 'display help') { puts opts }

end.parse!

options[:server] ? ( server = options[:server] ) : ( server = def_server )
options[:subject] ? ( subject = options[:subject] ) : ( subject = def_subject )
options[:from] ? ( from = options[:from] ) : ( from = def_from )
# check recipient of the mail
if options[:mailto] == nil
    puts "No recipient defined"
    exit
  else
    mailto = options[:mailto]
end
# check message
if options[:message] == nil
    puts "No message defined"
    exit
  else
    # message is a file or a simple message?
    if File.exist?(options[:message])
      message = File.read(options[:message])
    else  
      message = options[:message]
    end
end

# concatenate mail body
mailmsg="Subject: " + subject + "\n" + message

# send message
Net::SMTP.start(server) do |smtp|
  smtp.send_message mailmsg, from , mailto
end
