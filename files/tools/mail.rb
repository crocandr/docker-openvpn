#!/usr/bin/ruby

require 'net/smtp'
require 'optparse'

def_subject = "VPN Notice"

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

options[:server] ? ( server = options[:server] ) : ( abort("No mail server defined") )
options[:subject] ? ( subject = options[:subject] ) : ( subject = def_subject )
options[:from] ? ( from = options[:from] ) : ( abort("No from address defined") )
options[:mailto] ? ( mailto = options[:mailto] ) : ( abort("No recipient defined") ) 
# check message
if options[:message] == nil
    abort("No message defined")
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
