# encoding: utf-8

module Yast
  class AddOnCreatorClient < Client
    def main
      # testedfiles: AddOnCreator.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "AddOnCreator"

      DUMP("AddOnCreator::Modified")
      TEST(lambda { AddOnCreator.Modified }, [], nil)

      nil
    end
  end
end

Yast::AddOnCreatorClient.new.main
