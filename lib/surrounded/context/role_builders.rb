module Surrounded
  module Context
    module RoleBuilders

      # Define behaviors for your role players
      def role(name, type=default_role_type, &block)
        if type == :module
          mod_name = RoleBuilders.mod_name(name)
          mod = Module.new(&block).send(:include, ::Surrounded)
          private_const_set(mod_name, mod)
        else
          meth = method(type)
          meth.call(name, &block)
        end
      rescue NameError => e
        raise e.extend(InvalidRoleType)
      end
      alias_method :role_methods, :role

      # Create a named behavior for a role using the standard library SimpleDelegator.
      def wrap(name, &block)
        require 'delegate'
        wrapper_name = RoleBuilders.mod_name(name)
        klass = private_const_set(wrapper_name, Class.new(SimpleDelegator, &block))
        klass.send(:include, Surrounded)
      end
      alias_method :wrapper, :wrap


      # Create an object which will bind methods to the role player
      def interface(name, &block)
        class_basename = RoleBuilders.mod_name(name)
        interface_name = class_basename + 'Interface'

        behavior = private_const_set(interface_name, Module.new(&block))

        require 'surrounded/context/negotiator'
        undef_method(name)
        define_method(name) do
          instance_variable_set("@#{name}", Negotiator.new(role_map.assigned_player(name), behavior))
        end
      end
      
      def self.mod_name(name)
        name.to_s.gsub(/(?:^|_)([a-z])/){ $1.upcase }
      end

    end
  end
end