# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006-2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	clients/add-on-creator.ycp
# Package:	Configuration of add-on-creator
# Summary:	Main file
# Authors:	Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
#
# Main file for add-on-creator configuration. Uses all other files.
module Yast
  module AddOnCreatorWizardsInclude
    def initialize_add_on_creator_wizards(include_target)
      textdomain "add-on-creator"

      Yast.import "Popup"
      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "add-on-creator/complex.rb"
      Yast.include include_target, "add-on-creator/dialogs.rb"
      Yast.include include_target, "add-on-creator/patterns.rb"
    end

    # fill the defaults for content file
    def GenerateContent
      AddOnCreator.FillContentDefaults
      :next
    end

    # import data from existing product
    def CopyExisting
      # busy message
      Popup.ShowFeedback("", _("Importing product..."))

      AddOnCreator.ImportExistingProduct(AddOnCreator.import_path)

      Popup.ClearFeedback
      :next
    end

    # save the data with current configuration into global list
    def Commit
      AddOnCreator.CommitCurrentProduct
      :next
    end

    # if there are no Add-On products configured, open creation sequence
    def FirstDialog
      if Ops.greater_than(Builtins.size(AddOnCreator.add_on_products), 0)
        return :summary
      end
      AddOnCreator.selected_product = -1
      :new
    end

    # Main workflow of the add-on-creator configuration: create or edit Add-On
    # @return sequence result
    def MainSequence
      aliases = {
        "new"      => lambda { NewProductDialog() },
        "content"  => lambda { ContentFileDialog() },
        "sources"  => lambda { SourcesDialog() },
        "expert1"  => lambda { ExpertSettingsDialog() },
        "expert2"  => lambda { ExpertSettingsDialog2() },
        "packages" => lambda { PackagesDialog() },
        "patterns" => lambda { PatternsDialog() },
        "signing"  => lambda { SigningDialog() },
        "output"   => lambda { OutputDialog() },
        "overview" => lambda { OverviewDialog() },
        "workflow" => lambda { WorkflowConfigurationDialog() },
        "copy"     => [lambda { CopyExisting() }, true],
        "generate" => [lambda { GenerateContent() }, true],
        "commit"   => lambda { Commit() }
      }
      start_dialog = AddOnCreator.selected_product == -1 ? "new" : "sources"
      sequence = {
        "ws_start" => start_dialog,
        "new"      => { :abort => :abort, :next => "sources", :copy => "copy" },
        "sources"  => {
          :abort    => :abort,
          :next     => "generate",
          :skip_gen => "content"
        },
        "copy"     => { :next => "generate" },
        "generate" => { :next => "content" },
        "content"  => { :abort => :abort, :next => "packages" },
        "packages" => { :abort => :abort, :next => "patterns" },
        "patterns" => { :abort => :abort, :next => "output" },
        "output"   => {
          :abort    => :abort,
          :next     => "signing",
          :expert   => "expert1",
          :workflow => "workflow"
        },
        "workflow" => { :abort => :abort, :next => "output" },
        "signing"  => { :abort => :abort, :next => "overview" },
        "overview" => {
          :abort => :abort,
          #	    `next	: `next,
          :next  => "commit"
        },
        "commit" =>
          #	    `next	: "summary",
          { :next => :next },
        "expert1"  => { :abort => :abort, :next => "expert2" },
        "expert2"  => { :abort => :abort, :next => "output" }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of add-on-creator
    # @return sequence result
    def AddOnCreatorSequence
      aliases = {
        "read"    => [lambda { ReadDialog() }, true],
        "start"   => [lambda { FirstDialog() }, true],
        "summary" => lambda { SummaryDialog() },
        "build"   => lambda { BuildDialog() },
        "main"    => lambda { MainSequence() },
        "write"   => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "start" },
        "start"    => { :summary => "summary", :new => "main" },
        "summary"  => {
          :abort => :abort,
          :next  => :next,
          :new   => "main",
          :edit  => "main",
          :build => "build",
          :next  => "write"
        },
        "build"    => { :next => "summary", :abort => "summary" },
        "main"     => { :abort => "summary", :next => "summary" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
