# frozen_string_literal: true

require 'spec_helper'

require 'toyrpc/dbus'

RSpec.describe ToyRPC::DBus::Address do
  subject { described_class.new value }

  let(:value) { 'tcp:host=127.0.0.1,port=12345,family=ipv4' }

  describe '#to_s' do
    specify do
      expect(subject.to_s).to be_instance_of String
    end

    specify do
      expect(subject.to_s).to be_frozen
    end

    specify do
      expect(subject.to_s).to eq value
    end
  end

  describe '#inspect' do
    specify do
      expect(subject.inspect).to be_instance_of String
    end

    specify do
      expect(subject.inspect).to be_frozen
    end

    specify do
      expect(subject.inspect).to eq "#<#{described_class}: #{value}>"
    end
  end

  describe '#transport' do
    specify do
      expect(subject.transport).to eq :tcp
    end

    specify do
      expect(subject.tcp?).to eq true
    end

    specify do
      expect(subject.unix?).to eq false
    end
  end

  describe '#params' do
    specify do
      expect(subject.params).to eq(
        host:   '127.0.0.1',
        port:   '12345',
        family: 'ipv4',
      )
    end

    specify do
      expect(subject.params).to be_frozen
    end

    specify do
      expect(subject.params.values.all?(&:frozen?)).to eq true
    end
  end
end
