require 'spec_helper'

describe Kracken do
  it "#setup yields the config block" do
    expect { |b| Kracken.setup(&b) }.to yield_with_args(Kracken.config)
  end
end
