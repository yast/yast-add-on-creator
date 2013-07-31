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

# File:	include/add-on-creator/complex.ycp
# Package:	Add-On Creator
# Summary:	Dialogs definitions
# Authors:	Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
module Yast
  module AddOnCreatorComplexInclude
    def initialize_add_on_creator_complex(include_target)
      Yast.import "UI"

      textdomain "add-on-creator"

      Yast.import "AddOnCreator"
      Yast.import "FileUtils"
      Yast.import "Label"
      Yast.import "Message"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "Report"
      Yast.import "String"
      Yast.import "Summary"
      Yast.import "Wizard"
      Yast.import "UIHelper"


      Yast.include include_target, "add-on-creator/helps.rb"



      # -----------------------------------------------------------------------

      # how to show and handle package descriptions keys
      @description_descr = deep_copy(AddOnCreator.description_descr)
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      AddOnCreator.Modified
    end

    def ReallyAbort
      !AddOnCreator.Modified || Popup.ReallyAbort(true)
    end

    def PollAbort
      UI.PollInput == :abort
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      ret = AddOnCreator.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      ret = AddOnCreator.Write
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def BuildDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "build", ""))
      ret = AddOnCreator.BuildAddOn
      ret ? :next : :abort
    end

    # Summary dialog with the list of all configured AddOn Products
    def SummaryDialog
      # dialog caption
      caption = _("Add-on Creator Configuration Overview")

      add_on_products = deep_copy(AddOnCreator.add_on_products)

      get_summary_items = lambda do
        i = -1
        Builtins.maplist(add_on_products) do |add_on|
          content_map = Ops.get_map(add_on, "content_map", {})
          i = Ops.add(i, 1)
          Item(
            Id(i),
            Ops.get_string(
              content_map,
              "LABEL",
              Ops.get_string(content_map, "NAME", "")
            ),
            Ops.get_string(content_map, "VERSION", "")
          )
        end
      end
      summary_items = get_summary_items.call

      # generate description of selected product
      get_description = lambda do |add_on|
        add_on = deep_copy(add_on)
        content_map = Ops.get_map(add_on, "content_map", {})
        ret2 = Ops.add(
          # summary item
          Builtins.sformat(
            _("Input directory: %1<br>"),
            Ops.get_string(add_on, "rpm_path", "")
          ),
          # summary item
          Builtins.sformat(
            _("Output directory: %1<br>"),
            Ops.get_string(add_on, "base_output_path", "")
          )
        )
        if Ops.get_map(add_on, "patterns", {}) != {}
          # summary item, %1 is comma-separated list
          ret2 = Ops.add(
            ret2,
            Builtins.sformat(
              _("Patterns: %1"),
              Builtins.mergestring(
                Builtins.maplist(Ops.get_map(add_on, "patterns", {})) do |pat, p|
                  pat
                end,
                ", "
              )
            )
          )
        end
        ret2
      end

      # help text
      help_text = _(
        "<p>Start creating a new add-on product configuration with <b>Add</b>.</p>"
      ) +
        # help text
        _(
          "<p>Use <b>Edit</b> to modify the selected add-on product configuration.</p>"
        ) +
        # help text
        _("<p>Delete the selected configuration using <b>Delete</b>.</p>") +
        # help text
        _(
          "<p>Build the new add-on product based on the selected configuration with <b>Build</b>.</p>"
        )

      contents = VBox(
        VWeight(
          3,
          Table(
            Id(:table),
            Opt(:notify, :immediate),
            # table header item
            Header(
              _("Product Name"),
              # table header item
              _("Version")
            ),
            summary_items
          )
        ),
        VWeight(1, RichText(Id(:descr), "")),
        HBox(
          PushButton(Id(:new), Opt(:key_F3), Label.AddButton),
          PushButton(Id(:edit), Opt(:key_F4), Label.EditButton),
          PushButton(Id(:delete), Opt(:key_F5), Label.DeleteButton),
          HStretch(),
          # push button label
          PushButton(Id(:build), Opt(:key_F6), _("&Build"))
        )
      )

      contents = UIHelper.SpacingAround(contents, 1.5, 1.5, 1.0, 1.0)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help_text,
        Label.AbortButton,
        Label.FinishButton
      )
      Wizard.HideAbortButton

      if AddOnCreator.selected_product != -1
        UI.ChangeWidget(Id(:table), :CurrentItem, AddOnCreator.selected_product)
      end
      current = Convert.to_integer(UI.QueryWidget(Id(:table), :CurrentItem))
      current_product = {}
      if Ops.greater_than(Builtins.size(summary_items), 0)
        current_product = Ops.get(add_on_products, current, {})
        UI.ChangeWidget(
          Id(:descr),
          :Value,
          get_description.call(current_product)
        )
        UI.SetFocus(Id(:table))
      else
        Builtins.foreach([:edit, :delete, :build]) do |t|
          UI.ChangeWidget(Id(t), :Enabled, false)
        end
        UI.SetFocus(Id(:new))
      end

      ret = nil
      deleted = false
      while true
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")

        current = Convert.to_integer(UI.QueryWidget(Id(:table), :CurrentItem))

        if ret == :abort || ret == :cancel || ret == :back
          if ReallyAbort()
            ret = :abort
            break
          end
          next
        end
        break if ret == :new || ret == :next
        if ret == :delete
          # yes/no popup
          if Popup.YesNo(
              Builtins.sformat(
                _("Really delete configuration \"%1\"?"),
                Ops.get_string(current_product, ["content_map", "NAME"], "")
              )
            )
            add_on_products = Builtins.remove(add_on_products, current)
            summary_items = get_summary_items.call
            current_product = {}
            deleted = true
            UI.ChangeWidget(Id(:table), :Items, get_summary_items.call)
            Builtins.foreach([:edit, :delete, :build]) do |t|
              UI.ChangeWidget(Id(t), :Enabled, summary_items != [])
            end
            if summary_items != []
              ret = :table
              event = {}
            else
              UI.ChangeWidget(Id(:descr), :Value, "")
            end
          end
        end
        if ret == :table
          current_product = Ops.get(add_on_products, current, {})
          UI.ChangeWidget(
            Id(:descr),
            :Value,
            get_description.call(current_product)
          )
          ret = :edit if Ops.get_string(event, "EventReason", "") == "Activated"
        end
        if ret == :edit || ret == :build
          AddOnCreator.SelectProduct(current_product)
          AddOnCreator.PrepareBuild if ret == :build
          break
        end
      end
      AddOnCreator.selected_product = ret == :new ? -1 : current

      # save the map without possible deleted products
      if ret != :abort && deleted
        AddOnCreator.add_on_products = deep_copy(add_on_products)
      end
      Wizard.RestoreAbortButton
      Convert.to_symbol(ret)
    end

    # The first dialog in the sequence for creating new Add-On product
    # (select either creating new product or cloning existing one)
    def NewProductDialog
      # dialog caption
      caption = _("Add-On Product Creator")
      generate_descriptions = AddOnCreator.generate_descriptions

      contents = HVCenter(
        HBox(
          HSpacing(),
          VBox(
            VSpacing(0.8),
            RadioButtonGroup(
              Id(:rd),
              HVSquash(
                VBox(
                  Left(
                    RadioButton(
                      Id(:new),
                      Opt(:notify),
                      # radio button label
                      _("Create an Add-On &from the Beginning"),
                      !AddOnCreator.clone
                    )
                  ),
                  Left(
                    RadioButton(
                      Id(:copy),
                      Opt(:notify),
                      # radio button label
                      _("Create an Add-On Based on an &Existing Add-On"),
                      AddOnCreator.clone
                    )
                  ),
                  HBox(
                    HSpacing(2.5),
                    InputField(
                      Id(:path),
                      Opt(:hstretch),
                      # text entry label
                      _("&Path to Directory of the Existing Add-On Product"),
                      AddOnCreator.import_path
                    ),
                    VBox(Label(""), PushButton(Id(:browse), Label.BrowseButton))
                  ),
                  HBox(
                    HSpacing(2.5),
                    Left(
                      CheckBox(
                        Id(:descr_ch),
                        # checkbox label
                        _("&Generate Package Descriptions"),
                        generate_descriptions
                      ) # TODO move to next dialog?
                    )
                  )
                )
              )
            ),
            VSpacing(0.9)
          )
        )
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "start", ""),
        Label.BackButton,
        Label.NextButton
      )

      Builtins.foreach([:path, :descr_ch, :browse]) do |w|
        UI.ChangeWidget(Id(w), :Enabled, AddOnCreator.clone)
      end

      UI.SetFocus(Id(:next))

      ret = nil
      while true
        ret = UI.UserInput
        dir = Convert.to_string(UI.QueryWidget(Id(:path), :Value))
        clone = Convert.to_boolean(UI.QueryWidget(Id(:copy), :Value))
        if ret == :browse
          dir = UI.AskForExistingDirectory(dir, "")
          if dir != nil
            if Ops.add(Builtins.findlastof(dir, "/"), 1) == Builtins.size(dir)
              dir = Builtins.substring(
                dir,
                0,
                Ops.subtract(Builtins.size(dir), 1)
              )
            end
            UI.ChangeWidget(Id(:path), :Value, dir)
          end
        elsif ret == :new || ret == :copy
          Builtins.foreach([:path, :descr_ch, :browse]) do |w|
            UI.ChangeWidget(Id(w), :Enabled, ret == :copy)
          end
        elsif ret == :next
          AddOnCreator.generate_descriptions = !clone ||
            Convert.to_boolean(UI.QueryWidget(Id(:descr_ch), :Value))
          if clone && dir != ""
            AddOnCreator.import_path = dir
            AddOnCreator.clone = true
            ret = :copy
          end
          break
        elsif ret == :abort || ret == :cancel || ret == :back
          if ReallyAbort()
            break
          else
            next
          end
        end
      end
      if ret != :copy
        # reset possible previous settings
        AddOnCreator.ResetCurrentProduct
      end
      deep_copy(ret)
    end

    # @return dialog result
    def SourcesDialog
      current_product = deep_copy(AddOnCreator.current_product)

      # try to read existing product dependency and transform it to one string
      # easily understanable
      requres_l = Ops.get_list(
        AddOnCreator.product_info,
        ["requires", "value"],
        []
      )
      requires_m = Ops.get_map(requres_l, 0, {})
      # this is just internal string used to decide between predefined options
      requires = ""
      if Ops.get_string(requires_m, "name", "") != ""
        requires = Builtins.sformat(
          "%1-%2",
          Ops.get_string(requires_m, "name", ""),
          Ops.get_string(requires_m, "version", "")
        )
      end

      requires_orig = requires

      old_dir = Ops.get_string(current_product, "rpm_path", "")
      Ops.set(current_product, "rpm_path", "") if old_dir == nil

      content_map = deep_copy(AddOnCreator.content_map)
      product = Ops.get_string(content_map, "LABEL", "")
      old_product = product == "" ? nil : product

      version = Ops.get_string(content_map, "VERSION", "")
      old_version = version

      # dialog caption
      caption = _("Add-On Product Creator")

      contents = HBox(
        HSpacing(),
        VBox(
          HBox(
            InputField(
              Id(:product),
              Opt(:hstretch),
              # textentry label
              _("&Add-On Product Label"),
              product
            ),
            # textentry label
            InputField(Id(:version), Opt(:hstretch), _("&Version"), version)
          ),
          VSpacing(0.7),
          Frame(
            _("Required Product"),
            HBox(
              HSpacing(0.5),
              VBox(
                VSpacing(0.4),
                RadioButtonGroup(
                  Id(:rd),
                  Left(
                    HVSquash(
                      VBox(
                        Left(
                          RadioButton(
                            Id("SUSE_SLES-11"),
                            Opt(:notify),
                            # radio button label
                            _("SUSE &Linux Enterprise Server 11"),
                            requires == "SUSE_SLES-11"
                          )
                        ),
                        Left(
                          RadioButton(
                            Id("SUSE_SLED-11"),
                            Opt(:notify),
                            # radio button label
                            _("SUSE L&inux Enterprise Desktop 11"),
                            requires == "SUSE_SLED-11"
                          )
                        ),
                        Left(
                          RadioButton(
                            Id("SUSE_SLE-11"),
                            Opt(:notify),
                            # radio button label
                            _("S&USE Linux Enterprise 11"),
                            requires == "SUSE_SLE-11"
                          )
                        ),
                        Left(
                          RadioButton(
                            Id("SUSE_SLE-11.1"),
                            Opt(:notify),
                            # radio button label
                            _("SUSE Linux Enterprise 11 SP3"),
                            requires == "SUSE_SLE-11.3"
                          )
                        ),
                        Left(
                          RadioButton(
                            Id("openSUSE-12.3"),
                            Opt(:notify),
                            # radio button label
                            _("openSUSE 12.&3"),
                            requires == "openSUSE-12.3"
                          )
                        ),
                        Left(
                          RadioButton(
                            Id("openSUSE-13.1"),
                            Opt(:notify),
                            # radio button label
                            _("openSUSE 13.1"),
                            requires == "openSUSE-13.1"
                          )
                        ),
                        HBox(
                          Left(
                            RadioButton(
                              Id(:other),
                              Opt(:notify),
                              # radio button label
                              _("&Other")
                            )
                          )
                        )
                      )
                    )
                  )
                ),
                VSpacing(0.4)
              )
            )
          ),
          VSpacing(0.7),
          HBox(
            InputField(
              Id(:rpm_path),
              Opt(:hstretch),
              # text entry label
              _("&Path to Directory with Add-On Packages"),
              Ops.get_string(current_product, "rpm_path", "")
            ),
            VBox(Label(""), PushButton(Id(:browse_rpm), Label.BrowseButton))
          ),
          HBox(
            InputField(
              Id(:required_rpm_path),
              Opt(:hstretch),
              # text entry label
              _("Path to Directory with Re&quired Product Packages"),
              Ops.get_string(current_product, "required_rpm_path", "")
            ),
            VBox(Label(""), PushButton(Id(:browse_req_rpm), Label.BrowseButton))
          ),
          VSpacing(0.7)
        ),
        HSpacing()
      )


      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "sources", ""),
        Label.BackButton,
        Label.NextButton
      )
      UI.SetFocus(Id(:product))

      if UI.QueryWidget(Id(:rd), :Value) == nil
        UI.ChangeWidget(Id(:rd), :Value, :other)
        requires = "" # empty string means other than predefined values
      end

      ret = nil

      while true
        ret = UI.UserInput
        dir = Convert.to_string(UI.QueryWidget(Id(:rpm_path), :Value))
        req_dir = Convert.to_string(
          UI.QueryWidget(Id(:required_rpm_path), :Value)
        )
        product = Convert.to_string(UI.QueryWidget(Id(:product), :Value))
        version = Convert.to_string(UI.QueryWidget(Id(:version), :Value))

        if ret == :browse_rpm
          dir = UI.AskForExistingDirectory(dir, "")
          if dir != nil
            if Ops.add(Builtins.findlastof(dir, "/"), 1) == Builtins.size(dir)
              dir = Builtins.substring(
                dir,
                0,
                Ops.subtract(Builtins.size(dir), 1)
              )
            end
            UI.ChangeWidget(Id(:rpm_path), :Value, dir)
          end
        end
        if ret == :browse_req_rpm
          req_dir = UI.AskForExistingDirectory(req_dir, "")
          if req_dir != nil
            if Ops.add(Builtins.findlastof(req_dir, "/"), 1) ==
                Builtins.size(req_dir)
              req_dir = Builtins.substring(
                req_dir,
                0,
                Ops.subtract(Builtins.size(req_dir), 1)
              )
            end
            UI.ChangeWidget(Id(:required_rpm_path), :Value, req_dir)
          end
        elsif ret == :other
          requires = ""
        elsif Ops.is_string?(ret)
          requires = Convert.to_string(ret)
        elsif ret == :other
          requires = ""
          UI.ChangeWidget(Id(:other_val), :Enabled, true)
        elsif ret == :next
          if dir != "" && !FileUtils.Exists(dir)
            # error popup
            Popup.Error(
              Builtins.sformat(_("Directory %1 is not accessible."), dir)
            )
            UI.SetFocus(Id(:rpm_path))
            next
          end
          if req_dir != "" && !FileUtils.Exists(req_dir)
            # error popup
            Popup.Error(
              Builtins.sformat(_("Directory %1 is not accessible."), req_dir)
            )
            UI.SetFocus(Id(:required_rpm_path))
            next
          end
          if dir != "" &&
              Builtins.substring(dir, Ops.subtract(Builtins.size(dir), 1), 1) != "/"
            dir = Ops.add(dir, "/")
          end
          Ops.set(AddOnCreator.current_product, "rpm_path", dir)
          if req_dir != "" &&
              Builtins.substring(
                req_dir,
                Ops.subtract(Builtins.size(req_dir), 1),
                1
              ) != "/"
            req_dir = Ops.add(req_dir, "/")
          end
          Ops.set(AddOnCreator.current_product, "required_rpm_path", req_dir)
          if requires != "" && requires != requires_orig
            req_l = Builtins.splitstring(requires, "-")
            Ops.set(
              AddOnCreator.product_info,
              ["requires", "value"],
              [
                # with predefined values, use only one required product
                {
                  "name"    => Ops.get(req_l, 0, ""),
                  "version" => Ops.get(req_l, 1, ""),
                  "flag"    => "EQ"
                }
              ]
            )
          end

          Ops.set(AddOnCreator.content_map, "LABEL", product)
          # proposal for NAME: replace spaces with underscores
          Ops.set(
            AddOnCreator.content_map,
            "NAME",
            Builtins.mergestring(Builtins.splitstring(product, " "), "_")
          )
          Ops.set(AddOnCreator.content_map, "VERSION", version)
          # FIXME propose DISTRIBUTION as NAME - VERSION?

          # if rpm_path is different, reset packages_descr
          # (otherwise current values settings are merged into generated)
          if dir != old_dir
            Ops.set(AddOnCreator.current_product, "packages_descr", {})
          end
          break
        elsif ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :back
          break
        end
      end
      deep_copy(ret)
    end

    # Validation for pattern values
    def ValidatePatternValue(key, val)
      val = deep_copy(val)
      sval = Builtins.sformat("%1", val)
      ""
    end


    # Validation for values in content file
    def ValidateContentValue(key, val)
      val = deep_copy(val)
      sval = Builtins.sformat("%1", val)
      if key == "NAME"
        if Builtins.deletechars(sval, Ops.add(String.CAlnum, ".~_-")) != ""
          # error popup (input validation failed)
          return _(
            "The value of NAME may contain only\nletters, numbers, and the characters \".~_-\"."
          )
        end
      end
      ""
    end

    def AddContentValue(conflicts)
      conflicts = deep_copy(conflicts)
      ret = {}
      allowed_langs = Builtins.filter(AddOnCreator.GetLangCodes(true)) do |l|
        !Builtins.contains(conflicts, Ops.add("LABEL.", l))
      end
      help = Builtins.sformat(
        "<p><b>%1</b></p>%2<br>",
        Ops.get_string(
          AddOnCreator.content_specials,
          ["LABEL", "helplabel"],
          ""
        ),
        Ops.get_string(AddOnCreator.content_specials, ["LABEL", "help"], "")
      )

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(0.5),
            Label(_("LABEL")),
            # combo label
            Left(ComboBox(Id(:lang), _("La&nguage Code"), allowed_langs)),
            # textentry label
            InputField(Id(:val), Opt(:hstretch), _("&Value"), ""),
            HBox(
              PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
              PushButton(Id(:help), Opt(:key_F2), Label.HelpButton)
            )
          ),
          HSpacing(1)
        )
      )
      UI.SetFocus(Id(:val))
      while true
        result = UI.UserInput
        if result == :cancel
          ret = {}
          break
        end
        if result == :help
          # Heading for help popup window
          Popup.LongText(_("Help"), RichText(help), 50, 14)
        end
        if result == :ok
          ret = Builtins.union(
            Ops.get_map(AddOnCreator.content_specials, "LABEL", {}),
            {
              "key"   => Builtins.sformat(
                "LABEL.%1",
                UI.QueryWidget(Id(:lang), :Value)
              ),
              "value" => UI.QueryWidget(Id(:val), :Value)
            }
          )
          break
        end
      end
      UI.CloseDialog
      deep_copy(ret)
    end


    # First dialog
    # @return dialog result
    def ContentFileDialog
      # dialog caption - 'content' is file name
      caption = _("Product Definition")

      current_product = deep_copy(AddOnCreator.current_product)
      content = deep_copy(AddOnCreator.content)
      product_xml = {} # used only when imported
      product_info = deep_copy(AddOnCreator.product_info)
      generate_release_package = Ops.get_boolean(
        current_product,
        "generate_release_package",
        false
      )
      linguas_entry = -1

      # generate items for content file table
      get_content_items = lambda do |mandatory_only|
        i = -1
        ret2 = []
        Builtins.foreach(content) do |entry|
          i = Ops.add(i, 1)
          linguas_entry = i if Ops.get_string(entry, "key", "") == "LINGUAS"
          next if mandatory_only && !Ops.get_boolean(entry, "mandatory", false)
          next if Ops.get_string(entry, "label", "") == ""
          ret2 = Builtins.add(
            ret2,
            Item(
              Id(i),
              Ops.get_string(entry, "key", ""),
              Ops.get_string(entry, "value", ""),
              Ops.get_string(entry, "label", "")
            )
          )
        end
        deep_copy(ret2)
      end

      # generate items for prod file table
      get_prod_items = lambda do
        ret2 = []
        Builtins.foreach(product_info) do |key, entry|
          if Ops.get_string(entry, "type", "") == "dependency"
            value = ""
            Builtins.foreach(Ops.get_list(entry, "value", [])) do |dep|
              prod = Builtins.sformat(
                "%1-%2-%3",
                Ops.get_string(dep, "name", ""),
                Ops.get_string(dep, "version", "1"),
                Ops.get_string(dep, "flag", "EQ")
              )
              if Ops.get_string(dep, "release", "") != ""
                prod = Ops.add(
                  Ops.add(prod, "-"),
                  Ops.get_string(dep, "release", "")
                )
              end
              if Ops.get_string(dep, "flavor", "") != ""
                prod = Ops.add(
                  Ops.add(prod, "-"),
                  Ops.get_string(dep, "flavor", "")
                )
              end
              if Ops.get_string(dep, "patchlevel", "") != ""
                prod = Ops.add(
                  Ops.add(prod, "-"),
                  Ops.get_string(dep, "patchlevel", "")
                )
              end
              value = Ops.add(value, ",") if value != ""
              value = Ops.add(value, prod)
            end
            ret2 = Builtins.add(
              ret2,
              Item(Id(key), key, value, Ops.get_string(entry, "label", ""))
            )
          else
            ret2 = Builtins.add(
              ret2,
              Item(
                Id(key),
                key,
                Ops.get_string(entry, "value", ""),
                Ops.get_string(entry, "label", "")
              )
            )
          end
        end
        deep_copy(ret2)
      end

      contents = HBox(
        HSpacing(),
        VBox(
          # label
          Left(Label(_("Content File"))),
          Table(
            Id(:content_table),
            Opt(:notify),
            Header(
              # table header
              _("Key"),
              # table header
              _("Value"),
              # table header
              _("Description")
            ),
            get_content_items.call(true)
          ),
          HBox(
            PushButton(Id(:add), Label.AddButton),
            PushButton(Id(:edit), Label.EditButton),
            # push button label
            PushButton(Id(:import), _("Im&port")),
            HStretch(),
            CheckBox(
              Id(:filter_ch),
              Opt(:notify),
              # checkbox label
              _("Show &Only Required Keywords"),
              true
            )
          ),
          VSpacing(0.4),
          Left(
            CheckBox(
              Id(:release_package),
              Opt(:notify),
              # check box label
              _("Generate Release Package"),
              generate_release_package
            )
          ),
          # label
          Left(Label(_("Product File"))),
          Table(
            Id(:prod_table),
            Opt(:notify),
            Header(
              # table header
              _("Key"),
              # table header
              _("Value"),
              # table header
              _("Description")
            ),
            get_prod_items.call
          ),
          HBox(
            PushButton(Id(:edit_prod), Label.EditButton),
            # push button label
            PushButton(Id(:import_prod), _("I&mport")),
            HStretch()
          ),
          VSpacing(0.2)
        ),
        HSpacing()
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "content", ""),
        Label.BackButton,
        Label.NextButton
      )
      UI.SetFocus(Id(:content_table))

      Builtins.foreach([:prod_table, :edit_prod, :import_prod]) do |w|
        UI.ChangeWidget(Id(w), :Enabled, generate_release_package)
      end
      ret = nil
      mandatory = true
      while true
        ret = UI.UserInput

        if ret == :add
          new = AddContentValue(Builtins.maplist(content) do |e|
            Ops.get_string(e, "key", "")
          end)
          if new != {}
            if mandatory && !Ops.get_boolean(new, "mandatory", false)
              UI.ChangeWidget(Id(:filter_ch), :Value, false)
              ret = :filter_ch
            end
            # add new language to LINGUAS when new LABEL.lang was added
            if Builtins.substring(Ops.get_string(new, "key", ""), 0, 5) == "LABEL" &&
                linguas_entry != -1
              linguas = Ops.get_string(content, [linguas_entry, "value"], "")
              Ops.set(
                content,
                [linguas_entry, "value"],
                Builtins.sformat(
                  "%1%2%3",
                  linguas,
                  linguas == "" ? "" : " ",
                  Builtins.substring(Ops.get_string(new, "key", ""), 6)
                )
              )
            end
            content = Builtins.add(content, new)
            UI.ChangeWidget(
              Id(:content_table),
              :Items,
              get_content_items.call(mandatory)
            )
          end
        end
        if ret == :filter_ch
          filt = Convert.to_boolean(UI.QueryWidget(Id(:filter_ch), :Value))
          if filt != mandatory
            mandatory = filt
            UI.ChangeWidget(
              Id(:content_table),
              :Items,
              get_content_items.call(mandatory)
            )
          end
        elsif ret == :import
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "base_output_path", ""),
            "",
            # popup for file selection dialog
            _("Choose the Existing Content File")
          )
          if file != nil
            content = AddOnCreator.ReadContentFile(file)
            UI.ChangeWidget(
              Id(:content_table),
              :Items,
              get_content_items.call(mandatory)
            )
          end
        elsif ret == :edit || ret == :content_table
          key_no = Convert.to_integer(
            UI.QueryWidget(Id(:content_table), :CurrentItem)
          )
          val = Convert.to_string(
            EditValue(Ops.get(content, key_no, {}), "content")
          )
          if val != nil
            Ops.set(content, [key_no, "value"], val)
            UI.ChangeWidget(Id(:content_table), term(:Item, key_no, 1), val)
          end
          UI.SetFocus(Id(:content_table))
        end
        if ret == :release_package
          generate_release_package = Convert.to_boolean(
            UI.QueryWidget(Id(ret), :Value)
          )
          Builtins.foreach([:prod_table, :edit_prod, :import_prod]) do |w|
            UI.ChangeWidget(Id(w), :Enabled, generate_release_package)
          end
        elsif ret == :edit_prod || ret == :prod_table
          key = Convert.to_string(UI.QueryWidget(Id(:prod_table), :CurrentItem))
          val = EditValue(Ops.get(product_info, key, {}), "prod")
          if val != nil
            Ops.set(product_info, [key, "value"], val)
            if Ops.get_string(product_info, [key, "type"], "") == "dependency"
              UI.ChangeWidget(Id(:prod_table), :Items, get_prod_items.call)
            else
              UI.ChangeWidget(Id(:prod_table), term(:Item, key, 1), val)
            end
          end
          UI.SetFocus(Id(:prod_table))
        elsif ret == :import_prod
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "base_output_path", ""),
            "",
            # popup for file selection dialog
            _("Choose the Existing Product File")
          )
          if file != nil
            product_xml = AddOnCreator.ReadProductXML(file)
            product_info = AddOnCreator.GetProductInfo(product_xml, false)
            UI.ChangeWidget(Id(:prod_table), :Items, get_prod_items.call)
          end
        elsif ret == :next
          missing = []
          Builtins.foreach(content) do |entry|
            if Ops.get_string(entry, "value", "") == "" &&
                Ops.get_boolean(entry, "mandatory", false)
              missing = Builtins.add(missing, Ops.get_string(entry, "key", ""))
            end
          end
          if missing != []
            # error popup
            Popup.Error(
              Builtins.sformat(
                _("Enter the values for these items:\n%1"),
                Builtins.mergestring(missing, "\n")
              )
            )
            next
          end
          # FIXME some data are both in prod file and content file
          # (vendor, version, release, id (=name) ... -> popup
          i = 0
          index = -1
          product = ""
          Builtins.foreach(content) do |entry|
            if Ops.get_string(entry, "key", "") == "LABEL" &&
                Ops.get_string(entry, "value", "") == ""
              index = i
            end
            if Ops.get_string(entry, "key", "") == "NAME"
              product = Ops.get_string(entry, "value", "")
            end
            i = Ops.add(i, 1)
          end
          Ops.set(content, [index, "value"], product) if index != -1
          AddOnCreator.content = deep_copy(content)
          AddOnCreator.UpdateContentMap(content)
          AddOnCreator.product_xml = deep_copy(product_xml) if product_xml != {}
          AddOnCreator.product_info = deep_copy(product_info)
          Ops.set(
            AddOnCreator.current_product,
            "generate_release_package",
            generate_release_package
          )
          break
        elsif ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :back
          break
        end
      end
      deep_copy(ret)
    end


    # helper
    def value2string(val)
      val = deep_copy(val)
      if Ops.is_string?(val)
        s = Convert.to_string(val)
        if Builtins.issubstring(s, "\n")
          s = Builtins.mergestring(Builtins.splitstring(s, "\n"), " ")
        end
        return s
      elsif Ops.is_boolean?(val)
        # table item
        return Convert.to_boolean(val) ?
          _("Yes") :
          # table item
          _("No")
      elsif Ops.is_list?(val)
        return Builtins.mergestring(
          Convert.convert(val, :from => "any", :to => "list <string>"),
          " "
        )
      end
      Builtins.sformat("%1", val)
    end

    # default function for maps
    def NoString(arg)
      arg = deep_copy(arg)
      ""
    end
    def EditValue(entry, table_type)
      entry = deep_copy(entry)
      ret = nil
      type = Ops.get_string(entry, "type", "string")
      # textentry label
      label = Builtins.sformat(
        _("Value of \"%1\""),
        table_type == "content" ?
          Ops.get_string(entry, "key", "") :
          Ops.get_string(entry, "label", "")
      )

      value = Ops.get(entry, "value")
      if value == nil
        value = "" if table_type == "content" || table_type == "prod"
        value = [] if type == "package-list" || type == "dependency"
      end
      lvalues = [] # list of maps for "dependency" type

      cont = InputField(
        Id(:main),
        Opt(:hstretch),
        label,
        Builtins.sformat("%1", value)
      )
      w_id = :main
      height = 5

      help = table_type == "content" ?
        Builtins.sformat(
          "<p><b>%1</b></p>%2",
          Ops.get_string(entry, "helplabel", Ops.get_string(entry, "key", "")),
          Ops.get_string(entry, "help", "")
        ) :
        Ops.get_string(entry, "help", "")

      all_items = []

      # generate items for MultiSelectionBox
      # if all is boolean, apply to each item (=> all checked or all unchecked)
      get_package_items = lambda do |all|
        ret2 = []
        Builtins.foreach(AddOnCreator.available_packages) do |a, pa|
          ret2 = Builtins.union(
            ret2,
            Builtins.maplist(
              Convert.convert(pa, :from => "list", :to => "list <string>")
            ) do |p|
              height = Ops.add(height, 1)
              Item(
                p,
                all == nil ?
                  Builtins.contains(
                    Convert.convert(
                      value,
                      :from => "any",
                      :to   => "list <string>"
                    ),
                    p
                  ) :
                  all
              )
            end
          )
        end
        deep_copy(ret2)
      end

      # helper function, generate widget id distinguished by numbers
      get_id = lambda { |key, number| Builtins.sformat("%1-%2", key, number) }

      # number of products reffered in the dependency tags
      products = 0

      dependency_attrs = [
        "name",
        "version",
        "flag",
        "release",
        "patchlevel",
        "flavor"
      ]

      # generate a term for one product present in dependency tags
      get_dependency_term = lambda do |number, value_map|
        value_map = deep_copy(value_map)
        flag = Ops.get_string(value_map, "flag", "")
        Frame(
          "",
          VBox(
            HBox(
              HWeight(
                1,
                # input field label
                InputField(
                  Id(get_id.call("name", number)),
                  # input field label
                  _("Name"),
                  Ops.get_string(value_map, "name", "")
                )
              ),
              HSpacing(0.8),
              HWeight(
                1,
                InputField(
                  Id(get_id.call("version", number)),
                  # input field label
                  _("Version"),
                  Ops.get_string(value_map, "version", "")
                )
              ),
              HSpacing(0.8),
              # combo box label
              HWeight(
                1,
                ComboBox(
                  Id(get_id.call("flag", number)),
                  _("Flag"),
                  [
                    # combo box item
                    Item(Id("EQ"), _("Equal"), flag == "EQ" || flag == ""),
                    # combo box item
                    Item(Id("GE"), _("Greater than"), flag == "GE"),
                    # combo box item
                    Item(Id("LT"), _("Lower than"), flag == "LT")
                  ]
                )
              )
            ),
            HBox(
              HWeight(
                1,
                InputField(
                  Id(get_id.call("release", number)),
                  # input field label
                  _("Release"),
                  Ops.get_string(value_map, "release", "")
                )
              ),
              HSpacing(0.8),
              HWeight(
                1,
                InputField(
                  Id(get_id.call("flavor", number)),
                  # input field label
                  _("Flavor"),
                  Ops.get_string(value_map, "flavor", "")
                )
              ),
              HSpacing(0.8),
              HWeight(
                1,
                InputField(
                  Id(get_id.call("patchlevel", number)),
                  # input field label
                  _("Patch level"),
                  Ops.get_string(value_map, "patchlevel", "")
                )
              )
            )
          )
        )
      end

      if type == "dependency"
        lvalues = Convert.convert(value, :from => "any", :to => "list <map>")
        lvalues = [{}] if lvalues == []
        dep_term = VBox()
        Builtins.foreach(lvalues) do |valmap|
          products = Ops.add(products, 1)
          dep_term = Builtins.add(
            dep_term,
            get_dependency_term.call(products, valmap)
          )
        end
        cont = VBox(
          Label(Ops.get_string(entry, "label", label)),
          ReplacePoint(Id(:rp_dep), dep_term),
          Right(PushButton(Id(:add_dep), Label.AddButton))
        )
        w_id = "name-1"
      elsif type == "boolean"
        cont = VBox(
          Label(label),
          RadioButtonGroup(
            Id(:rd),
            Left(
              HVSquash(
                VBox(
                  Left(
                    RadioButton(
                      Id(:yes),
                      Opt(:notify),
                      Label.YesButton,
                      Convert.to_boolean(value)
                    )
                  ),
                  Left(
                    RadioButton(
                      Id(:no),
                      Opt(:notify),
                      Label.NoButton,
                      !Convert.to_boolean(value)
                    )
                  )
                )
              )
            )
          )
        )
        w_id = :yes
      elsif type == "multiline" || type == "pattern-list"
        sval = Convert.to_string(value)
        rt = Empty()
        height = Ops.add(Builtins.size(Builtins.splitstring(sval, "\n")), 3)
        if table_type == "packages" &&
            Builtins.issubstring(sval, "<!-- DT:Rich -->")
          rt = RichText(Id(:rt), Opt(:shrinkable), sval)
          height = Ops.multiply(height, 2)
        end
        cont = VBox(HSpacing(54), rt, MultiLineEdit(Id(:main), label, sval))
        height = 9 if Ops.less_than(height, 9)
      elsif type == "combo"
        cont = VBox(
          ComboBox(
            Id(:main),
            label,
            Builtins.maplist(Ops.get_list(entry, "allowed_values", [])) do |v|
              Item(v, v == value)
            end
          )
        )
      elsif type == "integer"
        ival = Builtins.tointeger(value)
        ival = Ops.get_integer(entry, ["range", 0], 0) if ival == nil
        cont = VBox(
          IntField(
            Id(:main),
            label,
            Ops.get_integer(entry, ["range", 0], 0),
            Ops.get_integer(entry, ["range", 1], 1000),
            ival
          )
        )
      elsif type == "package-list"
        all_items = get_package_items.call(nil)
        cont = VBox(
          HSpacing(50),
          # MultiSelectionBox label
          MultiSelectionBox(Id(:main), _("&Packages"), all_items),
          Left(
            # check box label
            CheckBox(Id(:all), Opt(:notify), _("Select or Deselect &All"))
          )
        )
      end
      height = 25 if Ops.greater_than(height, 25)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          VSpacing(height),
          HSpacing(1),
          VBox(
            cont,
            HBox(
              PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
              PushButton(Id(:help), Opt(:key_F2), Label.HelpButton)
            )
          ),
          HSpacing(1)
        )
      )
      UI.SetFocus(Id(w_id))
      UI.ChangeWidget(Id(:help), :Enabled, help != "")
      all_checked = false
      if type == "package-list"
        all_checked = value != [] &&
          Builtins.size(Convert.to_list(value)) == Builtins.size(all_items)
        UI.ChangeWidget(Id(:all), :Value, all_checked)
      end
      while true
        result = UI.UserInput
        if result == :cancel
          ret = nil
          break
        end
        if result == :help
          # Heading for help popup window
          Popup.LongText(_("Help"), RichText(help), 50, 10)
        end
        if result == :all
          ch = Convert.to_boolean(UI.QueryWidget(Id(:all), :Value))
          if ch != all_checked
            UI.ChangeWidget(Id(w_id), :Items, get_package_items.call(ch))
            all_checked = ch
          end
        end
        if result == :add_dep
          dep_term = VBox()
          i = 1
          y = 1
          begin
            valmap = {}
            Builtins.foreach(dependency_attrs) do |key|
              val = Convert.to_string(
                UI.QueryWidget(Id(get_id.call(key, i)), :Value)
              )
              Ops.set(valmap, key, val) if val != ""
            end
            if Ops.greater_than(Builtins.size(valmap), 1) # there's always at least the flag
              dep_term = Builtins.add(
                dep_term,
                get_dependency_term.call(y, valmap)
              )
              y = Ops.add(y, 1)
            end
            i = Ops.add(i, 1)
          end while Ops.less_or_equal(i, products) # counts the non-empty parts
          # if there were empty products, product number could be lower now
          products = y
          dep_term = Builtins.add(
            dep_term,
            get_dependency_term.call(products, {})
          )
          UI.ReplaceWidget(Id(:rp_dep), dep_term)
        end
        if result == :ok
          if type == "package-list"
            ret = UI.QueryWidget(Id(w_id), :SelectedItems)
          elsif type == "dependency"
            retlist = []
            i = 1
            begin
              retmap = {}
              Builtins.foreach(dependency_attrs) do |key|
                val = Convert.to_string(
                  UI.QueryWidget(Id(get_id.call(key, i)), :Value)
                )
                Ops.set(retmap, key, val) if val != ""
              end
              if Ops.greater_than(Builtins.size(retmap), 1) # there's always at least the flag
                retlist = Builtins.add(retlist, retmap)
              end
              i = Ops.add(i, 1)
            end while Ops.less_or_equal(i, products)
            ret = deep_copy(retlist)
          else
            ret = UI.QueryWidget(Id(w_id), :Value)
          end
          error = ""
          case table_type
            when "content"
              error = ValidateContentValue(
                Ops.get_string(entry, "key", ""),
                ret
              )
            when "pattern"
              error = ValidatePatternValue(
                Ops.get_string(entry, "key", ""),
                ret
              )
          end
          if table_type == "content"
            if error != ""
              Popup.Error(error)
              next
            end
          end
          break
        end
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    # edit the key and value in pattern description
    def AddDescriptionValue(existing)
      existing = deep_copy(existing)
      ret = {}
      # textentry label
      label = _("&Value")
      focus = ""
      help = ""
      height = 10
      rbs = VBox()
      Builtins.foreach(@description_descr) do |key, val|
        if !Builtins.contains(existing, key)
          rbs = Builtins.add(
            rbs,
            Left(
              RadioButton(
                Id(key),
                Opt(:notify),
                Ops.get_string(val, "label", ""),
                focus == ""
              )
            )
          )
          help = Ops.add(
            help,
            Builtins.sformat(
              "<b>%1</b><p>%2</p>",
              Ops.get_string(val, "label", ""),
              Ops.get_string(val, "help", "")
            )
          )
          height = Ops.add(height, 1)
          focus = key if focus == ""
        end
      end
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          VSpacing(height),
          HSpacing(1),
          VBox(
            HSpacing(50),
            VSpacing(0.5),
            RadioButtonGroup(Id(:rd), Left(HVSquash(rbs))),
            MultiLineEdit(Id(:val), label, ""),
            HBox(
              PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
              # push button label
              PushButton(Id(:import), Opt(:key_F3), _("I&mport")),
              PushButton(Id(:help), Opt(:key_F2), Label.HelpButton)
            )
          ),
          HSpacing(1)
        )
      )
      UI.SetFocus(Id(focus))
      while true
        result = UI.UserInput
        if result == :cancel
          ret = {}
          break
        end
        key = Convert.to_string(UI.QueryWidget(Id(:rd), :Value))
        Wizard.ShowHelp(help) if result == :help
        if result == :import
          file = UI.AskForExistingFile(
            Ops.get_string(AddOnCreator.current_product, "base_output_path", ""),
            "",
            # popup for file selection dialog
            _("Choose the file with the text to be imported.")
          )
          if file != nil
            text = Convert.to_string(SCR.Read(path(".target.string"), file))
            UI.ChangeWidget(Id(:val), :Value, text) if text != nil
          end
        end
        if result == :ok
          ret = { "key" => key, "value" => UI.QueryWidget(Id(:val), :Value) }
          break
        end
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    # Editor od packages.lang files
    # @return dialog result
    def PackagesDialog
      current_product = deep_copy(AddOnCreator.current_product)

      # dialog caption
      caption = _("Package Descriptions")
      descr = Ops.get_map(current_product, "packages_descr", {})

      descr_files = Builtins.maplist(descr) { |l, d| l }

      # generate the items for table with package names
      get_package_names = lambda do |lang|
        package_names = []
        # build the items with packages
        Builtins.foreach(
          Convert.convert(
            Ops.get(descr, lang, {}),
            :from => "map",
            :to   => "map <string, map>"
          )
        ) do |package, d|
          next if package == "___global___"
          package_names = Builtins.add(
            package_names,
            Item(Id(package), Ops.get_string(d, "Pkg", package))
          )
        end
        deep_copy(package_names)
      end

      # generate items for table with description of selected package
      get_descr_items = lambda do |description|
        description = deep_copy(description)
        ret2 = []
        Builtins.foreach(description) do |key, val|
          if key != "Pkg"
            ret2 = Builtins.add(
              ret2,
              Item(
                Id(key),
                Ops.get_string(@description_descr, [key, "label"], key),
                value2string(val)
              )
            )
          end
        end
        deep_copy(ret2)
      end

      allowed_langs = Builtins.sort(
        Builtins.splitstring(
          Ops.get(AddOnCreator.content_map, "LINGUAS", ""),
          " \t"
        )
      )
      allowed_langs = ["en", "de"] if allowed_langs == []
      def_lang = "en"
      # Addon for 10.1 has more languages, although only en, de in LINGUAS...

      # lang is language that should be active in the combo box
      replace_language_widgets = lambda do |lang|
        UI.ReplaceWidget(
          Id(:rpcombo),
          ComboBox(
            Id(:descr_files),
            Opt(:notify, :hstretch),
            # combobox label
            _("Description File &Language Code"),
            Builtins.maplist(descr) { |l, d| Item(Id(l), l, l == lang) }
          )
        )
        UI.ReplaceWidget(
          Id(:mbutton),
          # button label
          MenuButton(
            Id(:add_lang),
            _("Add Lan&guage"),
            Builtins.maplist(Builtins.filter(allowed_langs) do |la|
              !Builtins.haskey(descr, la)
            end) { |l| Item(Id(l), l) }
          )
        )
        UI.ChangeWidget(
          Id(:add_lang),
          :Enabled,
          Builtins.size(descr) != 0 &&
            Ops.less_than(Builtins.size(descr), Builtins.size(allowed_langs))
        )

        nil
      end

      contents = HBox(
        HSpacing(),
        VBox(
          VSpacing(0.5),
          HBox(
            ReplacePoint(
              Id(:rpcombo),
              ComboBox(
                Id(:descr_files),
                Opt(:notify, :hstretch),
                # combobox label
                _("Description File &Language Code"),
                descr_files
              )
            ),
            VBox(
              Label(""),
              HBox(
                ReplacePoint(
                  Id(:mbutton),
                  # button label
                  MenuButton(Id(:add_lang), _("Add Lan&guage"), [])
                ),
                # button label
                PushButton(Id(:import_lang), _("I&mport")),
                PushButton(Id(:delete_lang), Label.DeleteButton)
              )
            )
          ),
          Table(
            Id(:packages),
            Opt(:notify, :immediate),
            Header(
              # table header
              _("Package")
            ),
            []
          ),
          VSpacing(0.4),
          Table(
            Id(:description),
            Opt(:notify),
            Header(
              # table header 1/2
              _("Attribute"),
              # table header 2/2
              _("Value")
            ),
            []
          ),
          HBox(
            PushButton(Id(:add), Opt(:key_F6), Label.AddButton),
            PushButton(Id(:edit), Opt(:key_F7), Label.EditButton),
            PushButton(Id(:delete), Opt(:key_F8), Label.DeleteButton),
            HStretch()
          ),
          VSpacing(0.4),
          HBox(
            InputField(
              Id(:extra_prov),
              Opt(:hstretch),
              # textentry label
              _("Location of the File with Additional &Dependencies"),
              Ops.get_string(current_product, "extra_prov_file", "")
            ),
            VBox(Label(""), PushButton(Id(:browse), Label.BrowseButton))
          )
        ),
        HSpacing()
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "packages", ""),
        Label.BackButton,
        Label.NextButton
      )

      UI.SetFocus(Id(:packages))
      current_lang = Convert.to_string(UI.QueryWidget(Id(:descr_files), :Value))

      UI.ChangeWidget(
        Id(:packages),
        :Items,
        get_package_names.call(current_lang)
      )

      current_package = Convert.to_string(
        UI.QueryWidget(Id(:packages), :CurrentItem)
      )

      # build the items with description of current package
      UI.ChangeWidget(
        Id(:description),
        :Items,
        get_descr_items.call(
          Ops.get_map(descr, [current_lang, current_package], {})
        )
      )

      # do not allow to add new description key when all are present
      full_descr = Builtins.size(@description_descr)
      UI.ChangeWidget(
        Id(:add),
        :Enabled,
        Ops.get(descr, current_lang, {}) != {} &&
          Ops.less_than(
            Builtins.size(
              Ops.get_map(descr, [current_lang, current_package], {})
            ),
            full_descr
          )
      )

      # do not delete default language file
      UI.ChangeWidget(
        Id(:delete_lang),
        :Enabled,
        current_lang != def_lang && Ops.get(descr, current_lang, {}) != {}
      )

      UI.ChangeWidget(
        Id(:import_lang),
        :Enabled,
        Ops.get(descr, current_lang, {}) != {}
      )
      UI.ChangeWidget(
        Id(:edit),
        :Enabled,
        Ops.get(descr, current_lang, {}) != {}
      )
      UI.ChangeWidget(
        Id(:delete),
        :Enabled,
        Ops.get(descr, current_lang, {}) != {}
      )

      replace_language_widgets.call(current_lang)

      ret = nil
      while true
        ret = UI.UserInput
        lang = Convert.to_string(UI.QueryWidget(Id(:descr_files), :Value))
        if Ops.is_string?(ret)
          lang = Convert.to_string(ret)
          # copy global values and "Pkg" from default langauge,
          # add keys with defaults
          Ops.set(
            descr,
            lang,
            Builtins.mapmap(
              Convert.convert(
                Ops.get(descr, def_lang, {}),
                :from => "map",
                :to   => "map <string, map>"
              )
            ) do |pa, d|
              next { pa => d } if pa == "___global___"
              des = { "Pkg" => Ops.get_string(d, "Pkg", "") }
              Builtins.foreach(@description_descr) do |key, de|
                if Builtins.haskey(de, "defval")
                  Ops.set(des, key, Ops.get_string(de, "defval", ""))
                end
              end
              { pa => des }
            end
          )
          replace_language_widgets.call(lang)
          ret = :descr_files
        end
        if ret == :import_lang
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "packages.*",
            # popup for file selection dialog
            _("Choose the New Package Description File")
          )
          if file != nil
            name = file
            if Builtins.issubstring(name, "/")
              name = Builtins.substring(
                name,
                Ops.add(Builtins.findlastof(name, "/"), 1)
              )
            end
            if Builtins.substring(name, 0, 9) != "packages."
              # error popup (correct name is 'packages.*')
              Popup.Error(
                _(
                  "The package description file is named incorrectly.\nChoose another one."
                )
              )
              next
            end
            f = Builtins.splitstring(name, ".")
            lang = Ops.get_string(f, Ops.subtract(Builtins.size(f), 1), "en")
            if lang == "gz"
              if Ops.greater_than(Builtins.size(f), 2)
                lang = Ops.get_string(
                  f,
                  Ops.subtract(Builtins.size(f), 2),
                  "en"
                )
              else
                next
              end
            end
            next if lang == "" || lang == "DU" || lang == "FL"
            description = AddOnCreator.ReadPackagesFile(file)
            next if description == nil #TODO error handling
            Ops.set(descr, lang, description)
            if !Builtins.contains(allowed_langs, lang)
              allowed_langs = Builtins.add(allowed_langs, lang)
            end
            replace_language_widgets.call(lang)
            ret = :descr_files
            current_lang = nil
          end
        end
        if ret == :delete_lang
          descr = Builtins.remove(descr, lang)
          replace_language_widgets.call(def_lang)
          lang = Convert.to_string(UI.QueryWidget(Id(:descr_files), :Value))
          current_lang = nil
          ret = :descr_files
        end
        if ret == :descr_files
          if lang != current_lang
            current_lang = lang
            UI.ChangeWidget(Id(:packages), :Items, get_package_names.call(lang))
            UI.ChangeWidget(Id(:delete_lang), :Enabled, lang != def_lang)
            ret = :packages
            current_package = nil
          end
        end
        sel = Convert.to_string(UI.QueryWidget(Id(:packages), :CurrentItem))
        if ret == :packages
          if sel != current_package
            current_package = sel
            UI.ChangeWidget(
              Id(:description),
              :Items,
              get_descr_items.call(Ops.get_map(descr, [lang, sel], {}))
            )
            UI.ChangeWidget(
              Id(:add),
              :Enabled,
              Ops.less_than(
                Builtins.size(Ops.get_map(descr, [lang, sel], {})),
                full_descr
              )
            )
          end
        elsif ret == :add
          new_val = AddDescriptionValue(
            Builtins.maplist(Ops.get_map(descr, [lang, sel], {})) do |key, v|
              key
            end
          )
          if new_val != {}
            Ops.set(
              descr,
              [lang, sel, Ops.get_string(new_val, "key", "")],
              Ops.get_string(new_val, "value", "")
            )
            UI.ChangeWidget(
              Id(:description),
              :Items,
              get_descr_items.call(Ops.get_map(descr, [lang, sel], {}))
            )
          end
          UI.SetFocus(Id(:description))
          UI.ChangeWidget(
            Id(:add),
            :Enabled,
            Ops.less_than(
              Builtins.size(Ops.get_map(descr, [lang, sel], {})),
              full_descr
            )
          )
        elsif ret == :edit || ret == :description
          key = Convert.to_string(
            UI.QueryWidget(Id(:description), :CurrentItem)
          )
          des = Ops.get(@description_descr, key, {})
          val = EditValue(
            Builtins.union(
              des,
              { "value" => Ops.get_string(descr, [lang, sel, key], "") }
            ),
            "packages"
          )
          if val != nil
            Ops.set(descr, [lang, sel, key], val)
            UI.ChangeWidget(
              Id(:description),
              term(:Item, key, 1),
              value2string(val)
            )
          end
          UI.SetFocus(Id(:description))
        elsif ret == :delete
          key = Convert.to_string(
            UI.QueryWidget(Id(:description), :CurrentItem)
          )
          if Ops.get(descr, [lang, sel, key]) != nil
            Ops.set(
              descr,
              [lang, sel],
              Builtins.remove(Ops.get_map(descr, [lang, sel], {}), key)
            )
            UI.ChangeWidget(
              Id(:description),
              :Items,
              get_descr_items.call(Ops.get_map(descr, [lang, sel], {}))
            )
          end
          UI.SetFocus(Id(:description))
        elsif ret == :browse
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "",
            # popup for file selection dialog
            _("Choose the Path to EXTRA_PROV File")
          )
          UI.ChangeWidget(Id(:extra_prov), :Value, file) if file != nil
        elsif ret == :next
          Ops.set(AddOnCreator.current_product, "packages_descr", descr)
          extra = Convert.to_string(UI.QueryWidget(Id(:extra_prov), :Value))
          if extra != "" && !FileUtils.Exists(extra)
            # error popup
            Report.Error(
              Builtins.sformat(
                _("The file '%1' does not exist.\nChoose another one."),
                extra
              )
            )
            UI.SetFocus(Id(:extra_prov))
            next
          else
            cont = ""
            if extra != ""
              cont = Convert.to_string(SCR.Read(path(".target.string"), extra))
            end
            if cont != nil
              Ops.set(AddOnCreator.current_product, "extra_prov", cont)
              Ops.set(AddOnCreator.current_product, "extra_prov_file", extra)
            end
          end
          break
        elsif ret == :back
          break
        elsif ret == :abort || ret == :cancel
          break if ReallyAbort()
          next
        end
      end
      deep_copy(ret)
    end

    # Dialog for entering the data for new GPG keypair
    def GenerateKeyDialog
      ret = ""
      cont = HBox(
        HSpacing(1),
        VBox(
          VSpacing(0.5),
          # frame label
          Frame(
            _("Key Type"),
            HBox(
              HSpacing(0.5),
              VBox(
                RadioButtonGroup(
                  Id("Key-Type"),
                  Left(
                    HVSquash(
                      VBox(
                        Left(
                          RadioButton(
                            Id("DSA"),
                            Opt(:notify),
                            # radiobutton label (key type)
                            _("&DSA"),
                            true
                          )
                        ),
                        # radiobutton label (key type)
                        Left(RadioButton(Id("RSA"), Opt(:notify), _("&RSA")))
                      )
                    )
                  )
                )
              )
            )
          ),
          VSpacing(0.5),
          # textentry label
          IntField(Id("Key-Length"), _("Key &Size"), 1024, 4096, 2048),
          InputField(
            Id("Expire-Date"),
            Opt(:hstretch),
            # textentry label
            _("E&xpiration Date")
          ),
          # textentry label
          InputField(Id("Name-Real"), Opt(:hstretch), _("&Name")),
          # textentry label
          InputField(Id("Name-Comment"), Opt(:hstretch), _("Commen&t")),
          InputField(
            Id("Name-Email"),
            Opt(:hstretch),
            # textentry label
            _("E-&Mail Address")
          ),
          # password widget label
          Password(Id("Passphrase"), Opt(:hstretch), _("&Passphrase"))
        ),
        HSpacing(1)
      )
      Wizard.OpenAcceptDialog
      # dialog caption
      Wizard.SetContents(
        _("New GPG Key"),
        cont,
        Ops.get_string(@HELPS, "generate", ""),
        true,
        true
      )

      UI.ChangeWidget(Id("Expire-Date"), :ValidChars, "1234567890dwmy")

      UI.ChangeWidget(Id("Key-Length"), :Enabled, false)

      while true
        result = UI.UserInput

        type = Convert.to_string(UI.QueryWidget(Id("Key-Type"), :Value))
        UI.ChangeWidget(Id("Key-Length"), :Enabled, type == "RSA")

        if result == :cancel || result == :back
          ret = ""
          break
        end
        if result == :accept
          data = {}
          Builtins.foreach(
            [
              "Key-Type",
              "Expire-Date",
              "Key-Length",
              "Name-Real",
              "Name-Comment",
              "Name-Email",
              "Passphrase"
            ]
          ) do |key|
            Ops.set(
              data,
              key,
              Builtins.sformat("%1", UI.QueryWidget(Id(key), :Value))
            )
          end
          if Ops.get(data, "Name-Real", "") == "" &&
              Ops.get(data, "Name-Comment", "") == "" &&
              Ops.get(data, "Name-Email", "") == ""
            # error popup (see Name, Comment, Email Adress text entries
            Popup.Error(
              _(
                "Name, comment, and e-mail address values are empty.\nYou must enter at least one of them to provide user identification.\n"
              )
            )
            next
          end
          # feedback popup headline
          Popup.ShowFeedback(
            _("Generating Primary Key Pair"),
            # feedback message
            _(
              "If it takes too long, do some other work to give\nthe OS a chance to collect more entropy.\n"
            )
          )
          ret = AddOnCreator.GenerateGPGKey(data)
          Popup.ClearFeedback
          break
        end
      end
      Wizard.CloseDialog
      ret
    end

    # Dialog for product signing configuration
    def SigningDialog
      current_product = deep_copy(AddOnCreator.current_product)
      gpg_key = Ops.get_string(current_product, "gpg_key", "")
      # dialog caption
      caption = _("Signing the Add-On Product")
      gpg_keys = Builtins.maplist(AddOnCreator.gpg_keys) do |key|
        name = AddOnCreator.GetKeyUID(key)
        Item(
          Id(key),
          name != "" ? Builtins.sformat("%1 (%2)", key, name) : key,
          key == gpg_key
        )
      end

      contents = HBox(
        HSpacing(),
        VBox(
          HBox(
            ReplacePoint(
              Id(:rpcombo),
              ComboBox(
                Id(:gpg_keys),
                Opt(:editable, :hstretch),
                # combo box label
                _("GPG &Key ID"),
                gpg_keys
              )
            ),
            VBox(
              Label(""),
              # button label
              PushButton(Id(:create_key), _("&Create..."))
            )
          ),
          # password entry label
          Password(
            Id(:pw),
            Opt(:hstretch),
            _("&Passphrase"),
            Ops.get_string(AddOnCreator.passphrases, gpg_key, "")
          ),
          # password entry label (verification)
          Password(
            Id(:pw2),
            Opt(:hstretch),
            _("&Passphrase Verification"),
            Ops.get_string(AddOnCreator.passphrases, gpg_key, "")
          ),
          # checkbox label
          Left(
            CheckBox(
              Id(:resign),
              _("Re&sign all packages with selected key."),
              Ops.get_boolean(current_product, "resign_packages", false)
            )
          ),
          VSpacing(0.7)
        ),
        HSpacing()
      )
      # FIXME checkbox (so there's a chance not to sign...)

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "signing", ""),
        Label.BackButton,
        Label.NextButton
      )
      UI.SetFocus(Id(:pw))

      ret = nil

      while true
        ret = UI.UserInput
        key = Convert.to_string(UI.QueryWidget(Id(:gpg_keys), :Value))
        if ret == :create_key
          k = GenerateKeyDialog()
          if k != ""
            UI.ChangeWidget(
              Id(:gpg_keys),
              :Items,
              Builtins.maplist(AddOnCreator.gpg_keys) { |v| Item(v, v == k) }
            )
          end
        elsif ret == :next
          pw = Convert.to_string(UI.QueryWidget(Id(:pw), :Value))
          if pw != Convert.to_string(UI.QueryWidget(Id(:pw2), :Value))
            # error message
            Popup.Error(_("Passwords do not match. Try again."))
            UI.SetFocus(Id(:pw))
            next
          end

          resign = Convert.to_boolean(UI.QueryWidget(Id(:resign), :Value))
          if resign && !Package.Install("expect")
            UI.ChangeWidget(Id(:resign), :Value, false)
            next
          end
          Ops.set(AddOnCreator.passphrases, key, pw)
          Ops.set(AddOnCreator.current_product, "ask_for_passphrase", pw != "")
          Ops.set(AddOnCreator.current_product, "gpg_key", key)
          Ops.set(AddOnCreator.current_product, "resign_packages", resign)
          break
        elsif ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :back
          break
        end
      end
      deep_copy(ret)
    end

    # Output settings
    # @return dialog result
    def OutputDialog
      # dialog caption
      caption = _("Output Settings")
      current_product = deep_copy(AddOnCreator.current_product)
      iso = Ops.get_boolean(current_product, "iso", false)
      changelog = Ops.get_boolean(current_product, "changelog", false)
      autorun = false
      content_map = deep_copy(AddOnCreator.content_map)

      iso_name = Ops.get_string(current_product, "iso_name", "")
      if iso_name == ""
        iso_name = Builtins.sformat(
          "%1-%2", # FIXME no DEFAULTBASE for %1-%2-%3
          Builtins.tolower(Ops.get(content_map, "NAME", "")),
          Ops.get(content_map, "VERSION", "")
        )
      end

      contents = HBox(
        HSpacing(),
        VBox(
          HBox(
            InputField(
              Id(:output_path),
              Opt(:hstretch),
              # text entry label
              _("P&ath to Output Directory"),
              Ops.get_string(current_product, "base_output_path", "")
            ),
            VBox(Label(""), PushButton(Id(:browse), Label.BrowseButton))
          ),
          # check box label
          Left(CheckBox(Id(:iso), Opt(:notify), _("Create &ISO Image"), iso)),
          HBox(
            HSpacing(2),
            # text entry label
            InputField(
              Id(:iso_name),
              Opt(:hstretch),
              _("Image File Name"),
              iso_name
            )
          ),
          VSpacing(0.4),
          # check box label
          Left(CheckBox(Id(:changelog), _("&Generate Changelog"), changelog)),
          VSpacing(4),
          HBox(
            HStretch(),
            # button label
            PushButton(Id(:workflow), _("&Configure Workflow...")),
            # button label
            PushButton(Id(:expert), _("O&ptional Files..."))
          )
        ),
        HSpacing()
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "output", ""),
        Label.BackButton,
        Label.NextButton
      )
      UI.SetFocus(Id(:output_path))
      UI.ChangeWidget(Id(:iso_name), :Enabled, iso)

      ret = nil
      while true
        ret = UI.UserInput
        dir = Convert.to_string(UI.QueryWidget(Id(:output_path), :Value))
        changelog2 = Convert.to_boolean(UI.QueryWidget(Id(:changelog), :Value))
        iso2 = Convert.to_boolean(UI.QueryWidget(Id(:iso), :Value))
        iso_name = Convert.to_string(UI.QueryWidget(Id(:iso_name), :Value))
        UI.ChangeWidget(Id(:iso_name), :Enabled, iso2)
        if ret == :browse
          dir = UI.AskForExistingDirectory(dir, "")
          if dir != nil
            if Ops.add(Builtins.findlastof(dir, "/"), 1) == Builtins.size(dir)
              dir = Builtins.substring(
                dir,
                0,
                Ops.subtract(Builtins.size(dir), 1)
              )
            end
            UI.ChangeWidget(Id(:output_path), :Value, dir)
          end
        elsif ret == :expert || ret == :workflow
          Ops.set(AddOnCreator.current_product, "base_output_path", dir)
          Ops.set(AddOnCreator.current_product, "iso", iso2)
          Ops.set(AddOnCreator.current_product, "iso_name", iso_name)
          Ops.set(AddOnCreator.current_product, "changelog", changelog2)
          break
        elsif ret == :next
          if dir == ""
            # error popup
            Popup.Error(_("Enter the path to the directory for the add-on."))
            UI.SetFocus(Id(:output_path))
            next
          end
          if !FileUtils.Exists(dir)
            if !Popup.YesNo(Message.DirectoryDoesNotExistCreate(dir))
              next
            elsif !Convert.to_boolean(SCR.Execute(path(".target.mkdir"), dir))
              Popup.Error(Message.UnableToCreateDirectory(dir))
              next
            end
          end
          Ops.set(AddOnCreator.current_product, "base_output_path", dir)
          Ops.set(AddOnCreator.current_product, "iso", iso2)
          Ops.set(AddOnCreator.current_product, "iso_name", iso_name)
          Ops.set(AddOnCreator.current_product, "changelog", changelog2)
          if iso2 && !Package.Install("cdrkit-cdrtools-compat")
            UI.ChangeWidget(Id(:iso), :Value, false)
            ret = :notnext
            next
          end
          break
        elsif ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :back
          break
        end
      end
      deep_copy(ret)
    end


    # Dialof with overview of the product
    # @return dialog result
    def OverviewDialog
      # dialog caption
      caption = _("Overview")

      current_product = deep_copy(AddOnCreator.current_product)

      sum = ""

      # summary header
      sum = Summary.AddHeader(sum, _("Product Name"))
      sum = Summary.AddLine(sum, Ops.get(AddOnCreator.content_map, "NAME", ""))

      # summary header
      sum = Summary.AddHeader(sum, _("Patterns"))
      sum = Summary.OpenList(sum)
      Builtins.foreach(Ops.get_map(current_product, "patterns", {})) do |name, p|
        sum = Summary.AddListItem(sum, Ops.get_string(p, "Pat", name))
      end
      sum = Summary.CloseList(sum)

      # summary header
      sum = Summary.AddHeader(sum, _("Input Directory"))
      sum = Summary.AddLine(
        sum,
        Ops.get_string(current_product, "rpm_path", "")
      )

      # summary header
      sum = Summary.AddHeader(sum, _("Output Directory"))
      sum = Summary.AddLine(
        sum,
        Ops.get_string(current_product, "base_output_path", "")
      )

      if Ops.get_boolean(current_product, "iso", false)
        sum = Summary.AddLine(
          sum,
          # summary line
          _("Creating an ISO image in the output directory")
        )
      end

      contents = RichText(sum)
      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "overview", ""),
        Label.BackButton,
        Label.FinishButton
      )

      ret = nil
      while true
        ret = UI.UserInput

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next || ret == :back
          break
        end
      end
      deep_copy(ret)
    end
  end
end
