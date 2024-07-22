module SettingsOnRails
  module Configuration
    NAME_COLUMN = :settings_column_name
    DEFAULTS_COLUMN = :default_settings

    # Initialize needed variables for given class
    # @param [ActiveRecord] klass, the Model who has settings
    # @param [Symbol] column, the column to store settings
    def self.init(klass, column)
      unless column.is_a?(Symbol) || column.is_a?(String)
        raise ArgumentError.new("has_settings_on: symbol or string expected, but got a #{column.class}")
      end

      klass.class_eval do
        class_attribute Configuration::NAME_COLUMN, Configuration::DEFAULTS_COLUMN

        if ActiveRecord.version > Gem::Version.new('7.1')
          serialize column, type: ActiveSupport::HashWithIndifferentAccess, coder: YAML
        else
          serialize column, ActiveSupport::HashWithIndifferentAccess
        end

        Configuration::init_defaults_column(self)
        Configuration::init_name_column(self, column)
      end
    end

    # Returns the name of settings column for that instance
    def self.column_name(instance)
      instance.class.send(Configuration::NAME_COLUMN)
    end

    # Check for the validity of the settings column
    # Returns the column name if valid
    def self.check!(instance)
      settings_column_name = column_name(instance)
      raise NoSettingsColumnError unless settings_column_name
      raise ColumnNotExistError unless instance.has_attribute?(settings_column_name)
      raise InvalidColumnTypeError if column_type_not_text?(instance, settings_column_name)

      settings_column_name
    end

    # init to Hash {} for data attribute in klass if nil
    def self.init_defaults_column(klass)
      defaults = klass.send(Configuration::DEFAULTS_COLUMN)
      klass.send(Configuration::DEFAULTS_COLUMN.to_s + '=', ActiveSupport::HashWithIndifferentAccess.new) unless defaults
    end

    def self.init_name_column(klass, column_name)
      klass.send(Configuration::NAME_COLUMN.to_s + '=', column_name)
    end


    private

    def self.column_type_not_text?(instance, settings_column)
      return false if instance.column_for_attribute(settings_column).sql_type.nil?

      instance.column_for_attribute(settings_column).try(:sql_type).downcase != 'text'
    end
  end
end
