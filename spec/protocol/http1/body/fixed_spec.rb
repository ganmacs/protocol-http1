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

require 'protocol/http1/body/fixed'
require 'async/rspec/buffer'

RSpec.describe Protocol::HTTP1::Body::Fixed do
	include_context Async::RSpec::Memory
	include_context Async::RSpec::Buffer
	
	let(:content) {"Hello World"}
	let(:stream) {Async::IO::Stream.new(buffer)}
	subject! {described_class.new(stream, content.bytesize)}
	
	before do
		buffer.write content
		buffer.seek(0)
	end
	
	describe "#empty?" do
		it "returns whether EOF was reached" do
			expect(subject.empty?).to be == false
		end
	end
	
	describe "#stop" do
		it "closes the stream" do
			subject.close(EOFError)
			expect(stream).to be_closed
		end
		
		it "doesn't close the stream when EOF was reached" do
			subject.read
			subject.close(EOFError)
			expect(stream).not_to be_closed
		end
	end
	
	describe "#read" do
		it "retrieves chunks of content" do
			expect(subject.read).to be == "Hello World"
			expect(subject.read).to be == nil
		end
		
		it "updates number of bytes retrieved" do
			subject.read
			expect(subject).to be_empty
		end
		
		context "when provided length is smaller than stream size" do
			subject {described_class.new(stream, 5)}
			
			it "retrieves content up to provided length" do
				expect(subject.read).to be == "Hello"
				expect(subject.read).to be == nil
			end
			
			it "updates number of bytes retrieved" do
				subject.read
				expect(subject).to be_empty
			end
		end
		
		context "with large stream" do
			let(:content) {"a" * 5*1024*1024}
			
			it "allocates expected amount of memory" do
				expect do
					subject.read.clear until subject.empty?
				end.to limit_allocations(size: 0)
			end
		end
	end
	
	describe "#join" do
		it "returns all content" do
			expect(subject.join).to be == "Hello World"
			expect(subject.join).to be == ""
		end
		
		it "updates number of bytes retrieved" do
			subject.read
			expect(subject).to be_empty
		end
	end
end
