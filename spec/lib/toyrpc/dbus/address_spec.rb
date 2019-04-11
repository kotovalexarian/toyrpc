# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ToyRPC::DBus::Address do
  subject { described_class.new value }

  let :value do
    [
      transport.to_s.tr('_', '-'),
      params.map { |k, v| "#{k}=#{v}" }.join(','),
    ].join ':'
  end

  let(:transport) { %i[unix launchd tcp nonce_tcp unixexec autolaunch].sample }

  let :params do
    Array.new(rand(1..10)).map do
      [
        %i[
          abstract
          argv0
          argv1
          bind
          dir
          env
          family
          host
          guid
          noncefile
          path
          port
          runtime
          scope
          tmpdir
        ].sample,
        SecureRandom.hex,
      ]
    end.to_h
  end

  pending '#to_unix_sockaddr'

  describe '#value' do
    specify do
      expect(subject.value).to be_instance_of String
    end

    specify do
      expect(subject.value).to be_frozen
    end

    specify do
      expect(subject.value).to eq value
    end
  end

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
      expect(subject.transport).to eq transport
    end
  end

  describe '#params' do
    specify do
      expect(subject.params).to be_instance_of Hash
    end

    specify do
      expect(subject.params).to be_frozen
    end

    specify do
      expect(subject.params.keys.all? { |k| k.instance_of? Symbol }).to eq true
    end

    specify do
      expect(
        subject.params.values.all? { |v| v.instance_of? String },
      ).to eq true
    end

    specify do
      expect(subject.params.values.all?(&:frozen?)).to eq true
    end

    specify do
      expect(subject.params).to eq params
    end
  end
end
