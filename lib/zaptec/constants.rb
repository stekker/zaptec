module Zaptec
  class Constants
    class << self
      def observation_state_id_to_name(state_id:, device_type:)
        device_type_observation_ids(device_type)
          .fetch(state_id)
      rescue KeyError
        "Unknown state id '#{state_id}' (device type '#{device_type}')"
      end

      def charger_operation_mode_to_name(operation_mode)
        constants
          .fetch("ChargerOperationModes")
          .detect { |_name, mode| mode == operation_mode }
          .then { |name, _mode| name }
      end

      def charger_operation_mode_name_to_mode(operation_mode_name)
        constants
          .fetch("ChargerOperationModes")
          .detect { |name, _mode| name == operation_mode_name.to_s }
          .then { |_name, mode| mode }
      end

      def command_to_command_id(command)
        constants
          .fetch("Commands")
          .fetch(command.to_s) { raise "Unknown command '#{command}'" }
      end

      def country_id_to_country_code(country_id)
        return if country_id.nil?

        constants
          .fetch("Countries")
          .fetch(country_id)
          .fetch("Code")
      end

      def network_type_to_name(network_type)
        constants
          .fetch("NetworkTypes")
          .detect { |_name, type| type == network_type }
          .then { |name, _type| name }
      end

      private

      def device_type_observation_ids(device_type)
        @device_type_observation_ids ||= {}

        @device_type_observation_ids[device_type] ||=
          begin
            global_observation_ids = constants.fetch("Observations").invert.transform_values(&:to_sym)

            device_specific_observations =
              constants
                .fetch("Schema")
                .fetch(device_type_to_name(device_type))
                .fetch("ObservationIds")
                .invert
                .transform_values(&:to_sym)

            global_observation_ids.merge(device_specific_observations)
          end
      end

      def device_type_to_name(device_type)
        constants
          .fetch("DeviceTypes")
          .detect { |_name, type| type == device_type }
          .then { |name, _type| name }
      end

      def constants
        @constants ||= JSON.parse(constants_file.read)
      end

      def constants_file = Pathname.new(__dir__).join("../../data/constants.json")
    end
  end
end
