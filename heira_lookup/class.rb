#!/usr/bin/env ruby

require 'syck'

class Key
  def initialize()
    @hash = Hash.new
    @hosts = Array.new
  end
  
  def hosts
    return @hosts
  end
  
  def hash
    return @hash
  end
 
  def add_hosts(host)
    @hosts = @hosts << host
    return @hosts
  end
  
  def print(level)
    if !@hash.empty?
      num = 0
      str = ""
      while num < level do
        str = str + "|   "
        num = num+1
      end
      @hash.each_pair do |key, value|
        #puts "#{str}#{key}"
        @count=0
        value.hosts.each do |host|
          @count=@count+1
          #puts "   #{str}#{host}"
        end
        if key.kind_of?(String)
          key.lines do |line|
            puts "#{str}#{line}"
          end
        else
          puts "#{str}#{key}:"
        end
        puts "#{str}refs:#{@count}"
        value.print(level+1)
      end
    end
  end
  
  def add_value(key, value, host)
   # puts "#{key}	#{value}	#{host}"
    @hash.store(key, Key.new()) unless @hash.has_key?(key)
    key_obj = @hash.fetch(key)
    key_obj.add_hosts(host)
    key_hash = key_obj.hash
    
    if value.kind_of?(Hash)
      value.each do |hash_key, val|
        key_obj.add_value(hash_key, val, host)
      end
    elsif value.kind_of?(Array)
      value.collect
      value.each do |val|
      	add_value(key, val, host)
      end
    else
      #if value.kind_of?(String)
        #value = value.delete "\n"
     # end
      key_hash.store(value, Key.new()) unless key_hash.has_key?(value)
      v = key_hash.fetch(value)
      v.add_hosts(host)
    end
  end
  
end


class Run
  def self.use_yaml(file)
    yp = YAML::Syck::Parser.new( {} ) 
    if File.file?(file)
      if @data = yp.load( File::open( file ).read) 
      #@this, @that = file.split(/.*\/.*\//, 2)
      #@host = @that.gsub(/\..*/, '')
        @host = file.split(/[\.\_.*]/)
        @data.each_pair do |key, value|
          #puts "#{key}"
          #puts "#{@host}"
          $k.add_value(key, value, @host)
        end
      end
    else
      puts "fail file"
    end
  end

  def self.start
    $k = Key.new()
    Dir.chdir("/etc/puppet/heiradata")
    Dir.for_each do |file_or_dir|
       File.directory?(file_or_dir) 
        Dir.chdir(file_or_dir)
    Dir.glob("*yaml") do |item|
      next if item == '.' or item == '..'
      #puts "#{dir}"
      p = use_yaml(item);
    end
    $k.print(0)
   end
end

Run.start
