# frozen_string_literal: true

RSpec.describe RubyJard::Commands::DownCommand do
  subject(:command_object) { described_class.new }

  it_behaves_like 'command with times', :down, :down do
  end
end
