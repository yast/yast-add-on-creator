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
  module AddOnCreatorPatternsInclude
    def initialize_add_on_creator_patterns(include_target)
      textdomain "add-on-creator"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "String"
      Yast.import "Wizard"
      Yast.import "AddOnCreator"

      Yast.include include_target, "add-on-creator/helps.rb"

      # how to show and handle pattern keys
      @pattern_descr = deep_copy(AddOnCreator.pattern_descr)
    end

    def create_full_name(pattern)
      pattern = deep_copy(pattern)
      AddOnCreator.CreatePatternFullName(pattern, false)
    end


    # new pattern map - maybe add default values to pattern_descr map?
    def new_pattern_old(name)
      ret = Builtins.mapmap(
        Convert.convert(
          @pattern_descr,
          :from => "map",
          :to   => "map <string, map>"
        )
      ) do |key, descr|
        {
          key => Builtins.haskey(descr, "defval") ?
            Ops.get(descr, "defval") :
            ""
        }
      end
      Ops.set(ret, "name", name)
      Ops.set(ret, "Pat", create_full_name(ret))
      deep_copy(ret)
    end

    # new pattern map - maybe add default values to pattern_descr map?
    def new_pattern(pattern)
      pattern = deep_copy(pattern)
      ret = Builtins.mapmap(
        Convert.convert(
          @pattern_descr,
          :from => "map",
          :to   => "map <string, map>"
        )
      ) do |key, descr|
        {
          key => Builtins.haskey(descr, "defval") ?
            Ops.get(descr, "defval") :
            ""
        }
      end
      Builtins.foreach(
        Convert.convert(pattern, :from => "map", :to => "map <string, any>")
      ) { |key, val| Ops.set(ret, key, val) }
      Ops.set(ret, "Pat", create_full_name(ret))
      deep_copy(ret)
    end

    # add new pattern: get the identification (currently only name)
    # return its name
    #string AddPattern (list<string> conflicts) {
    def AddPattern(conflicts)
      conflicts = deep_copy(conflicts)
      ret = {}

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            HBox(
              # text entry label
              InputField(
                Id("name"),
                Opt(:hstretch),
                _("&Name of the New Pattern")
              ),
              # combo box label
              ComboBox(
                Id("arch"),
                _("&Architecture"),
                Builtins.maplist(
                  Ops.get_list(@pattern_descr, ["arch", "allowed_values"], [])
                ) { |v| v }
              )
            ),
            HBox(
              # text entry label
              InputField(Id("version"), Opt(:hstretch), _("&Version")),
              # text entry label
              InputField(Id("release"), Opt(:hstretch), _("&Release"))
            ),
            ButtonBox(
              PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton)
            )
          ),
          HSpacing(1)
        )
      )
      UI.SetFocus(Id("name"))
      UI.ChangeWidget(Id("name"), :ValidChars, Ops.add(String.CAlnum, "-_=."))
      while true
        result = UI.UserInput
        break if result == :cancel
        if result == :ok
          name = Convert.to_string(UI.QueryWidget(Id("name"), :Value))
          arch = Convert.to_string(UI.QueryWidget(Id("arch"), :Value))
          break if name == ""
          if Builtins.contains(Ops.get(conflicts, name, []), arch)
            # popup message
            Popup.Error(
              _(
                "Such a pattern already exists.\nChoose a different name or architecture.\n"
              )
            )
            next
          end
          Builtins.foreach(["name", "version", "release", "arch"]) do |key|
            val = Convert.to_string(UI.QueryWidget(Id(key), :Value))
            Ops.set(ret, key, val) if val != ""
          end
          break
        end
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    # edit the key and value in pattern description
    def AddPatternValue(conflicts)
      conflicts = deep_copy(conflicts)
      ret = {}
      # textentry label
      label = _("&Value")
      help = Builtins.mergestring(
        Builtins.maplist(["Des", "Sum", "Cat"]) do |k|
          Builtins.sformat(
            "<p><b>%1</b></p>%2",
            Ops.get_string(AddOnCreator.pattern_descr, [k, "label"], ""),
            Ops.get_string(AddOnCreator.pattern_descr, [k, "lang_help"], "")
          )
        end,
        "<br>"
      )
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(0.5),
            RadioButtonGroup(
              Id(:rd),
              Left(
                HVSquash(
                  VBox(
                    Left(
                      RadioButton(
                        Id("Des"),
                        Opt(:notify),
                        _("&Description"),
                        true
                      )
                    ),
                    Left(RadioButton(Id("Sum"), Opt(:notify), _("&Summary"))),
                    Left(RadioButton(Id("Cat"), Opt(:notify), _("Ca&tegory")))
                  )
                )
              )
            ),
            # combo label
            Left(
              ComboBox(
                Id(:lang),
                Opt(:editable),
                _("&Language Code"),
                AddOnCreator.GetLangCodes(false)
              )
            ),
            ReplacePoint(Id(:rp), MultiLineEdit(Id(:val), label, "")),
            HBox(
              PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
              PushButton(Id(:help), Opt(:key_F2), Label.HelpButton)
            )
          ),
          HSpacing(1)
        )
      )
      UI.SetFocus(Id("Des"))
      while true
        result = UI.UserInput
        if result == :cancel
          ret = {}
          break
        end
        val = Convert.to_string(UI.QueryWidget(Id(:val), :Value))
        if result == "Des"
          UI.ReplaceWidget(Id(:rp), MultiLineEdit(Id(:val), label, val))
        end
        if result == "Sum" || result == "Cat"
          UI.ReplaceWidget(
            Id(:rp),
            TextEntry(Id(:val), label, value2string(val))
          )
        end
        if result == :help
          # Heading for help popup window
          Popup.LongText(_("Help"), RichText(help), 50, 14)
        end
        if result == :ok
          key = Builtins.sformat(
            "%1.%2",
            UI.QueryWidget(Id(:rd), :Value),
            UI.QueryWidget(Id(:lang), :Value)
          )
          if Builtins.contains(conflicts, key)
            # popup message
            Popup.Error(
              _("A key with this name already exists.\nChoose a different one.")
            )
            next
          end
          ret = { "key" => key, "value" => val }
          break
        end
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    # Dialog for editing patterns
    # @return dialog result
    def PatternsDialog
      current_product = deep_copy(AddOnCreator.current_product)
      import_path = Ops.get_string(current_product, "rpm_path", "")
      patterns = Ops.get_map(current_product, "patterns", {})
      content_patterns = Ops.get(AddOnCreator.content_map, "PATTERNS", "")
      proposed_patterns = Builtins.splitstring(content_patterns, " ")

      # helper for generation of table items
      get_pattern_items = lambda do |pattern|
        pattern = deep_copy(pattern)
        ret2 = []
        Builtins.foreach(
          Convert.convert(pattern, :from => "map", :to => "map <string, any>")
        ) do |key, value|
          pat = Ops.get_map(@pattern_descr, key, {})
          if pat == {}
            shortkey = Builtins.substring(key, 0, 3)
            pat = Ops.get_map(@pattern_descr, shortkey, {})
            Ops.set(
              pat,
              "label",
              Ops.add(
                Ops.get_string(pat, "label", ""),
                Builtins.sformat(" (%1)", Builtins.substring(key, 4))
              )
            )
          end
          if pat != {} && Ops.get_string(pat, "label", "") != ""
            ret2 = Builtins.add(
              ret2,
              Item(
                Id(key),
                Ops.get_string(pat, "label", ""),
                value2string(value)
              )
            )
          end
        end
        deep_copy(ret2)
      end

      get_patterns_items = lambda { Builtins.maplist(patterns) do |full_name, pattern|
        name = Ops.get_string(pattern, "name", "")
        Item(Id(full_name), name, full_name)
      end }


      # dialog caption
      caption = _("Editor for Patterns")

      contents = HBox(
        HSpacing(),
        VBox(
          VSpacing(0.5),
          VWeight(
            1,
            Table(
              Id(:patterns),
              Opt(:notify, :immediate),
              # table header
              Header(
                _("Name of the Pattern"),
                # table header
                _("Full Name")
              ),
              get_patterns_items.call
            )
          ),
          HBox(
            PushButton(Id(:new_pt), Opt(:key_F3), Label.NewButton),
            # button label
            PushButton(Id(:import_pt), Opt(:key_F4), _("I&mport")),
            PushButton(Id(:delete_pt), Opt(:key_F5), Label.DeleteButton),
            HStretch()
          ),
          VWeight(
            2,
            Table(
              Id(:pattern),
              Opt(:notify),
              Header(
                # table header 1/2
                _("Attribute"),
                # table header 2/2
                _("Value")
              ),
              []
            )
          ),
          HBox(
            PushButton(Id(:add), Opt(:key_F6), Label.AddButton),
            PushButton(Id(:edit), Opt(:key_F7), Label.EditButton),
            PushButton(Id(:delete), Opt(:key_F8), Label.DeleteButton),
            HStretch(),
            # check box label
            CheckBox(
              Id(:required),
              Opt(:notify, :key_F8),
              _("R&equired Pattern"),
              false
            )
          ),
          VSpacing(0.5)
        ),
        HSpacing()
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "patterns", ""),
        Label.BackButton,
        Label.NextButton
      )
      UI.SetFocus(Id(:patterns))
      current_pattern = Convert.to_string(
        UI.QueryWidget(Id(:patterns), :CurrentItem)
      )
      current_pattern_map = Ops.get(patterns, current_pattern, {})
      if Ops.get(patterns, current_pattern) != nil
        UI.ChangeWidget(
          Id(:pattern),
          :Items,
          get_pattern_items.call(Ops.get(patterns, current_pattern, {}))
        )
        UI.ChangeWidget(
          Id(:required),
          :Value,
          Builtins.contains(
            proposed_patterns,
            Ops.get_string(current_pattern_map, "name", "")
          )
        )
      end
      Builtins.foreach([:delete_pt, :edit, :add, :delete, :required]) do |w|
        UI.ChangeWidget(Id(w), :Enabled, patterns != {})
      end

      ret = nil
      while true
        ret = Convert.to_symbol(UI.UserInput)

        conflicts = {}
        if ret == :new_pt || ret == :edit || ret == :pattern
          Builtins.foreach(patterns) do |pat, p|
            name = Ops.get_string(p, "name", "")
            if Builtins.haskey(conflicts, name)
              Ops.set(
                conflicts,
                name,
                Builtins.add(
                  Ops.get(conflicts, name, []),
                  Ops.get_string(p, "arch", "")
                )
              )
            else
              Ops.set(conflicts, name, [Ops.get_string(p, "arch", "")])
            end
          end
        end
        if ret == :new_pt
          new_pt = AddPattern(conflicts)
          if new_pt != {}
            new_pt = new_pattern(new_pt)
            full_name = Ops.get_string(new_pt, "Pat", "")
            Ops.set(patterns, full_name, new_pt)
            UI.ChangeWidget(Id(:patterns), :Items, get_patterns_items.call)
            UI.ChangeWidget(Id(:patterns), :CurrentItem, full_name)
          end
        elsif ret == :import_pt
          file = UI.AskForExistingFile(
            import_path,
            "*.pat *.pat.gz",
            # popup for file selection dialog
            _("Existing Pattern")
          )
          if file != nil
            short2full = Builtins.mapmap(patterns) do |full, p|
              {
                Ops.add(
                  Ops.add(Ops.get_string(p, "name", ""), " "),
                  Ops.get_string(p, "arch", "")
                ) => full
              }
            end
            pats = AddOnCreator.ReadPatternsFile(file)
            full_name = ""
            Builtins.foreach(pats) do |pat|
              full_name = Ops.get_string(pat, "Pat", "")
              pt = Builtins.splitstring(full_name, " ")
              if full_name != ""
                Ops.set(pat, "name", Ops.get(pt, 0, ""))
                Ops.set(pat, "version", Ops.get(pt, 1, ""))
                Ops.set(pat, "release", Ops.get(pt, 2, ""))
                Ops.set(pat, "arch", Ops.get(pt, 3, ""))
                short = Ops.add(
                  Ops.add(Ops.get(pt, 0, ""), " "),
                  Ops.get(pt, 3, "")
                )
                # replace existing pattern with same name and arch
                if Builtins.haskey(short2full, short)
                  Builtins.y2internal(
                    "replacing pattern %1",
                    Ops.get_string(short2full, short, "")
                  )
                  patterns = Builtins.remove(
                    patterns,
                    Ops.get_string(short2full, short, "")
                  )
                end
                Ops.set(patterns, full_name, pat)
              end
            end
            UI.ChangeWidget(Id(:patterns), :Items, get_patterns_items.call)
            if full_name != ""
              UI.ChangeWidget(Id(:patterns), :CurrentItem, full_name)
            end
            import_path = file
          end
        elsif ret == :delete_pt
          sel2 = Convert.to_string(UI.QueryWidget(Id(:patterns), :CurrentItem))
          if sel2 != nil
            patterns = Builtins.remove(patterns, sel2)
            UI.ChangeWidget(Id(:patterns), :Items, get_patterns_items.call)
            UI.SetFocus(Id(:patterns))
          end
        end
        if Builtins.contains([:new_pt, :import_pt, :delete_pt], ret)
          Builtins.foreach([:delete_pt, :edit, :add, :delete, :required]) do |s|
            UI.ChangeWidget(Id(s), :Enabled, patterns != {})
          end
          ret = :patterns
          UI.SetFocus(Id(:pattern)) if ret != :delete_pt
        end
        sel = Convert.to_string(UI.QueryWidget(Id(:patterns), :CurrentItem))
        if ret == :patterns
          if sel != current_pattern
            current_pattern = sel
            current_pattern_map = Ops.get(patterns, current_pattern, {})
            UI.ChangeWidget(
              Id(:pattern),
              :Items,
              get_pattern_items.call(current_pattern_map)
            )
            UI.ChangeWidget(
              Id(:required),
              :Value,
              Ops.greater_than(Builtins.size(patterns), 0) &&
                Builtins.contains(
                  proposed_patterns,
                  Ops.get_string(current_pattern_map, "name", "")
                )
            )
          end
        elsif ret == :add
          new_val = AddPatternValue(
            Builtins.maplist(
              Convert.convert(
                Ops.get(patterns, sel, {}),
                :from => "map",
                :to   => "map <string, any>"
              )
            ) { |k, a| k }
          )
          if new_val != {}
            Ops.set(
              patterns,
              [sel, Ops.get_string(new_val, "key", "")],
              Ops.get_string(new_val, "value", "")
            )
            UI.ChangeWidget(
              Id(:pattern),
              :Items,
              get_pattern_items.call(Ops.get(patterns, sel, {}))
            )
            UI.ChangeWidget(Id(:required), :Value, false)
          end
          UI.SetFocus(Id(:pattern))
        elsif ret == :delete
          key = Convert.to_string(UI.QueryWidget(Id(:pattern), :CurrentItem))
          Ops.set(
            patterns,
            sel,
            Builtins.remove(Ops.get(patterns, sel, {}), key)
          )
          UI.ChangeWidget(
            Id(:pattern),
            :Items,
            get_pattern_items.call(Ops.get(patterns, sel, {}))
          )
          UI.SetFocus(Id(:pattern))
        elsif ret == :edit || ret == :pattern
          key = Convert.to_string(UI.QueryWidget(Id(:pattern), :CurrentItem))
          pat = Ops.get_map(@pattern_descr, key, {})
          if pat == {}
            shortkey = Builtins.substring(key, 0, 3)
            pat = Ops.get_map(@pattern_descr, shortkey, {})
            Ops.set(
              pat,
              "label",
              Ops.add(
                Ops.get_string(pat, "label", ""),
                Builtins.sformat(" (%1)", Builtins.substring(key, 4))
              )
            )
            Ops.set(
              pat,
              "help",
              Ops.get_string(pat, "lang_help", Ops.get_string(pat, "help", ""))
            )
          end

          pattern = Ops.get(patterns, sel, {})

          val = EditValue(
            Builtins.union(pat, { "value" => Ops.get(pattern, key) }),
            "pattern"
          )
          if val != nil
            if key == "arch"
              conflict = false
              Builtins.foreach(conflicts) do |p, archs|
                if Builtins.contains(archs, val)
                  conflict = true
                  raise Break
                end
              end
              if conflict
                # error message
                Popup.Error(
                  _(
                    "Such a pattern already exists.\nChoose a different architecture.\n"
                  )
                )
                next
              end
            elsif !Ops.get_boolean(@pattern_descr, [key, "adapt_name"], false)
              Ops.set(patterns, [sel, key], val)
            end
            UI.ChangeWidget(
              Id(:pattern),
              term(:Item, key, 1),
              value2string(val)
            )
          end
          if Ops.get_boolean(@pattern_descr, [key, "adapt_name"], false)
            # key in the map was changed, generate affected items again
            Ops.set(pattern, key, val)
            full_name = create_full_name(pattern)
            Ops.set(pattern, "Pat", full_name)
            patterns = Builtins.remove(patterns, sel)
            Ops.set(patterns, full_name, pattern)
            UI.ChangeWidget(Id(:patterns), :Items, get_patterns_items.call)
          end
          UI.SetFocus(Id(:pattern))
        elsif ret == :required
          name = Ops.get_string(patterns, [sel, "name"], "")
          if UI.QueryWidget(Id(:required), :Value) == true
            if !Builtins.contains(proposed_patterns, name)
              proposed_patterns = Builtins.add(proposed_patterns, name)
            end
          elsif Builtins.contains(proposed_patterns, name)
            proposed_patterns = Builtins.filter(proposed_patterns) do |p|
              name != p
            end
          end
        elsif ret == :next
          Ops.set(AddOnCreator.current_product, "patterns", patterns)
          content_patterns = Builtins.mergestring(proposed_patterns, " ")
          if Ops.get(AddOnCreator.content_map, "PATTERNS", "") != content_patterns
            i = 0
            Builtins.foreach(AddOnCreator.content) do |entry|
              if Ops.get_string(entry, "key", "") == "PATTERNS"
                Ops.set(AddOnCreator.content, [i, "value"], content_patterns)
              end
              i = Ops.add(i, 1)
            end
            Ops.set(AddOnCreator.content_map, "PATTERNS", content_patterns)
          end
          break
        elsif ret == :back
          break
        elsif ret == :abort || ret == :cancel
          break if ReallyAbort()
          next
        end
      end
      ret
    end
  end
end
