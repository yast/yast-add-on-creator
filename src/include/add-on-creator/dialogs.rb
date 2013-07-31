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
  module AddOnCreatorDialogsInclude
    def initialize_add_on_creator_dialogs(include_target)
      textdomain "add-on-creator"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "AddOnCreator"

      Yast.include include_target, "add-on-creator/helps.rb"
    end

    # add the new readme/license file
    def AddFile(label, conflicts, values)
      conflicts = deep_copy(conflicts)
      values = deep_copy(values)
      ret = nil
      allowed = values == nil ? [] : Builtins.filter(values) do |v|
        !Builtins.contains(conflicts, v)
      end

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            values == nil ?
              TextEntry(Id(:file), label, "") :
              ComboBox(Id(:file), Opt(:editable), label, allowed),
            HBox(
              PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton)
            )
          ),
          HSpacing(1)
        )
      )
      UI.SetFocus(Id(:file))
      while true
        result = UI.UserInput
        if result == :cancel
          ret = nil
          break
        end
        if result == :ok
          ret = Convert.to_string(UI.QueryWidget(Id(:file), :Value))
          if Builtins.contains(conflicts, ret)
            # popup message
            Popup.Error(
              _(
                "A file with this name already exists.\nChoose a different one."
              )
            )
            ret = nil
            next
          end
          break
        end
      end
      UI.CloseDialog
      ret
    end

    # @return dialog result
    def ExpertSettingsDialog
      current_product = deep_copy(AddOnCreator.current_product)

      # dialog caption
      caption = _("Expert Settings")

      info = Ops.get_string(current_product, "info", "")
      license_files = Ops.get_map(current_product, "license_files", {})
      readme_files = Ops.get_map(current_product, "readme_files", {})

      replace_readme_widgets = lambda do |active|
        UI.ReplaceWidget(
          Id(:rpfiles),
          ComboBox(
            Id(:readme_files),
            Opt(:notify, :hstretch),
            "",
            Builtins.maplist(readme_files) { |f, c| Item(Id(f), f, f == active) }
          )
        )

        nil
      end
      replace_license_widgets = lambda do |active|
        UI.ReplaceWidget(
          Id(:rplicenses),
          ComboBox(
            Id(:lic_files),
            Opt(:notify, :hstretch),
            "",
            Builtins.maplist(license_files) do |f, c|
              Item(Id(f), f, f == active)
            end
          )
        )

        nil
      end

      contents = HBox(
        HSpacing(),
        VBox(
          VWeight(2, MultiLineEdit(Id(:info), _("&info.txt File"), info)),
          # frame label
          VWeight(
            4,
            Frame(
              _("&License Files"),
              HBox(
                HSpacing(0.4),
                VBox(
                  HBox(
                    ReplacePoint(
                      Id(:rplicenses),
                      ComboBox(
                        Id(:lic_files),
                        Opt(:notify, :hstretch),
                        "",
                        Builtins.maplist(license_files) { |f, c| f }
                      )
                    ),
                    PushButton(Id(:add_license), Label.AddButton),
                    # button label
                    PushButton(Id(:import_license), _("I&mport")),
                    PushButton(Id(:delete_license), Label.DeleteButton)
                  ),
                  MultiLineEdit(Id(:license), "")
                ),
                HSpacing(0.4)
              )
            )
          ),
          VSpacing(0.7),
          # frame label
          VWeight(
            4,
            Frame(
              _("README Files"),
              HBox(
                HSpacing(0.4),
                VBox(
                  HBox(
                    ReplacePoint(
                      Id(:rpfiles),
                      ComboBox(
                        Id(:readme_files),
                        Opt(:notify, :hstretch),
                        "",
                        Builtins.maplist(readme_files) { |f, c| f }
                      )
                    ),
                    PushButton(Id(:add_readme), Label.AddButton),
                    # button label
                    PushButton(Id(:import_readme), _("Im&port")),
                    PushButton(Id(:delete_readme), Label.DeleteButton)
                  ),
                  MultiLineEdit(Id(:readme), "")
                ),
                HSpacing(0.4)
              )
            )
          ),
          VSpacing(0.7)
        ),
        HSpacing()
      )


      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "expert", ""),
        Label.BackButton,
        Label.NextButton
      )
      Wizard.HideAbortButton

      current_readme = Convert.to_string(
        UI.QueryWidget(Id(:readme_files), :Value)
      )
      if Ops.get(readme_files, current_readme, "") != ""
        UI.ChangeWidget(
          Id(:readme),
          :Value,
          Ops.get(readme_files, current_readme, "")
        )
      end
      current_license = Convert.to_string(
        UI.QueryWidget(Id(:lic_files), :Value)
      )
      if Ops.get(license_files, current_license, "") != ""
        UI.ChangeWidget(
          Id(:license),
          :Value,
          Ops.get(license_files, current_license, "")
        )
      end

      UI.ChangeWidget(Id(:delete_readme), :Enabled, readme_files != {})
      UI.ChangeWidget(Id(:delete_license), :Enabled, license_files != {})

      ret = nil
      while true
        ret = UI.UserInput
        if ret == :add_readme
          new = AddFile(
            # textentry label
            _("&Name of the New README File"),
            Builtins.maplist(readme_files) { |f, c| f },
            nil
          )
          if new != nil
            Ops.set(readme_files, new, "")
            replace_readme_widgets.call(new)
            ret = :readme_files
            UI.SetFocus(Id(:readme))
          end
          UI.ChangeWidget(Id(:delete_readme), :Enabled, readme_files != {})
        end
        if ret == :import_readme
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "",
            # popup for file selection dialog
            _("Choose the New README File")
          )
          if file != nil
            imported = Convert.to_string(SCR.Read(path(".target.string"), file))
            if imported != nil
              new = Builtins.substring(
                file,
                Ops.add(Builtins.findlastof(file, "/"), 1)
              )
              Ops.set(readme_files, new, imported)
              replace_readme_widgets.call(new)
              current_readme = nil
              ret = :readme_files
              UI.SetFocus(Id(:readme))
            end
          end
        end
        fr = Convert.to_string(UI.QueryWidget(Id(:readme_files), :Value))
        if ret == :delete_readme
          readme_files = Builtins.remove(readme_files, fr)
          replace_readme_widgets.call("")
          ret = :readme_files
          fr = Convert.to_string(UI.QueryWidget(Id(:readme_files), :Value))
          current_readme = nil
          UI.ChangeWidget(Id(:delete_readme), :Enabled, readme_files != {})
        end
        if ret == :readme_files
          if fr != current_readme
            if current_readme != nil
              Ops.set(
                readme_files,
                current_readme,
                Convert.to_string(UI.QueryWidget(Id(:readme), :Value))
              )
            end
            current_readme = fr
            UI.ChangeWidget(Id(:readme), :Value, Ops.get(readme_files, fr, ""))
          end
        end
        if ret == :add_license
          new = AddFile(
            # textentry label
            _("&Language for the New License File"),
            Builtins.maplist(license_files) do |f, c|
              f == "license" ? "" : Builtins.substring(f, 8)
            end,
            AddOnCreator.GetLangCodes(true)
          )
          if new != nil
            new = Ops.add("license" + (new == "" ? "" : "."), new)
            Ops.set(license_files, new, "")
            replace_license_widgets.call(new)
            ret = :lic_files
            UI.SetFocus(Id(:license))
          end
          UI.ChangeWidget(Id(:delete_license), :Enabled, license_files != {})
        end
        if ret == :import_license
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "license*",
            # popup for file selection dialog
            _("Choose the New License File")
          )
          if file != nil
            imported = Convert.to_string(SCR.Read(path(".target.string"), file))
            if imported != nil
              new = Builtins.substring(
                file,
                Ops.add(Builtins.findlastof(file, "/"), 1)
              )
              Ops.set(license_files, new, imported)
              replace_license_widgets.call(new)
              current_license = nil
              ret = :lic_files
              UI.SetFocus(Id(:license))
            end
          end
        end
        fl = Convert.to_string(UI.QueryWidget(Id(:lic_files), :Value))
        if ret == :delete_license
          license_files = Builtins.remove(license_files, fl)
          replace_license_widgets.call("")
          ret = :lic_files
          fl = Convert.to_string(UI.QueryWidget(Id(:lic_files), :Value))
          current_license = nil
          UI.ChangeWidget(Id(:delete_license), :Enabled, license_files != {})
        end
        if ret == :lic_files
          if fl != current_license
            if current_license != nil
              Ops.set(
                license_files,
                current_license,
                Convert.to_string(UI.QueryWidget(Id(:license), :Value))
              )
            end
            current_license = fl
            UI.ChangeWidget(
              Id(:license),
              :Value,
              Ops.get(license_files, fl, "")
            )
          end
        elsif ret == :next
          Ops.set(
            readme_files,
            current_readme,
            Convert.to_string(UI.QueryWidget(Id(:readme), :Value))
          )
          Ops.set(
            license_files,
            current_license,
            Convert.to_string(UI.QueryWidget(Id(:license), :Value))
          )
          # AddOnCreator::media =
          # 		(string) UI::QueryWidget (`id(`media),`Value);
          Ops.set(
            AddOnCreator.current_product,
            "info",
            UI.QueryWidget(Id(:info), :Value)
          )
          Ops.set(AddOnCreator.current_product, "readme_files", readme_files)
          Ops.set(AddOnCreator.current_product, "license_files", license_files)
          break
        elsif ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :back
          Wizard.RestoreAbortButton
          break
        end
      end
      deep_copy(ret)
    end

    # editor of COPYING, COPYING.lang, COPYRIGHT, COPYRIGHT.lang
    # @return dialog result
    def ExpertSettingsDialog2
      # dialog caption
      caption = _("Expert Settings, Part 2")

      current_product = deep_copy(AddOnCreator.current_product)
      copying_files = Ops.get_map(current_product, "copying_files", {})
      copyright_files = Ops.get_map(current_product, "copyright_files", {})

      replace_copyright_widgets = lambda do |active|
        UI.ReplaceWidget(
          Id(:rpfiles),
          ComboBox(
            Id(:copyright_files),
            Opt(:notify, :hstretch),
            "",
            Builtins.maplist(copyright_files) do |f, c|
              Item(Id(f), f, f == active)
            end
          )
        )
        UI.ChangeWidget(Id(:delete_copyright), :Enabled, copyright_files != {})

        nil
      end
      replace_copying_widgets = lambda do |active|
        UI.ReplaceWidget(
          Id(:rpcopyings),
          ComboBox(
            Id(:copying_files),
            Opt(:notify, :hstretch),
            "",
            Builtins.maplist(copying_files) do |f, c|
              Item(Id(f), f, f == active)
            end
          )
        )
        UI.ChangeWidget(Id(:delete_copying), :Enabled, copying_files != {})

        nil
      end

      contents = HBox(
        HSpacing(),
        VBox(
          # frame label
          Frame(
            _("&COPYING Files"),
            HBox(
              HSpacing(0.4),
              VBox(
                HBox(
                  ReplacePoint(
                    Id(:rpcopyings),
                    ComboBox(
                      Id(:copying_files),
                      Opt(:notify, :hstretch),
                      "",
                      Builtins.maplist(copying_files) { |f, c| f }
                    )
                  ),
                  PushButton(Id(:add_copying), Label.AddButton),
                  # button label
                  PushButton(Id(:import_copying), _("I&mport")),
                  PushButton(Id(:delete_copying), Label.DeleteButton)
                ),
                MultiLineEdit(Id(:copying), "")
              ),
              HSpacing(0.4)
            )
          ),
          VSpacing(0.7),
          # frame label
          Frame(
            _("COPY&RIGHT Files"),
            HBox(
              HSpacing(0.4),
              VBox(
                HBox(
                  ReplacePoint(
                    Id(:rpfiles),
                    ComboBox(
                      Id(:copyright_files),
                      Opt(:notify, :hstretch),
                      "",
                      Builtins.maplist(copyright_files) { |f, c| f }
                    )
                  ),
                  PushButton(Id(:add_copyright), Label.AddButton),
                  # button label
                  PushButton(Id(:import_copyright), _("Im&port")),
                  PushButton(Id(:delete_copyright), Label.DeleteButton)
                ),
                MultiLineEdit(Id(:copyright), "")
              ),
              HSpacing(0.4)
            )
          ),
          VSpacing(0.7)
        ),
        HSpacing()
      )


      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "expert2", ""),
        Label.BackButton,
        Label.NextButton
      )

      current_copyright = Convert.to_string(
        UI.QueryWidget(Id(:copyright_files), :Value)
      )
      if Ops.get(copyright_files, current_copyright, "") != ""
        UI.ChangeWidget(
          Id(:copyright),
          :Value,
          Ops.get(copyright_files, current_copyright, "")
        )
      end

      current_copying = Convert.to_string(
        UI.QueryWidget(Id(:copying_files), :Value)
      )
      if Ops.get(copying_files, current_copying, "") != ""
        UI.ChangeWidget(
          Id(:copying),
          :Value,
          Ops.get(copying_files, current_copying, "")
        )
      end

      UI.ChangeWidget(Id(:delete_copyright), :Enabled, copyright_files != {})
      UI.ChangeWidget(Id(:delete_copying), :Enabled, copying_files != {})

      ret = nil
      while true
        ret = UI.UserInput
        if ret == :add_copyright
          new = AddFile(
            # textentry label
            _("&Language for the New COPYRIGHT File"),
            Builtins.maplist(copyright_files) do |f, c|
              f == "COPYRIGHT" ? "" : Builtins.substring(f, 10)
            end,
            AddOnCreator.GetLangCodes(false)
          )
          if new != nil
            new = Ops.add("COPYRIGHT" + (new == "" ? "" : "."), new)
            Ops.set(copyright_files, new, "")
            replace_copyright_widgets.call(new)
            ret = :copyright_files
            UI.SetFocus(Id(:copyright))
          end
        end
        if ret == :import_copyright
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "COPYRIGHT*",
            # popup for file selection dialog
            _("Choose the New COPYRIGHT File")
          )
          if file != nil
            imported = Convert.to_string(SCR.Read(path(".target.string"), file))
            if imported != nil
              new = Builtins.substring(
                file,
                Ops.add(Builtins.findlastof(file, "/"), 1)
              )
              Ops.set(copyright_files, new, imported)
              replace_copyright_widgets.call(new)
              current_copyright = nil
              ret = :copyright_files
              UI.SetFocus(Id(:copyright))
            end
          end
        end
        cr = Convert.to_string(UI.QueryWidget(Id(:copyright_files), :Value))
        if ret == :delete_copyright
          copyright_files = Builtins.remove(copyright_files, cr)
          replace_copyright_widgets.call("")
          ret = :copyright_files
          cr = Convert.to_string(UI.QueryWidget(Id(:copyright_files), :Value))
          current_copyright = nil
        end
        if ret == :copyright_files
          if cr != current_copyright
            if current_copyright != nil
              Ops.set(
                copyright_files,
                current_copyright,
                Convert.to_string(UI.QueryWidget(Id(:copyright), :Value))
              )
            end
            current_copyright = cr
            UI.ChangeWidget(
              Id(:copyright),
              :Value,
              Ops.get(copyright_files, cr, "")
            )
          end
        end
        if ret == :add_copying
          new = AddFile(
            # textentry label
            _("&Language for the New COPYING File"),
            Builtins.maplist(copying_files) do |f, c|
              f == "COPYING" ? "" : Builtins.substring(f, 8)
            end,
            AddOnCreator.GetLangCodes(false)
          )
          if new != nil
            new = Ops.add("COPYING" + (new == "" ? "" : "."), new)
            Ops.set(copying_files, new, "")
            replace_copying_widgets.call(new)
            ret = :copying_files
            UI.SetFocus(Id(:copying))
          end
        end
        if ret == :import_copying
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "copying*",
            # popup for file selection dialog
            _("Choose the New COPYING File")
          )
          if file != nil
            imported = Convert.to_string(SCR.Read(path(".target.string"), file))
            if imported != nil
              new = Builtins.substring(
                file,
                Ops.add(Builtins.findlastof(file, "/"), 1)
              )
              Ops.set(copying_files, new, imported)
              replace_copying_widgets.call(new)
              current_copying = nil
              ret = :copying_files
              UI.SetFocus(Id(:copying))
            end
          end
        end
        co = Convert.to_string(UI.QueryWidget(Id(:copying_files), :Value))
        if ret == :delete_copying
          copying_files = Builtins.remove(copying_files, co)
          replace_copying_widgets.call("")
          ret = :copying_files
          co = Convert.to_string(UI.QueryWidget(Id(:copying_files), :Value))
          current_copying = nil
        end
        if ret == :copying_files
          if co != current_copying
            if current_copying != nil
              Ops.set(
                copying_files,
                current_copying,
                Convert.to_string(UI.QueryWidget(Id(:copying), :Value))
              )
            end
            current_copying = co
            UI.ChangeWidget(
              Id(:copying),
              :Value,
              Ops.get(copying_files, co, "")
            )
          end
        elsif ret == :next
          Ops.set(
            copyright_files,
            current_copyright,
            Convert.to_string(UI.QueryWidget(Id(:copyright), :Value))
          )
          Ops.set(
            copying_files,
            current_copying,
            Convert.to_string(UI.QueryWidget(Id(:copying), :Value))
          )
          Ops.set(
            AddOnCreator.current_product,
            "copyright_files",
            copyright_files
          )
          Ops.set(AddOnCreator.current_product, "copying_files", copying_files)
          Wizard.RestoreAbortButton
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

    # editor of patches, products, media files FIXME
    # @return dialog result
    def ExpertSettingsDialog3
      # dialog caption
      caption = _("Expert Settings, Part 3")

      current_product = deep_copy(AddOnCreator.current_product)
      products_files = Ops.get_list(current_product, "products_files", [])
      patches_files = Ops.get_list(current_product, "patches_files", [])
      media_files = Ops.get_list(current_product, "media_files", [])

      products = Ops.get(products_files, 0, "")
      patches = Ops.get(patches_files, 0, "")
      media = Ops.get(media_files, 0, "")

      contents = HBox(
        HSpacing(),
        VBox(
          MultiLineEdit(Id(:products), _("products"), products),
          Right(
            # button label
            PushButton(Id(:import_products), _("I&mport"))
          ),
          VSpacing(0.7),
          MultiLineEdit(Id(:patches), _("patches"), patches),
          Right(
            # button label
            PushButton(Id(:import_patches), _("&Import"))
          ),
          VSpacing(0.7),
          MultiLineEdit(Id(:media), _("media"), media),
          Right(
            # button label
            PushButton(Id(:import_media), _("Im&port"))
          ),
          VSpacing(0.7)
        ),
        HSpacing()
      )


      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "expert3", ""),
        Label.BackButton,
        Label.NextButton
      )


      ret = nil
      while true
        ret = UI.UserInput
        if ret == :next
          Wizard.RestoreAbortButton
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

    # Dialog for configuration of an installation workflow
    def WorkflowConfigurationDialog
      # dialog caption
      caption = _("Workflow Configuration")
      current_product = deep_copy(AddOnCreator.current_product)
      workflow_path = Ops.get_string(current_product, "workflow_path", "")
      y2update_path = Ops.get_string(current_product, "y2update_path", "")
      y2update_packages = Ops.get_list(current_product, "y2update_packages", [])
      # helper for updating table contents
      update_table = lambda do
        UI.ChangeWidget(
          Id(:y2update_packages),
          :Items,
          Builtins.maplist(y2update_packages) { |p| Item(Id(p), p) }
        )

        nil
      end

      contents = HBox(
        HSpacing(),
        VBox(
          HBox(
            TextEntry(
              Id(:workflow_path),
              # textentry label
              _("&Location of the File with the Workflow Description"),
              workflow_path
            ),
            VBox(Label(""), PushButton(Id(:browse), Label.BrowseButton))
          ),
          VSpacing(),
          RadioButtonGroup(
            Id(:rbg),
            VBox(
              Left(
                RadioButton(
                  Id(:no_additional),
                  Opt(:notify),
                  # radiobutton label
                  _("&No Additional YaST Modules"),
                  y2update_path == "" && y2update_packages == []
                )
              ),
              Left(
                RadioButton(
                  Id(:y2update_rb),
                  Opt(:notify),
                  # radiobutton label
                  _("&Path to y2update.tgz"),
                  y2update_path != ""
                )
              ),
              HBox(
                HSpacing(2),
                TextEntry(Id(:y2update_path), "", y2update_path),
                # pushbutton label
                PushButton(Id(:br_y2update), _("&Browse"))
              ),
              Left(
                RadioButton(
                  Id(:import),
                  Opt(:notify),
                  # radiobutton label
                  _("&Import the Packages"),
                  y2update_packages != [] && y2update_path == ""
                )
              ),
              HBox(
                HSpacing(2),
                VBox(
                  Table(
                    Id(:y2update_packages),
                    # table header
                    Header(_("YaST Module Package")),
                    []
                  ),
                  HBox(
                    PushButton(Id(:add), Label.AddButton),
                    PushButton(Id(:delete), Label.DeleteButton),
                    HStretch()
                  )
                )
              )
            )
          ),
          VSpacing(0.7)
        ),
        HSpacing()
      )


      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "workflow", ""),
        Label.BackButton,
        Label.NextButton
      )
      Wizard.HideAbortButton

      update_table.call
      Builtins.foreach([:y2update_path, :br_y2update]) do |w_id|
        UI.ChangeWidget(
          Id(w_id),
          :Enabled,
          UI.QueryWidget(Id(:rbg), :Value) == :y2update_rb
        )
      end
      Builtins.foreach([:y2update_packages, :add, :delete]) do |w_id|
        UI.ChangeWidget(
          Id(w_id),
          :Enabled,
          UI.QueryWidget(Id(:rbg), :Value) == :import
        )
      end
      UI.ChangeWidget(Id(:delete), :Enabled, y2update_packages != [])

      ret = nil
      while true
        ret = UI.UserInput
        if ret == :browse
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "*.xml",
            # popup for file selection dialog
            _("Choose the installation.xml File")
          )
          if file != nil #TODO check for xml format
            workflow_path = file
            UI.ChangeWidget(Id(:workflow_path), :Value, file)
          end
        elsif ret == :import || ret == :y2update_rb || ret == :no_additional
          Builtins.foreach([:y2update_packages, :add, :delete]) do |w_id|
            UI.ChangeWidget(Id(w_id), :Enabled, ret == :import)
          end
          Builtins.foreach([:y2update_path, :br_y2update]) do |w_id|
            UI.ChangeWidget(Id(w_id), :Enabled, ret == :y2update_rb)
          end
        end
        if ret == :br_y2update
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "y2update.tgz",
            # popup for file selection dialog
            _("Choose the Path to the y2update.tgz File")
          )
          if file != nil #TODO check for tgz format
            y2update_path = file
            UI.ChangeWidget(Id(:y2update_path), :Value, file)
          end
        elsif ret == :add
          file = UI.AskForExistingFile(
            Ops.get_string(current_product, "rpm_path", ""),
            "*.rpm",
            # popup for file selection dialog
            _("Choose the YaST Module Package")
          )
          if file != nil && !Builtins.contains(y2update_packages, file)
            #TODO check for rpm
            y2update_packages = Builtins.add(y2update_packages, file)
            update_table.call
          end
          UI.ChangeWidget(Id(:delete), :Enabled, y2update_packages != [])
        elsif ret == :delete
          sel = Convert.to_string(
            UI.QueryWidget(Id(:y2update_packages), :CurrentItem)
          )
          y2update_packages = Builtins.filter(y2update_packages) { |p| p != sel }
          update_table.call
          UI.ChangeWidget(Id(:delete), :Enabled, y2update_packages != [])
        elsif ret == :next
          Ops.set(
            AddOnCreator.current_product,
            "y2update_packages",
            y2update_packages
          )
          Ops.set(
            AddOnCreator.current_product,
            "y2update_path",
            Convert.to_string(UI.QueryWidget(Id(:y2update_path), :Value))
          )
          Ops.set(
            AddOnCreator.current_product,
            "workflow_path",
            Convert.to_string(UI.QueryWidget(Id(:workflow_path), :Value))
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
      Wizard.RestoreAbortButton
      deep_copy(ret)
    end
  end
end
