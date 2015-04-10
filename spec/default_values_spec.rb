require 'spec_helper'
require 'support/models'
require 'settings_on_rails'

RSpec.describe 'DefaultsHandler' do
  before(:each) { clear_database }

  describe '.has_settings' do
    before { Blog.class_eval { has_settings_on :settings } }

    describe '#has_key' do
      it 'responds to the method' do
        expect do
          Blog.class_eval do
            has_settings(:theme).has_settings(:homepage) do |s|
              s.key :background, defaults: { color: 'red', image: 'bg.png' }
              s.attr :text_size, default: 50
            end
          end
        end.not_to raise_error
      end

      describe 'default values' do
        before do
          Blog.class_eval do
            has_settings(:theme).has_settings(:homepage) do |s|
              s.key :background, defaults: { color: 'red', image: 'bg.png' }
              s.attr :text_size, default: 50
            end
          end
        end
        subject { Blog.new }

        it 'returns the default value', focus: true do
          expect(Blog.new.settings(:theme).settings(:homepage).text_size).to eq 50
        end
      end
    end
  end
end
