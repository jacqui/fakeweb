
$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'open-uri'
require 'fake_web'
require 'rubygems'
require 'mocha'

module FakeWebTestHelper

  # Sets several expectations (using Mocha) that a real HTTP request makes it
  # past FakeWeb to the socket layer. You can use this when you need to check
  # that a request isn't handled by FakeWeb.
  def setup_expectations_for_real_request(options = {})
    # Socket handling
    if options[:port] == 443
      socket = mock("SSLSocket")
      OpenSSL::SSL::SSLSocket.expects(:===).with(socket).returns(true).at_least_once
      OpenSSL::SSL::SSLSocket.expects(:new).with(socket, instance_of(OpenSSL::SSL::SSLContext)).returns(socket).at_least_once
      socket.stubs(:sync_close=).returns(true)
      socket.expects(:connect).with().at_least_once
    else
      socket = mock("TCPSocket")
      Socket.expects(:===).with(socket).returns(true)
    end

    TCPSocket.expects(:open).with(options[:host], options[:port]).returns(socket).at_least_once
    socket.stubs(:closed?).returns(false)
    socket.stubs(:close).returns(true)

    # Request/response handling
    request_parts = ["#{options[:method]} #{options[:path]} HTTP/1.1", "Host: #{options[:host]}"]
    socket.expects(:write).with(all_of(includes(request_parts[0]), includes(request_parts[1]))).returns(100)

    # TODO: handle long response bodies that use more than one #sysread call
    socket.expects(:sysread).with(1024).at_least_once.returns("HTTP/1.1 #{options[:response_code]} #{options[:response_message]}\nContent-Length: #{options[:response_body].length}\n\n#{options[:response_body]}").then.raises(EOFError)
  end


  # A helper that calls #setup_expectations_for_real_request for you, using
  # defaults for our commonly used test request to images.apple.com.
  def setup_expectations_for_real_apple_hot_news_request(options = {})
    defaults = { :host => "images.apple.com", :port => 80, :method => "GET",
                 :path => "/main/rss/hotnews/hotnews.rss",
                 :response_code => 200, :response_message => "OK",
                 :response_body => "<title>Apple Hot News</title>" }
    setup_expectations_for_real_request(defaults.merge(options))
  end

end