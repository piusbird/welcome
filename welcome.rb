#!/usr/bin/env ruby

require "etc"
require "tty-prompt"
require "tty-screen"

def sep
  puts
  puts "~" * TTY::Screen.width
  puts
end

prompt = TTY::Prompt.new

system "clear"

# welcome
system "toilet -F gay -f script tilde.fur"
puts
puts "welcome to tilde.fur!!"
puts
puts "we're glad you're here!"
puts "let's walk through some basic questions to get you set up"

prompt.keypress("ready? press enter to continue")
puts

# change your password
sep
puts "step 1:"
puts "  first, let's change your shell password"
puts
puts "  you'll find the temporary password in your welcome email"
puts "  enter the current password once, followed by your new password twice"

success = false
until success do
  success = system "passwd"
end

# select your shell
sep
puts "step 2:"
puts "  now, let's pick your default shell"
puts
puts "  a shell is a program that handles commands you type"
puts "  bash is the most common shell and is a good place to start"
puts "  note that the list of shells extends beyond one page"
puts

shells = File.readlines("/etc/shells")
  .select { |line| !line.start_with?("#") }
  .map(&:chomp)
  .map { |line| [File.basename(line), line] }
  .to_h

shell = prompt.select("  which shell would you like to use?", shells, per_page: shells.count)
puts
puts "  great, you've picked #{shell}!"
puts "  in order to change your shell, you'll have to enter your password again"

success = false
until success do
  success = system "chsh -s #{shell}"
end

# default text editor
sep
puts "step 3:"
puts "  now, let's pick your default text editor"
puts
puts "  You can change the default command-line text"
puts "  editor used by various programs, such as crontab"
puts

editors = File.readlines("/etc/editors")
  .select { |line| !line.start_with?("#") }
  .map(&:chomp)
  .map { |line| [File.basename(line), line] }
  .to_h

editors = prompt.select("  which editor would you like to use?", editors, per_page: editors.count)
puts
puts "  great, you've picked #{editors}!"

success = false
until success do
  success = system "echo 'export EDITOR=#{editors}' >> #{Dir.home}/.profile"
end

# byobu or not
sep
puts "step 4:"
puts "  we recommend using a terminal multiplexer, which is a tool that allows you"
puts "  to have tabs in your shell and even disconnect while leaving things running"
puts "  as you left them."
puts
puts "  the tool we recommend is byobu: https://superuser.com/a/423397/866501"
puts
puts "  if you're not sure about this, decline for now. you can set it up at any time"
puts "  later on by running 'byobu-enable' from your shell."
puts

enable_byobu = prompt.yes?("  would you like to set byobu to launch automatically when you log in?")

if enable_byobu
  system "byobu-enable"
  puts "our default configs will connect you to chat and open a mail client when you log in"
end

# tz
sep
puts "step 5:"
puts "  great, let's set up your timezone!"
puts
tz = %x{tzselect}.chomp
puts
puts "  you selected #{tz}, adding this to your ~/.profile now"
puts "  it might not take effect until you log out and back in"
open("#{Dir.home}/.profile", "a") { |f| f.puts "export TZ='#{tz}'" }

# email forwarding
sep
puts "step 6:"
puts "  tilde.fur has a standard mailserver that you can use to send"
puts "  and receive mail using #{Etc.getlogin}@tilde.fur"
puts

if prompt.yes?("  would you like to forward your mail elsewhere?")
  forward_addr = prompt.ask("  where would you like to forward your mail to?") do |q|
    q.validate(/\A\w+@\w+\.\w+\Z/)
    q.messages[:valid?] = "Invalid email address"
  end

  File.open("#{Dir.home}/.forward", "w") { |f| f.puts forward_addr }
  puts "  ok, your mail will now be sent off to #{forward_addr}"
  puts "  you can update this in your ~/.forward file"
  puts "  if you remove the file, you can use our mailserver as usual without forwarding"
else
  puts "  alright, your mail won't be forwarded anywhere."
  puts "  you can use any standard mail client with smtp and imap"
  puts "  to access your @tilde.fur email"
  puts "  see the wiki page for more information: https://tilde.fur/wiki/email.html"
  puts
  puts "  if you decide to forward your mail in the future, you can do so"
  puts "  by putting the destination address in a file called ~/.forward"
  puts "  eg: echo \"me@example.com\" > ~/.forward"
end
puts

sep
puts

# pronouns
sep
puts "step 8:"
pronouns = prompt.ask("  what are your preferred pronouns?")
puts "  saving your pronouns to your ~/.pronouns file."
puts "  feel free to update it as needed!"
open("#{Dir.home}/.pronouns", "w") { |f| f.puts pronouns }

# welcome completed
sep
puts "welcome to the ~fur!"
puts
puts "please come stop by chat when you get a chance by running the 'chat' command" unless enable_byobu
puts "we're happy to help as needed and get you any information you're looking for"
puts "have a look at our wiki: https://tilde.fur/wiki/ (ctrl-click will let you open that from here)"
puts "if you need to run this wizard again, you can do so with the `firstlogin` command"
File.delete("#{Dir.home}/.new_user")

if enable_byobu
  exec "byobu"
end
