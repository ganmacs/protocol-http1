# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../connection_context'

require 'protocol/http1/body/chunked'

require 'async/io/stream'
require 'async/rspec/buffer'

RSpec.describe Protocol::HTTP1::Body::Chunked do
	include_context Async::RSpec::Memory
	include_context Protocol::HTTP1::Connection
	
	let(:content) {"Hello World"}
	subject! {described_class.new(client)}
	
	before do
		sockets.last.write "#{content.bytesize.to_s(16)}\r\n#{content}\r\n0\r\n\r\n"
		sockets.last.close
	end
	
	describe "#empty?" do
		it "returns whether EOF was reached" do
			expect(subject.empty?).to be == false
		end
	end
	
	describe "#stop" do
		it "closes the stream" do
			subject.close(EOFError)
			expect(client.stream).to be_closed
		end
		
		it "marks body as finished" do
			subject.close(EOFError)
			expect(subject).to be_empty
		end
	end
	
	describe "#read" do
		it "retrieves chunks of content" do
			expect(subject.read).to be == "Hello World"
			expect(subject.read).to be == nil
			expect(subject.read).to be == nil
		end
		
		it "updates number of bytes retrieved" do
			subject.read
			subject.read # realizes there are no more chunks
			expect(subject).to be_empty
		end
		
		xcontext "with large stream" do
			let!(:content) {"a" * 1024}
			
			it "allocates expected amount of memory" do
				expect do
					while chunk = subject.read
						chunk.clear
					end
				end.to limit_allocations.of(String, size: 0).of(Hash, count: 8)
			end
		end
	end
end
