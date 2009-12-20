#!/usr/bin/ruby

require 'rubygems'
require 'hbase'

client = HBase::Client.new('http://localhost:8080') 

class Topic
  attr_reader :id, :name, :description
  def from_hbase(hbase_row)
    @id = hbase_row.object_id
    hbase_row.columns.each do |column|
      @name = column.value if column.name == "content:name"            
      @description = column.value if column.name == "content:description"                  
      @created = Time.at(column.timestamp / 1000) if @created == nil
    end    
  end
  def to_s
    "ID: \"#{@id}\", Name: \"#{@name}\" (#{@created}) \n    \"#{@description}\""
  end
end

scanner = client.open_scanner('topicstable', { :columns => ['content:name', 'content:description'] })
rows = client.get_rows(scanner)

rows.each do |row|
  topic = Topic.new
  topic.from_hbase(row)
  print topic.to_s, "\n"
end

client.close_scanner(scanner)
