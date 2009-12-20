#!/usr/bin/ruby

require 'rubygems'
require 'hbase'

class User 
  attr_reader :id, :email, :password, :name, :created, :from_storage
  def create(email, password, name)  
    @email = email
    @password = password
    @name = name
    @created = Time.now
    @id = @created.strftime('%Y%m%d%H%M%S')    
    @from_storage = false
  end
  def from_hbase(hbase_row)
    @id = hbase_row.name
    hbase_row.columns.each do |column|
      @email = column.value if column.name == "maininfo:email"
      @password = column.value if column.name == "maininfo:password"
      @name = column.value if column.name == "maininfo:fullname"            
      @created = Time.at(column.timestamp / 1000) if @created == nil
    end
    @from_storage = true
  end
  def to_hbase()
    result = [ ]
    result << { :name => 'maininfo:email', :value => @email }
    result << { :name => 'maininfo:fullname', :value => @name }
    result << { :name => 'maininfo:password', :value => @password }
    return result
  end
end

def describe_user(user)
  print "Hello, \"#{user.name}\" <#{user.email}> \n"
  print "Your ID: #{user.id} and password: #{user.password} \n"
  print "You were created on #{user.created} \n"
  print "Loaded from storage: #{user.from_storage} \n"
  print "\n"
end

client = HBase::Client.new('http://localhost:8080') 

# just creating new user object
user = User.new()
user.create('test@test.com', 'somepassword', 'Test User')
describe_user(user)

# saving user object to storage
client.create_row('userstable', user.id, user.created.to_i, user.to_hbase)

# and load again
row = client.show_row('userstable', user.id)
user = User.new()
user.from_hbase(row)
describe_user(user)
