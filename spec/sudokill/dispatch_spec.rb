require 'spec_helper'

describe Sudokill::Dispatch do
  describe "call" do
    before(:each) do
      @dispatch = Sudokill::Dispatch.new
    end
    it "should set data as name if name is nil" do
      @dispatch.call("Rossta")
      @dispatch.name.should == "Rossta"
    end
    describe "name is set" do
      before(:each) do
        @dispatch.name = "Rossta"
      end
      it "should send move request if matches game move" do
        @dispatch.call("0 0 3").should == [:move, "0 0 3"]
      end
    end
  end
end
