require 'spec_helper'
require 'support/models'
require 'settings_on_rails'

RSpec.describe SettingsOnRails do
  before(:each) { clear_database }

  describe 'column type validations' do
    context 'with exiting column of type text' do
      before { Blog.class_eval { has_settings_on :settings } }
      let(:blog) { Blog.new }

      it 'responds to the method' do
        expect(blog).to respond_to(:settings)
      end

      it 'is able to call the method' do
        expect{blog.settings}.not_to raise_error
      end
    end

    # context 'with non exist column' do
    #   before { Blog.class_eval { has_settings_on :other_column } }
    #   let(:blog) { Blog.new }

    #   it 'raises an error' do
    #     expect{blog.settings}.to raise_error(SettingsOnRails::ColumnNotExistError)
    #   end
    # end

    context 'with existing column of other types' do
      before { Blog.class_eval { has_settings_on :name } }
      let(:blog) { Blog.new }

      it 'raises an error' do
        expect{blog.settings}.to raise_error(SettingsOnRails::InvalidColumnTypeError)
      end
    end
  end

  describe '#settings' do
    before { Blog.class_eval { has_settings_on :settings } }
    let(:blog) { Blog.new }

    describe 'key validations' do
      let(:valid_keys) { %w(key KEY key_ key_1) }
      let(:invalid_keys) { %w(_key 1key) }

      context 'with valid keys' do
        it 'does not raise any errors' do
          valid_keys.each do |key|
            expect{ blog.settings.send(key + '=', 'value') }.not_to raise_error
          end
        end
      end

      context 'with invalid keys' do
        it 'does not raise any errors' do
          invalid_keys.each do |key|
            expect{ blog.settings.send(key + '=', 'value') }.to raise_error(NoMethodError)
          end
        end
      end
    end

    describe 'get/set attributes' do
      let(:attributes) { {enabled: false, title: 'text', number: 100} }

      context 'set and get attributes' do
        before do
          attributes.each do |k, v|
            blog.settings.send(k.to_s + '=', v)
          end
        end

        it 'returns the value as set' do
          attributes.each do |k, v|
            expect(blog.settings.send(k)).to eq v
          end
        end

        context 'after save' do
          before { blog.save }

          it 'returns the value as set' do
            attributes.each do |k, v|
              expect(blog.reload.settings.send(k)).to eq v
            end
          end
        end
      end
    end

    describe 'multiple/nested keys' do
      let(:text) { 'SETTINGS ON RAILS' }
      context 'set value with multiple keys' do
        before { blog.settings(:key1, :key2, :key3).value = text }

        it 'returns the correct value' do
          expect(blog.settings(:key1, :key2, :key3).value).to eq text
          expect(blog.settings(:key1).settings(:key2).settings(:key3).value).to eq text
          expect(blog.settings(:key1, :key2).settings(:key3).value).to eq text
          expect(blog.settings(:key1, :key2).settings(:key3).value).to eq text
        end
      end

      context 'set value with nested keys' do
        before { blog.settings(:key1).settings(:key2).settings(:key3).value = text }

        it 'returns the correct value' do
          expect(blog.settings(:key1, :key2, :key3).value).to eq text
          expect(blog.settings(:key1).settings(:key2).settings(:key3).value).to eq text
          expect(blog.settings(:key1, :key2).settings(:key3).value).to eq text
        end
      end
    end

    describe 'type of return value' do
      context 'when value is nil' do
        it 'returns settings object' do
          expect(blog.settings(:key1, :key2)).to be_instance_of SettingsOnRails::Settings
        end
      end

      context 'when value is Hash' do
        let(:settings) { blog.settings(:key1, :key2) }
        before { settings.key3 = { "enabled" => false } }

        it 'returns the settings object' do
          expect(settings.settings(:key3)).to be_instance_of SettingsOnRails::Settings
          expect(settings.settings(:key3).enabled).to eq false
        end
      end

      context 'when value is not nil or Hash' do
        before { blog.settings(:key1).settings(:key2).key3 = true }

        it 'returns the correct value' do
          expect(blog.settings(:key1, :key2, :key3)).to eq true
          expect(blog.settings(:key1, :key2).settings(:key3)).to eq true
        end
      end
    end

    describe 'hash functions' do
      let(:text) { 'SETTINGS ON RAILS' }
      context 'assign a new key to settings' do
        let(:settings_object) { blog.settings(:key1, :key2) }
        before { settings_object.settings(:key3).title = text }

        it 'operates on the hash object when passing a block' do
          expect(settings_object.any? {|key, value| key == 'key3' }).to eq true
        end

        it 'is a hash within different access object' do
          expect((settings_object.map {|key, value| value }).first).
              to be_instance_of ActiveSupport::HashWithIndifferentAccess
        end
      end
    end
  end
end
