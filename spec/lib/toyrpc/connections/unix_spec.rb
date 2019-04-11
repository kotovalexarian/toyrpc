# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ToyRPC::Connections::Unix do
  subject { described_class.new sockaddr, marshaller, unmarshaller }

  let(:sockaddr) { Socket.pack_sockaddr_un socket_filename }
  let(:socket_filename) { File.join Dir.tmpdir, socket_basename }
  let(:socket_basename) { SecureRandom.hex }

  let :marshaller do
    lambda do |message|
      message.downcase
    end
  end

  let :unmarshaller do
    lambda do |buffer|
      buffer.upcase
    end
  end

  let! :thread do
    server = UNIXServer.new socket_filename

    Thread.start do
      socket = server.accept

      loop do
        socket.read_nonblock 1024
      rescue IO::WaitReadable
        IO.select [socket]
        retry
      end
    end
  end

  after do
    thread.kill
    File.delete socket_filename
  end

  pending '#write_message'
  pending '#read_message'
  pending '#flush_read_buffer'
  pending '#flush_write_buffer'

  describe '#to_io' do
    specify do
      expect(subject.to_io).to be_instance_of Socket
    end
  end

  describe '#marshaller' do
    specify do
      expect(subject.marshaller).to equal marshaller
    end
  end

  describe '#unmarshaller' do
    specify do
      expect(subject.unmarshaller).to equal unmarshaller
    end
  end

  describe '#read_buffer_cap' do
    specify do
      expect(subject.read_buffer_cap).to be_instance_of Integer
    end

    specify do
      expect(subject.read_buffer_cap).to be_positive
    end

    specify do
      expect(subject.read_buffer_cap).to \
        eq described_class::DEFAULT_READ_BUFFER_CAP
    end

    context 'when read buffer capacity was specified' do
      subject do
        described_class.new sockaddr, marshaller, unmarshaller,
                            read_buffer_cap: read_buffer_cap
      end

      let(:read_buffer_cap) { rand 1..65_536 }

      specify do
        expect(subject.read_buffer_cap).to be_instance_of Integer
      end

      specify do
        expect(subject.read_buffer_cap).to eq read_buffer_cap
      end
    end
  end

  describe '#write_buffer_cap' do
    specify do
      expect(subject.write_buffer_cap).to be_instance_of Integer
    end

    specify do
      expect(subject.write_buffer_cap).to be_positive
    end

    specify do
      expect(subject.write_buffer_cap).to \
        eq described_class::DEFAULT_WRITE_BUFFER_CAP
    end

    context 'when write buffer capacity was specified' do
      subject do
        described_class.new sockaddr, marshaller, unmarshaller,
                            write_buffer_cap: write_buffer_cap
      end

      let(:write_buffer_cap) { rand 1..65_536 }

      specify do
        expect(subject.write_buffer_cap).to be_instance_of Integer
      end

      specify do
        expect(subject.write_buffer_cap).to eq write_buffer_cap
      end
    end
  end
end
