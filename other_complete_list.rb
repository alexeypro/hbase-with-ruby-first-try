#!/usr/bin/ruby

require 'rubygems'
require 'hbase'

client = HBase::Client.new('http://localhost:8080') 

class Topic
  attr_reader :id, :name, :description
  def from_hbase(hbase_row)
    return if hbase_row == nil
    @id = hbase_row.name
    hbase_row.columns.each do |column|
      @name = column.value if column.name == "content:name"            
      @description = column.value if column.name == "content:description"                  
      @created = Time.at(column.timestamp / 1000) if @created == nil
    end    
  end
  def to_s
    "\"#{@name}\": #{@description}"
  end
end

class Comment
  attr_reader :id, :body, :reply_to_id, :user_id
  def from_hbase(hbase_row)
    return if hbase_row == nil
    @id = hbase_row.name
    hbase_row.columns.each do |column|
      @body = column.value if column.name == "content:body"
      @user_id = column.value if column.name == "postinginfo:author"
      @reply_to_id = column.value if column.name == "postinginfo:replyto"
      @created = Time.at(column.timestamp / 1000) if @created == nil      
    end
  end
  def to_s
    "#{@body}"
  end
end

class User 
  attr_reader :id, :email, :password, :name
  def from_hbase(hbase_row)
    return if hbase_row == nil
    @id = hbase_row.name
    hbase_row.columns.each do |column|
      @email = column.value if column.name == "maininfo:email"
      @password = column.value if column.name == "maininfo:password"
      @name = column.value if column.name == "maininfo:fullname"            
      @created = Time.at(column.timestamp / 1000) if @created == nil
    end
  end
end

class UserComments
  attr_reader :user_id, :comments_id
  def from_hbase(hbase_row)
    return if hbase_row == nil
    @user_id = hbase_row.name
    @comments_id = []
    hbase_row.columns.each do |column|
      @comments_id << column.name.split(':').last
    end
  end
end

# get all users
scanner = client.open_scanner('userstable', { :columns => ['maininfo:fullname', 'maininfo:password', 'maininfo:email'] })
rows = client.get_rows(scanner)
users_to_show = []
rows.each do |row|
  user = User.new
  user.from_hbase(row)
  users_to_show << user
end
client.close_scanner(scanner)

# show comments to topics by user
users_to_show.each do |user|
  begin
    row = client.show_row('usersreferencestable', user.id)
  rescue
    # probably row was not found or something else
  end
  user_comments = UserComments.new
  user_comments.from_hbase(row)
  
  # fancy "output"
  print "User \"#{user.name}\" says: \n"
  if user_comments.comments_id == nil || user_comments.comments_id.empty?
    print "   (nothing, 0 comments)"
  else
    user_comments.comments_id.each do |comment_id|
      row = client.show_row('commentstable', comment_id)
      comment = Comment.new
      comment.from_hbase(row)      
      print "   ", comment.to_s, "\n"
    end
  end
  print "\n"
end
