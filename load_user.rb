#!/usr/bin/ruby

require 'rubygems'
require 'hbase'

class User 
  attr_reader :id, :email, :password, :name, :created
  def initialize(hbase_row)
    @id = hbase_row.name
    hbase_row.columns.each do |column|
      @email = column.value if column.name == "maininfo:email"
      @password = column.value if column.name == "maininfo:password"
      @name = column.value if column.name == "maininfo:fullname"            
      @created = Time.at(column.timestamp) if @created == nil
    end
  end
end

def hello_user(user)
  print "Hello, \"#{user.name}\" <#{user.email}> \n"
  print "Your ID: #{user.id} and password: #{user.password} \n"
  print "You were created on #{user.created}\n"
  print "\n"
end

client = HBase::Client.new("http://localhost:60050/api") 

row = client.show_row('userstable', '20091213093540')
user = User.new(row)
hello_user(user)

row = client.show_row('userstable', '20091213120030')
user = User.new(row)
hello_user(user)

