#!/usr/bin/ruby

require 'rubygems'
require 'hbase'

client = HBase::Client.new('http://localhost:8080') 

class Topic
  attr_reader :id, :name, :description
  def from_hbase(hbase_row)
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
    @id = hbase_row.name
    hbase_row.columns.each do |column|
      @email = column.value if column.name == "maininfo:email"
      @password = column.value if column.name == "maininfo:password"
      @name = column.value if column.name == "maininfo:fullname"            
      @created = Time.at(column.timestamp / 1000) if @created == nil
    end
  end
end

# get all topics
scanner = client.open_scanner('topicstable', { :columns => ['content:name', 'content:description'] })
rows = client.get_rows(scanner)
topics_to_show = []
rows.each do |row|
  topic = Topic.new
  topic.from_hbase(row)
  topics_to_show << topic
end
client.close_scanner(scanner)

# get comments to fetched topics
topics_to_show.each do |topic|
  print topic.to_s, "\n"
  scanner = client.open_scanner('commentstable', { :start_row => topic.id.to_s + '-', 
                                                   :end_row => topic.id.to_s + '-99999999999999-99999999999999', 
                                                   :columns => ['content:body', 'postinginfo:author', 'postinginfo:replyto'] })
  rows = client.get_rows(scanner)
  rows.each do |row|
    comment = Comment.new
    comment.from_hbase(row)
    
    # load user associated with comment
    row = client.show_row('userstable', comment.user_id)
    user = User.new
    user.from_hbase(row)
    
    # check if this comment is reply to another one
    reply_comment = nil
    if comment.reply_to_id != nil && !comment.reply_to_id.empty?
      row = client.show_row('commentstable', comment.reply_to_id)      
      reply_comment = Comment.new
      reply_comment.from_hbase(row)
    end
    
    # just "fancy" output
    print "   ", user.name, ": ", comment.to_s
    print " (reply to: ", reply_comment.to_s, ")" unless reply_comment == nil
    print "\n"
    
  end
  client.close_scanner(scanner)  
end
